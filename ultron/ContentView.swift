import SwiftUI

struct RootView: View {
    @EnvironmentObject var appVM: AppViewModel

    var body: some View {
        ZStack {
            switch appVM.appState {
            case .launch:
                LaunchView()
                    .transition(.opacity)
            case .onboarding:
                OnboardingContainerView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            case .home:
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appVM.appState)
    }
}
