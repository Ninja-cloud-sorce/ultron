import Foundation

/// Single source of truth for the currently authenticated user's storage scope.
///
/// Set by AppViewModel immediately after Firebase confirms authentication.
/// Cleared by AppViewModel on sign-out.
///
/// Every data service keys its UserDefaults entries and file paths off this uid,
/// guaranteeing complete per-user data isolation with no cross-account data leakage.
final class UserContext {
    static let shared = UserContext()
    private init() {}

    private(set) var uid: String = "anonymous"

    func setUser(_ uid: String) {
        self.uid = uid
    }

    func clearUser() {
        uid = "anonymous"
    }

    /// Returns a UserDefaults key guaranteed to be unique to the current user.
    func key(_ base: String) -> String { "\(uid)_\(base)" }

    /// Returns a file URL in the app's Documents directory unique to the current user.
    func fileURL(_ filename: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("\(uid)_\(filename)")
    }
}
