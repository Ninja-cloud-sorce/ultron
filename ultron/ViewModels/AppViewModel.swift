import SwiftUI
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

enum AppState {
    case launch
    case landing
    case onboarding
    case auth
    case northStar
    case home
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var appState: AppState = .launch
    @Published var selectedTab: Int = 0
    @Published var showNewEntry: Bool = false

    private let onboardingKey = "compass_onboarding_done_v1"
    private let skipAuthKey   = "compass_skip_auth_v1"

    #if canImport(FirebaseAuth)
    // Holds the Firebase auth state listener so it stays alive for the app lifetime.
    private var authHandle: AuthStateDidChangeListenerHandle?
    #endif

    init() {
        // Auth listener is registered for all users (first-time and returning).
        setupAuthListener()
        guard UserDefaults.standard.bool(forKey: onboardingKey) else { return }
        // Returning user: only go home if Firebase confirms a live authenticated session.
        if FirebaseAuthenticationService.shared.isSignedIn {
            #if canImport(FirebaseAuth)
            if let user = Auth.auth().currentUser {
                // Scope all storage to this user before any data is loaded.
                UserContext.shared.setUser(user.uid)
                SettingsManager.shared.reload()
                JournalAnalysisRepository.shared.invalidateCache()
                importFirebaseProfileIfNeeded(user)
            }
            #endif
            appState = NorthStarService.shared.hasBeenSeen ? .home : .northStar
        } else {
            appState = .auth
        }
    }

    // Watches for external session invalidation (token expiry, force sign-out from console).
    private func setupAuthListener() {
        #if canImport(FirebaseAuth)
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self else { return }
                // If Firebase revokes the session while the user is on the home screen, kick to auth.
                if user == nil, self.appState == .home || self.appState == .northStar {
                    self.selectedTab = 0
                    self.advance(to: .auth)
                }
            }
        }
        #endif
    }

    #if canImport(FirebaseAuth)
    deinit {
        if let handle = authHandle { Auth.auth().removeStateDidChangeListener(handle) }
    }
    #endif

    func advance(to state: AppState) {
        withAnimation(.easeInOut(duration: 0.5)) { appState = state }
    }

    func finishOnboarding(goal: String? = nil) {
        if let g = goal?.trimmingCharacters(in: .whitespaces), !g.isEmpty {
            NorthStarService.shared.goal = g
        }
        // North Star was offered during onboarding — don't show the separate screen after auth.
        NorthStarService.shared.hasBeenSeen = true
        UserDefaults.standard.set(true, forKey: onboardingKey)
        advance(to: .auth)
    }

    func finishAuth() {
        // Hard gate: Firebase must confirm an authenticated user before home is shown.
        guard FirebaseAuthenticationService.shared.isSignedIn else { return }
        #if canImport(FirebaseAuth)
        if let user = Auth.auth().currentUser {
            // Scope all data services to the newly authenticated user BEFORE navigating home.
            UserContext.shared.setUser(user.uid)
            SettingsManager.shared.reload()
            JournalAnalysisRepository.shared.invalidateCache()
            // If no profile has been saved for this UID yet, seed it from Firebase auth data
            // so Google, Apple, and email accounts each show a distinct starting identity.
            importFirebaseProfileIfNeeded(user)
        }
        #endif
        selectedTab = 0
        advance(to: NorthStarService.shared.hasBeenSeen ? .home : .northStar)
    }

    #if canImport(FirebaseAuth)
    /// Populates the user's profile from Firebase auth data on first sign-in for a new UID.
    /// Never overwrites a profile the user has already customised.
    private func importFirebaseProfileIfNeeded(_ user: FirebaseAuth.User) {
        let nameKey = UserContext.shared.key("settings_username")
        guard UserDefaults.standard.string(forKey: nameKey) == nil else { return }

        let settings = SettingsManager.shared
        if let name = user.displayName, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            settings.username = name
        } else if let email = user.email {
            let prefix = String(email.prefix(while: { $0 != "@" }))
            settings.username = prefix.isEmpty ? "Wanderer" : prefix
        }
    }
    #endif

    // "Skip for now" — user explicitly chose to continue without an account.
    func skipAuth() {
        selectedTab = 0
        UserDefaults.standard.set(true, forKey: skipAuthKey)
        advance(to: NorthStarService.shared.hasBeenSeen ? .home : .northStar)
    }

    func finishNorthStar(goal: String?) {
        if let g = goal, !g.trimmingCharacters(in: .whitespaces).isEmpty {
            NorthStarService.shared.goal = g
        }
        NorthStarService.shared.hasBeenSeen = true
        advance(to: .home)
    }

    func signOut() {
        // 1. Reset all in-memory data so the next user never sees stale state.
        SettingsManager.shared.reset()
        JournalAnalysisRepository.shared.invalidateCache()
        // 2. Clear the uid scope BEFORE signing out so any pending writes use "anonymous".
        UserContext.shared.clearUser()
        // 3. Sign out of Firebase.
        FirebaseAuthenticationService.shared.signOut()
        UserDefaults.standard.removeObject(forKey: skipAuthKey)
        selectedTab = 0
        advance(to: .auth)
        // Note: JournalViewModel is a @StateObject inside HomeView.
        // Navigating away from .home destroys HomeView, which deallocates JournalViewModel.
        // The next sign-in creates a fresh HomeView → fresh JournalViewModel that loads
        // from the new user's UID-scoped file.
    }
}
