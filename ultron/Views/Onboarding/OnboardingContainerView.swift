import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var currentPage = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "lan2",
            title: "Track Your Moods",
            subtitle: "Check in daily with how you're feeling and discover patterns in your emotional landscape.",
            accentColor: AppTheme.Colors.accentGold
        ),
        OnboardingPage(
            imageName: "lan3",
            title: "Reflect Daily",
            subtitle: "Guided prompts help you go deeper — uncovering insights about who you are and who you're becoming.",
            accentColor: AppTheme.Colors.accentTeal
        ),
        OnboardingPage(
            imageName: "lan4",
            title: "Find Your Path",
            subtitle: "Watch your journey unfold over time. Every entry is a step toward greater self-understanding.",
            accentColor: AppTheme.Colors.accentGold
        ),
    ]

    var body: some View {
        ZStack {
            ForEach(pages.indices, id: \.self) { i in
                if i == currentPage {
                    OnboardingPageView(
                        page: pages[i],
                        pageIndex: i,
                        totalPages: pages.count,
                        onNext: advancePage,
                        onSkip: { appVM.advance(to: .home) }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(i)
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: currentPage)
    }

    private func advancePage() {
        if currentPage < pages.count - 1 {
            currentPage += 1
        } else {
            appVM.advance(to: .home)
        }
    }
}
