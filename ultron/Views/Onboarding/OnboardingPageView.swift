import SwiftUI

struct OnboardingPage {
    let imageName: String
    let title: String
    let subtitle: String
    let accentColor: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    let pageIndex: Int
    let totalPages: Int
    let onNext: () -> Void
    let onSkip: () -> Void

    var isLast: Bool { pageIndex == totalPages - 1 }

    var body: some View {
        ZStack {
            BackgroundImageView(imageName: page.imageName, gradientFromTop: true)

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.m)
                            .padding(.vertical, AppTheme.Spacing.s)
                    }
                }
                .padding(.top, AppTheme.Spacing.m)

                Spacer()

                VStack(spacing: AppTheme.Spacing.xl) {
                    VStack(spacing: AppTheme.Spacing.m) {
                        Text(page.title)
                            .font(.system(size: 30, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.5), radius: 8)

                        Text(page.subtitle)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.horizontal, AppTheme.Spacing.l)
                    }

                    VStack(spacing: AppTheme.Spacing.l) {
                        ProgressDotsView(total: totalPages, current: pageIndex)

                        GlowButton(title: isLast ? "Begin My Journey" : "Continue",
                                   icon: isLast ? "safari.fill" : "arrow.right",
                                   action: onNext)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, 60)
            }
        }
    }
}
