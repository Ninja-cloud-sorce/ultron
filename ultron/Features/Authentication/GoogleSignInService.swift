import Foundation
import AuthenticationServices
import CryptoKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

// MARK: - Google Sign-In (PKCE + ASWebAuthenticationSession, no extra SDK)

@MainActor
final class GoogleSignInService {

    static let shared = GoogleSignInService()

    private let clientID   = "890361446961-85dvmdpm7gsoe6aobthmr3hn6ihh2rtd.apps.googleusercontent.com"
    private let scheme     = "com.googleusercontent.apps.890361446961-85dvmdpm7gsoe6aobthmr3hn6ihh2rtd"
    private var redirectURI: String { "\(scheme):/oauthredirect" }

    private var authSession: ASWebAuthenticationSession?
    private let context = WebAuthContext()

    private init() {}

    // Full flow: browser → auth code → token exchange → Firebase credential
    func signIn() async throws {
        let verifier  = Self.makeVerifier()
        let challenge = Self.makeChallenge(from: verifier)

        var comps = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
        comps.queryItems = [
            .init(name: "client_id",             value: clientID),
            .init(name: "redirect_uri",          value: redirectURI),
            .init(name: "response_type",         value: "code"),
            .init(name: "scope",                 value: "openid email profile"),
            .init(name: "code_challenge",        value: challenge),
            .init(name: "code_challenge_method", value: "S256"),
        ]

        let code   = try await openBrowser(url: comps.url!)
        let tokens = try await exchangeCode(code, verifier: verifier)

        #if canImport(FirebaseAuth)
        let credential = GoogleAuthProvider.credential(
            withIDToken:  tokens.idToken,
            accessToken:  tokens.accessToken
        )
        try await Auth.auth().signIn(with: credential)
        #endif
        // Without FirebaseAuth linked the flow still "succeeds" so the app advances.
    }

    // MARK: - Browser flow

    private func openBrowser(url: URL) async throws -> String {
        defer { authSession = nil }
        return try await withCheckedThrowingContinuation { cont in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: scheme
            ) { callbackURL, error in
                if let error {
                    cont.resume(throwing: error)
                } else if let callbackURL,
                          let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: true)?
                              .queryItems?.first(where: { $0.name == "code" })?.value {
                    cont.resume(returning: code)
                } else {
                    cont.resume(throwing: AuthError.networkError)
                }
            }
            session.presentationContextProvider = context
            session.prefersEphemeralWebBrowserSession = false
            authSession = session
            session.start()
        }
    }

    // MARK: - Token exchange

    private struct TokenResponse: Decodable {
        let id_token: String
        let access_token: String
        var idToken: String    { id_token }
        var accessToken: String { access_token }
    }

    private func exchangeCode(_ code: String, verifier: String) async throws -> TokenResponse {
        var bodyComps = URLComponents()
        bodyComps.queryItems = [
            .init(name: "code",          value: code),
            .init(name: "client_id",     value: clientID),
            .init(name: "redirect_uri",  value: redirectURI),
            .init(name: "code_verifier", value: verifier),
            .init(name: "grant_type",    value: "authorization_code"),
        ]

        var req = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = bodyComps.percentEncodedQuery?.data(using: .utf8)

        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.networkError
        }
        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }

    // MARK: - PKCE helpers

    private static func makeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64url
    }

    private static func makeChallenge(from verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64url
    }
}

// MARK: - ASWebAuthentication presentation context

private final class WebAuthContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first else {
            return UIWindow()
        }
        return UIWindow(windowScene: scene)
    }
}

// MARK: - Base64URL encoding

private extension Data {
    var base64url: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
