import SwiftUI

struct LandingView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var appeared = false

    var body: some View {
        ZStack {
            BackgroundImageView(imageName: "lan1")

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: AppTheme.Spacing.l) {
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("Compass")
                            .font(.system(size: 42, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .shadow(color: .black.opacity(0.4), radius: 8)

                        Text("A mindful journaling companion\nthat helps you reflect, grow, and\nfind your direction.")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .offset(y: appeared ? 0 : 30)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: AppTheme.Spacing.m) {
                        GlowButton(title: "Begin Your Journey", icon: "arrow.right") {
                            appVM.advance(to: .onboarding)
                        }

                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                            Button("Sign In") { appVM.advance(to: .auth) }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.accentGold)
                        }
                    }
                    .offset(y: appeared ? 0 : 40)
                    .opacity(appeared ? 1 : 0)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                appeared = true
            }
        }
    }
}
