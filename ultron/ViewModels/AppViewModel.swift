import SwiftUI
import Combine

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

    init() {
        // Returning user — skip launch/landing/onboarding, go straight to home or north star
        guard UserDefaults.standard.bool(forKey: onboardingKey) else { return }
        appState = NorthStarService.shared.hasBeenSeen ? .home : .northStar
    }

    func advance(to state: AppState) {
        withAnimation(.easeInOut(duration: 0.5)) { appState = state }
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: onboardingKey)
        advance(to: .auth)
    }

    func finishAuth() {
        advance(to: NorthStarService.shared.hasBeenSeen ? .home : .northStar)
    }

    // "Skip for now" — remembered so auth screen is not shown again.
    func skipAuth() {
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
        FirebaseAuthenticationService.shared.signOut()
        UserDefaults.standard.removeObject(forKey: skipAuthKey)
        advance(to: .auth)
    }
}
