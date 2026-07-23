import SwiftUI

struct SocialLoginButtons: View {
    @ObservedObject var vm: SignInViewModel

    var body: some View {
        VStack(spacing: 14) {
            // OR divider
            HStack(spacing: 14) {
                Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
                Text("or")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Rectangle().fill(Color.white.opacity(0.5)).frame(height: 1)
            }

            // Google
            SocialButton(
                label: "Continue with Google",
                backgroundColor: .white,
                foregroundColor: Color(.label),
                strokeColor: Color.clear
            ) {
                Text("G")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: "#4285F4"))
                    .frame(width: 20, height: 20)
            } action: {
                vm.signInWithGoogle()
            }

            // Apple
            SocialButton(
                label: "Continue with Apple",
                backgroundColor: .black,
                foregroundColor: .white,
                strokeColor: Color.clear
            ) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            } action: {
                vm.signInWithApple()
            }
        }
    }
}

// MARK: - Reusable social button

private struct SocialButton<Logo: View>: View {
    let label: String
    let backgroundColor: Color
    let foregroundColor: Color
    let strokeColor: Color
    @ViewBuilder var logo: Logo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                logo
                Text(label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(foregroundColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
