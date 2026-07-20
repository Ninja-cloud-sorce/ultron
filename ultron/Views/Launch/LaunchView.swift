import SwiftUI

struct LaunchView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var pulse = false
    @State private var opacity = 0.0

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.l) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentGold.opacity(0.08))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulse ? 1.3 : 1.0)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: pulse)

                    Circle()
                        .fill(AppTheme.Colors.accentGold.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .scaleEffect(pulse ? 1.15 : 1.0)
                        .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(0.2), value: pulse)

                    Image(systemName: "safari.fill")
                        .font(.system(size: 52, weight: .light))
                        .foregroundColor(AppTheme.Colors.accentGold)
                }

                VStack(spacing: AppTheme.Spacing.s) {
                    Text("Compass")
                        .font(.system(size: 38, weight: .bold, design: .serif))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text("Your mindful journaling companion")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()
            }
            .opacity(opacity)
        }
        .onAppear {
            pulse = true
            withAnimation(.easeIn(duration: 0.6)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                appVM.advance(to: .onboarding)
            }
        }
    }
}
