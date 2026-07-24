import SwiftUI
import AuthenticationServices

// MARK: - Step

enum SignUpStep: CaseIterable {
    case email, password, repeatPassword

    var placeholder: String {
        switch self {
        case .email:          return "ENTER YOUR E-MAIL HERE"
        case .password:       return "ENTER YOUR PASSWORD HERE"
        case .repeatPassword: return "REPEAT YOUR PASSWORD HERE"
        }
    }

    var isSecure: Bool { self != .email }
    var keyboardType: UIKeyboardType { self == .email ? .emailAddress : .default }
    var identityIcon: String { self == .email ? "envelope" : "lock" }

    var next: SignUpStep? {
        switch self {
        case .email:          return .password
        case .password:       return .repeatPassword
        case .repeatPassword: return nil
        }
    }
}

// MARK: - SignUpCardView

struct SignUpCardView: View {

    var onSuccess: () -> Void = {}
    var onSkip:    () -> Void = {}

    // Default to sign-in so returning users can authenticate immediately.
    @State private var isSignInMode: Bool = true

    @State private var currentStep: SignUpStep = .email
    @State private var inputText: String = ""
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isSubmitting: Bool = false

    @State private var storedEmail: String = ""
    @State private var storedPassword: String = ""

    @State private var isLoadingGoogle = false
    @State private var isLoadingApple  = false
    @FocusState private var focused: SignUpStep?

    private let lavender = Color(red: 0.68, green: 0.64, blue: 0.90)
    private let pillFill = Color.white.opacity(0.12)
    private let errorRed = Color(red: 1.0, green: 0.45, blue: 0.45)

    // MARK: - Body

