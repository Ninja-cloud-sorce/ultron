import SwiftUI

struct LoginCard: View {
    @ObservedObject var vm: SignInViewModel
    @FocusState private var focus: SignInField?

    var body: some View {
        VStack(spacing: 0) {
            // White card with fields
            VStack(spacing: 10) {
                AuthField(
                    icon: "envelope",
                    placeholder: "Email",
                    text: $vm.email,
                    isSecure: false,
                    showToggle: false,
                    showSecure: .constant(false),
                    hasError: false
                )
                .focused($focus, equals: .email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                AuthField(
                    icon: "lock",
                    placeholder: "Password",
                    text: $vm.password,
                    isSecure: !vm.showPassword,
                    showToggle: true,
                    showSecure: $vm.showPassword,
                    hasError: vm.passwordFieldHasError
                )
                .focused($focus, equals: .password)
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            // GO button welded to bottom of card
            GoButton(vm: vm)
                .offset(y: -3)
        }
        .shadow(color: .black.opacity(0.14), radius: 18, x: 0, y: 8)
        .onChange(of: focus) { _, f in vm.focusedField = f }
        .onChange(of: vm.monsterMood) { _, mood in
            if mood == .idle || mood == .typing { }
        }
    }
}

// MARK: - Individual field

private struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let showToggle: Bool
    @Binding var showSecure: Bool
    let hasError: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(.systemGray2))
                .frame(width: 18)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15))
            .foregroundColor(.black.opacity(0.85))

            if showToggle {
                Button {
                    showSecure.toggle()
                } label: {
                    Image(systemName: showSecure ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray2))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "#F4F4F6"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(hasError ? Color(hex: "#E03B2E").opacity(0.8) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: hasError)
    }
}

// MARK: - GO button

struct GoButton: View {
    @ObservedObject var vm: SignInViewModel
    @State private var pressScale: CGFloat = 1.0

    var body: some View {
        Button {
            guard vm.canSubmit else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) { pressScale = 0.94 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { pressScale = 1.0 }
            }
            vm.signIn()
        } label: {
            ZStack {
                if vm.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else if vm.isSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                } else {
                    Text("go")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .scaleEffect(pressScale)
        .disabled(!vm.canSubmit)
        .animation(.easeInOut(duration: 0.22), value: vm.isSuccess)
        .animation(.easeInOut(duration: 0.22), value: vm.isLoading)
    }

    private var buttonBackground: Color {
        if vm.passwordFieldHasError { return Color(hex: "#C0392B") }
        if vm.isSuccess { return Color(hex: "#1D7A0F") }
        return Color(hex: "#1E5C14")
    }
}
