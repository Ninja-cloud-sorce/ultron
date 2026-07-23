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
                // Skip button — top right (hidden on last page)
                HStack {
                    Spacer()
                    if !isLast {
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.horizontal, AppTheme.Spacing.m)
                                .padding(.vertical, AppTheme.Spacing.s)
                        }
                    }
                }
                .padding(.top, AppTheme.Spacing.m)

                Spacer()

                // Title + subtitle
                VStack(spacing: AppTheme.Spacing.m) {
                    Text(page.title)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.5), radius: 8)

                    Text(page.subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                }

                // Bottom nav: dots (left) + circle arrow (right)
                HStack {
                    ProgressDotsView(total: totalPages, current: pageIndex)

                    Spacer()

                    // Circle arrow button
                    Button(action: onNext) {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.18))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.35), lineWidth: 1)
                                )

                            Image(systemName: isLast ? "checkmark" : "arrow.right")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, 60)
            }
        }
    }
}
