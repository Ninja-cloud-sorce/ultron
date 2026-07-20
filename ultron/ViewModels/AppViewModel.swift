import SwiftUI
import Combine

enum AppState {
    case launch
    case landing
    case onboarding
    case home
}

@MainActor
class AppViewModel: ObservableObject {
    @Published var appState: AppState = .launch
    @Published var selectedTab: Int = 0
    @Published var showNewEntry: Bool = false

    func advance(to state: AppState) {
        withAnimation(.easeInOut(duration: 0.5)) {
            appState = state
        }
    }
}
