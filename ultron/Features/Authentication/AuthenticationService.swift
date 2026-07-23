import Foundation
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidEmail
    case emptyPassword
    case weakPassword
    case wrongCredentials
    case networkError
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:     return "Please enter a valid email address."
        case .emptyPassword:    return "Please enter your password."
        case .weakPassword:     return "Password must be at least 6 characters."
        case .wrongCredentials: return "Incorrect email or password."
        case .networkError:     return "Network error. Please try again."
        case .unknown(let msg): return msg
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
    func signOut()
    func deleteAccount() async throws
}

// MARK: - Firebase (production)

#if canImport(FirebaseAuth)
final class FirebaseAuthenticationService: AuthenticationService {
    static let shared = FirebaseAuthenticationService()

    var isSignedIn: Bool { Auth.auth().currentUser != nil }

    func signIn(email: String, password: String) async throws {
        guard !email.isEmpty, email.contains("@") else { throw AuthError.invalidEmail }
        guard !password.isEmpty else { throw AuthError.emptyPassword }
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch let err as NSError {
            throw mapFirebaseError(err)
        }
    }

    func signInWithGoogle() async throws {
        // Requires GoogleSignIn-iOS package + CLIENT_ID in GoogleService-Info.plist.
        // Add package: https://github.com/google/GoogleSignIn-iOS
        throw AuthError.networkError
    }

    func signInWithApple() async throws {
        // Handled natively in SignUpCardView via ASAuthorizationController.
    }

    func createAccount(email: String, password: String) async throws {
        guard !email.isEmpty, email.contains("@") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch let err as NSError {
            throw mapFirebaseError(err)
        }
    }

    func signOut() {
        try? Auth.auth().signOut()
    }

    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else { return }
        try await user.delete()
    }

    private func mapFirebaseError(_ error: NSError) -> AuthError {
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidEmail, .invalidRecipientEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .wrongPassword, .userNotFound, .userDisabled:
            return .wrongCredentials
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
#else
// Fallback when FirebaseAuth is not linked — forwards to MockAuthenticationService.
// Link FirebaseAuth in Xcode (Target → General → Frameworks) to activate the real implementation.
final class FirebaseAuthenticationService: AuthenticationService {
    static let shared = FirebaseAuthenticationService()
    private let mock = MockAuthenticationService.shared

    var isSignedIn: Bool { mock.isSignedIn }
    func signIn(email: String, password: String) async throws { try await mock.signIn(email: email, password: password) }
    func signInWithGoogle() async throws { try await mock.signInWithGoogle() }
    func signInWithApple() async throws { try await mock.signInWithApple() }
    func createAccount(email: String, password: String) async throws { try await mock.createAccount(email: email, password: password) }
    func signOut() { mock.signOut() }
    func deleteAccount() async throws { mock.signOut() }
}
#endif

// MARK: - Mock (development / previews)

final class MockAuthenticationService: AuthenticationService {
    static let shared = MockAuthenticationService()
    static let sessionKey = "compass_signed_in_v1"

    var isSignedIn: Bool {
        UserDefaults.standard.bool(forKey: Self.sessionKey)
    }

    func signIn(email: String, password: String) async throws {
        guard !email.isEmpty, email.contains("@") else { throw AuthError.invalidEmail }
        guard !password.isEmpty else { throw AuthError.emptyPassword }
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
        guard !email.isEmpty, email.contains("@") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        try await Task.sleep(nanoseconds: 1_200_000_000)
        UserDefaults.standard.set(true, forKey: Self.sessionKey)
    }

    func signOut() {
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }

    func deleteAccount() async throws {
        UserDefaults.standard.removeObject(forKey: Self.sessionKey)
    }
}
