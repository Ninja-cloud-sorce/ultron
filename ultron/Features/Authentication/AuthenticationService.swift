import Foundation
import AuthenticationServices
import CryptoKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case emptyPassword
    case weakPassword
    case wrongCredentials
    case wrongProvider
    case networkError
    case accountDisabled
    case tooManyRequests
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidEmail:     return "Please enter a valid email address."
        case .emptyPassword:    return "Please enter your password."
        case .weakPassword:     return "Password must be at least 6 characters."
        case .wrongCredentials: return "Incorrect email or password."
        case .wrongProvider:    return "This email is linked to Apple or Google sign-in. Please use that method instead."
        case .networkError:     return "No internet connection. Please try again."
        case .accountDisabled:  return "This account has been disabled. Contact support."
        case .tooManyRequests:  return "Too many attempts. Please wait a moment and try again."
        case .unknown:          return "Something went wrong. Please try again."
        }
    }
}

// MARK: - Protocol

protocol AuthenticationService: AnyObject {
    var isSignedIn: Bool { get }
    func signIn(email: String, password: String) async throws
    func signInWithGoogle() async throws
    func signInWithApple() async throws
    func createAccount(email: String, password: String) async throws
    func sendPasswordReset(email: String) async throws
    func signOut()
    func deleteAccount() async throws
}

// MARK: - Firebase (production)

#if canImport(FirebaseAuth)

// MARK: Apple Sign-In helper — self-retaining delegate bridging ASAuthorizationController to async/await

private final class AppleAuthHelper: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>
    private var authController: ASAuthorizationController?
    // Self-retain so the delegate isn't deallocated before the system callback fires.
    private static var retained: AppleAuthHelper?

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func start(hashedNonce: String) {
        Self.retained = self
        let provider = ASAuthorizationAppleIDProvider()
        let request  = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate                  = self
        controller.presentationContextProvider = self
        authController = controller
        controller.performRequests()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let w = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) { return w }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            return UIWindow()
        }
        return UIWindow(windowScene: scene)
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        authController = nil
        defer { Self.retained = nil }
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: AuthError.unknown)
            return
        }
        continuation.resume(returning: cred)
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        authController = nil
        defer { Self.retained = nil }
        continuation.resume(throwing: error)
    }
}

// MARK: Firebase implementation

final class FirebaseAuthenticationService: AuthenticationService {
    static let shared = FirebaseAuthenticationService()

    var isSignedIn: Bool { Auth.auth().currentUser != nil }

    // MARK: Email / password

    func signIn(email: String, password: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard isValidEmail(trimmed) else { throw AuthError.invalidEmail }
        guard !password.isEmpty    else { throw AuthError.emptyPassword }
        do {
            try await Auth.auth().signIn(withEmail: trimmed, password: password)
        } catch let err as NSError {
            throw mapFirebaseError(err)
        }
    }

    func createAccount(email: String, password: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard isValidEmail(trimmed) else { throw AuthError.invalidEmail }
        guard password.count >= 6  else { throw AuthError.weakPassword }
        do {
            try await Auth.auth().createUser(withEmail: trimmed, password: password)
        } catch let err as NSError {
            throw mapFirebaseError(err)
        }
    }