    var body: some View {
        ZStack {
            BackgroundImageView(imageName: "bg")

            VStack(spacing: 14) {
                card
                    .padding(.horizontal, 38)

                socialButtons

                modeToggleLink
            }

            VStack {
                Spacer()
                Button { onSkip() } label: {
                    Text("Skip for now")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.45))
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.bottom, 36)
            }
        }
    }

    // MARK: - Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isSignInMode ? "SIGN IN" : "SIGN UP")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(isSignInMode ? "Welcome back!" : "Fill in all informations")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.55))

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(errorRed)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer().frame(height: 4)

            rowContainer
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 24)
        .animation(.easeInOut(duration: 0.2), value: errorMessage)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        HStack(spacing: 12) {
            Button { signInWithGoogle() } label: {
                HStack(spacing: 10) {
                    if isLoadingGoogle {
                        ProgressView().tint(.white).scaleEffect(0.75)
                            .frame(width: 20, height: 20)
                    } else {
                        Image("google logo")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Text("Google")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(isLoadingGoogle)

            Button { signInWithApple() } label: {
                HStack(spacing: 10) {
                    if isLoadingApple {
                        ProgressView().tint(.white).scaleEffect(0.75)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.white)
                    }
                    Text("Apple")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 38)
    }

    // MARK: - Mode toggle link

    private var modeToggleLink: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSignInMode.toggle()
                resetForm()
            }
        } label: {
            Text(isSignInMode ? "New here? **Create account**" : "Already have an account? **Sign in**")
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.65))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Row Container

    private var rowContainer: some View {
        ZStack {
            if showSuccess {
                successBanner
                    .transition(.scale(scale: 0.8, anchor: .center).combined(with: .opacity))
            } else {
                inputRow
                    .transition(.opacity)
            }
        }
        .frame(height: 64)
        .clipped()
        .animation(.spring(response: 0.38, dampingFraction: 0.70), value: showSuccess)
    }

    private var keyboardSubmitLabel: SubmitLabel {
        let isLast = isSignInMode ? currentStep == .password : currentStep == .repeatPassword
        return isLast ? .go : .next
    }

    // MARK: - Input Row

    private var inputRow: some View {
        HStack(spacing: 10) {
            Group {
                if currentStep.isSecure {
                    SecureField(currentStep.placeholder, text: $inputText)
                        .focused($focused, equals: currentStep)
                        .submitLabel(keyboardSubmitLabel)
                        .onSubmit { handleIconTap() }
                } else {
                    TextField(currentStep.placeholder, text: $inputText)
                        .keyboardType(currentStep.keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused, equals: currentStep)
                        .submitLabel(keyboardSubmitLabel)
                        .onSubmit { handleIconTap() }
                }
            }
            .id(currentStep)
            .font(.system(size: 18, weight: .regular))
            .environment(\.colorScheme, .dark)
            .foregroundStyle(Color.white)
            .tint(.white)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .move(edge: .trailing)),
                removal:   .opacity.combined(with: .move(edge: .leading))
            ))

            iconButton
        }
        .padding(.leading, 18)
        .padding(.trailing, 10)
        .padding(.vertical, 14)
        .background(Capsule().fill(pillFill))
        .animation(.easeInOut(duration: 0.25), value: currentStep)
        .onAppear { focused = .email }
    }

    private var trailingIcon: String {
        if isSubmitting { return "arrow.2.circlepath" }
        if inputText.isEmpty { return currentStep.identityIcon }
        // Last step in current mode → submit icon
        let isLastStep = isSignInMode ? currentStep == .password : currentStep == .repeatPassword
        return isLastStep ? "paperplane.fill" : "arrow.up"
    }

    private var iconButton: some View {
        Button(action: handleIconTap) {
            Image(systemName: trailingIcon)
                .contentTransition(.symbolEffect(.replace))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSubmitting ? lavender.opacity(0.6) : lavender)
                )
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .animation(.easeInOut(duration: 0.2), value: trailingIcon)
    }

    // MARK: - Success Banner

    private var successBanner: some View {
        ZStack {
            Text(isSignInMode ? "SIGNED IN" : "ACCOUNT CREATED")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.10, green: 0.55, blue: 0.24))
                .offset(x: 2, y: 2)
            Text(isSignInMode ? "SIGNED IN" : "ACCOUNT CREATED")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.22, green: 0.82, blue: 0.52))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions

    private func handleIconTap() {
        guard !inputText.isEmpty, !isSubmitting else { return }
        errorMessage = nil

        if currentStep == .email {
            storedEmail = inputText
            advance()
        } else if currentStep == .password {
            storedPassword = inputText
            if isSignInMode {
                performSignIn()
            } else {
                advance()
            }
        } else if currentStep == .repeatPassword {
            guard inputText == storedPassword else {
                errorMessage = "Passwords don't match."
                return
            }
            createAccount()
        }
    }

    private func advance() {
        guard let next = currentStep.next else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentStep = next
            inputText   = ""
        }
        // Schedule focus after SwiftUI rebuilds the new field via .id(currentStep)
        Task { @MainActor in focused = next }
    }

    private func resetForm() {
        currentStep   = .email
        inputText     = ""
        storedEmail   = ""
        storedPassword = ""
        errorMessage  = nil
        showSuccess   = false
    }

    private func performSignIn() {
        isSubmitting = true
        Task {
            do {
                try await FirebaseAuthenticationService.shared.signIn(
                    email: storedEmail, password: storedPassword
                )
                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.65)) {
                        showSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { onSuccess() }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "Incorrect email or password."
                }
            }
        }
    }

    private func createAccount() {
        isSubmitting = true
        Task {
            do {
                try await FirebaseAuthenticationService.shared.createAccount(
                    email: storedEmail, password: storedPassword
                )
                await MainActor.run {
                    isSubmitting = false
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.65)) {
                        showSuccess = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { onSuccess() }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = (error as? LocalizedError)?.errorDescription
                        ?? "Something went wrong."
                }
            }
        }
    }

    private func signInWithApple() {
        isLoadingApple = true
        Task {
            do {
                try await FirebaseAuthenticationService.shared.signInWithApple()
                isLoadingApple = false
                onSuccess()
            } catch let err as ASAuthorizationError where err.code == .canceled {
                isLoadingApple = false
            } catch {
                isLoadingApple = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Apple sign-in failed."
            }
        }
    }

    private func signInWithGoogle() {
        isLoadingGoogle = true
        Task {
            do {
                try await FirebaseAuthenticationService.shared.signInWithGoogle()
                isLoadingGoogle = false
                onSuccess()
            } catch let err as ASWebAuthenticationSessionError where err.code == .canceledLogin {
                isLoadingGoogle = false
            } catch {
                isLoadingGoogle = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Google sign-in failed."
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpCardView()
}
