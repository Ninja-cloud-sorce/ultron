import SwiftUI

struct RootView: View {
    @EnvironmentObject var appVM:   AppViewModel
    @EnvironmentObject var network: NetworkMonitor

    var body: some View {
        ZStack {
            appContent

            if !network.isConnected {
                NetworkErrorView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: network.isConnected)
    }

    @ViewBuilder
    private var appContent: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            switch appVM.appState {
            case .launch:
                LaunchView()
                    .transition(.opacity)

            case .landing:
                LandingView()
                    .transition(.opacity)

            case .onboarding:
                OnboardingContainerView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))

            case .auth:
                SignUpCardView(
                    onSuccess: { appVM.finishAuth() },
                    onSkip:    { appVM.skipAuth()   }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))

            case .northStar:
                NorthStarView()
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