    func sendPasswordReset(email: String) async throws {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard isValidEmail(trimmed) else { throw AuthError.invalidEmail }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: trimmed)
        } catch let err as NSError {
            throw mapFirebaseError(err)
        }
    }

    // MARK: Apple Sign-In (nonce + Firebase OAuthCredential)

    func signInWithApple() async throws {
        let nonce       = Self.generateNonce()
        let hashedNonce = Self.sha256(nonce)

        // ASAuthorizationController MUST be created and performRequests() called from the
        // main thread. signInWithApple() is non-isolated async, so Swift Concurrency runs it
        // on the cooperative thread pool — we must explicitly hop to the main actor here.
        let appleCredential = try await withCheckedThrowingContinuation { cont in
            Task { @MainActor in
                AppleAuthHelper(continuation: cont).start(hashedNonce: hashedNonce)
            }
        }

        guard let tokenData = appleCredential.identityToken,
              let token = String(data: tokenData, encoding: .utf8) else {
            throw AuthError.unknown
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: token,
            rawNonce:    nonce,
            fullName:    appleCredential.fullName
        )
        do {
            try await Auth.auth().signIn(with: firebaseCredential)
        } catch let err as NSError {
            throw mapFirebaseError(err)
        }
    }

    // MARK: Google Sign-In — delegated to GoogleSignInService (PKCE + Firebase)

    func signInWithGoogle() async throws {
        try await GoogleSignInService.shared.signIn()
    }

    // MARK: Account management

    func signOut() {
        try? Auth.auth().signOut()
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }

    // MARK: - Helpers

    private func isValidEmail(_ email: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@",
                    "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}")
            .evaluate(with: email)
    }

    private func mapFirebaseError(_ error: NSError) -> AuthError {
        let code = AuthErrorCode(rawValue: error.code)
        switch code {
        case .invalidEmail, .invalidRecipientEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .wrongPassword, .userNotFound, .invalidCredential:
            return .wrongCredentials
        case .accountExistsWithDifferentCredential, .credentialAlreadyInUse:
            return .wrongProvider
        case .userDisabled:
            return .accountDisabled
        case .networkError:
            return .networkError
        case .tooManyRequests:
            return .tooManyRequests
        case .operationNotAllowed:
            // Email/Password provider is disabled in the Firebase console.
            return .unknown
        default:
            return .unknown
        }
    }

    // MARK: - Nonce generation (required for Apple Sign-In with Firebase)

    private static func generateNonce(length: Int = 32) -> String {
        var bytes = [UInt8](repeating: 0, count: length)
        SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )
        return String(bytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        Data(SHA256.hash(data: Data(input.utf8)))
            .map { String(format: "%02x", $0) }.joined()
    }
}

#else

// Fallback stub when FirebaseAuth is not linked — delegates to mock.
final class FirebaseAuthenticationService: AuthenticationService {
    static let shared = FirebaseAuthenticationService()
    private let mock  = MockAuthenticationService.shared

    var isSignedIn: Bool { mock.isSignedIn }
    func signIn(email: String, password: String) async throws      { try await mock.signIn(email: email, password: password) }
    func signInWithGoogle() async throws                            { try await mock.signInWithGoogle() }
    func signInWithApple() async throws                             { try await mock.signInWithApple() }
    func createAccount(email: String, password: String) async throws { try await mock.createAccount(email: email, password: password) }
    func sendPasswordReset(email: String) async throws              { try await mock.sendPasswordReset(email: email) }
    func signOut()                                                  { mock.signOut() }
    func deleteAccount() async throws                               { mock.signOut() }
}

#endif

// MARK: - Mock (development / Previews)

final class MockAuthenticationService: AuthenticationService {
    static let shared  = MockAuthenticationService()
    static let sessionKey = "compass_signed_in_v1"

    private static let emailPredicate = NSPredicate(
        format: "SELF MATCHES %@",
        "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
    )

    var isSignedIn: Bool { UserDefaults.standard.bool(forKey: Self.sessionKey) }

    func signIn(email: String, password: String) async throws {
        let t = email.trimmingCharacters(in: .whitespaces)
        guard Self.emailPredicate.evaluate(with: t) else { throw AuthError.invalidEmail }
        guard !password.isEmpty   else { throw AuthError.emptyPassword }
        guard password.count >= 6 else { throw AuthError.wrongCredentials }
        try await Task.sleep(nanoseconds: 1_100_000_000)
        UserDefaults.standard.set(true, forKey: Self.sessionKey)
    }

    func signInWithGoogle() async throws {
        try await Task.sleep(nanoseconds: 900_000_000)
        UserDefaults.standard.set(true, forKey: Self.sessionKey)
    }

    func signInWithApple() async throws {
        try await Task.sleep(nanoseconds: 900_000_000)
        UserDefaults.standard.set(true, forKey: Self.sessionKey)
    }

    func createAccount(email: String, password: String) async throws {
        let t = email.trimmingCharacters(in: .whitespaces)
        guard Self.emailPredicate.evaluate(with: t) else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        UserDefaults.standard.set(true, forKey: Self.sessionKey)
    }

    func sendPasswordReset(email: String) async throws {
        let t = email.trimmingCharacters(in: .whitespaces)
        guard Self.emailPredicate.evaluate(with: t) else { throw AuthError.invalidEmail }
        try await Task.sleep(nanoseconds: 800_000_000)
    }

    func signOut()                      { UserDefaults.standard.removeObject(forKey: Self.sessionKey) }
    func deleteAccount() async throws   { UserDefaults.standard.removeObject(forKey: Self.sessionKey) }
}
