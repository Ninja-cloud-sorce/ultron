import SwiftUI
import AuthenticationServices

// MARK: - Apple Sign-In Coordinator

private final class AppleSignInCoordinator: NSObject,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    var onComplete: (Bool) -> Void
    // Must be retained — ASAuthorizationController does NOT retain itself.
    // If it goes out of scope after performRequests(), the delegate never fires.
    private var authController: ASAuthorizationController?

    init(onComplete: @escaping (Bool) -> Void) {
        self.onComplete = onComplete
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let keyWindow = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) {
            return keyWindow
        }
        // No key window — create one from the active scene (safe: always non-nil in a running app)
        let scene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first!
        return UIWindow(windowScene: scene)
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        authController = nil
        DispatchQueue.main.async { self.onComplete(true) }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        authController = nil
        let code = (error as? ASAuthorizationError)?.code
        if code != .canceled {
            DispatchQueue.main.async { self.onComplete(false) }
        }
    }

    func startSignIn() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        authController = controller   // retain before performRequests()
        controller.performRequests()
    }
}

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
    var actionIcon: String { self == .repeatPassword ? "paperplane.fill" : "arrow.up" }

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

    @State private var currentStep: SignUpStep = .email
    @State private var inputText: String = ""
    @State private var showSuccess: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isSubmitting: Bool = false

    // Stored across steps for final Firebase call
    @State private var storedEmail: String = ""
    @State private var storedPassword: String = ""

    @State private var appleCoordinator: AppleSignInCoordinator?
    @State private var isLoadingGoogle = false

    private let lavender  = Color(red: 0.68, green: 0.64, blue: 0.90)
    private let cardCream = Color(red: 0.995, green: 0.990, blue: 0.972)
    private let cardTan   = Color(red: 0.71,  green: 0.63,  blue: 0.51)
    private let pillFill  = Color(red: 240/255, green: 240/255, blue: 240/255)
    private let nearBlack = Color(red: 0.13,  green: 0.11,  blue: 0.17)
    private let errorRed  = Color(red: 0.85,  green: 0.22,  blue: 0.22)

    // MARK: - Body

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            VStack(spacing: 14) {
                card
                    .padding(.horizontal, 38)

                socialButtons
            }

            // Skip button pinned to bottom center
            VStack {
                Spacer()
                Button { onSkip() } label: {
                    Text("Skip for now")
                        .font(.system(size: 14))
                        .foregroundColor(.black.opacity(0.45))
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
            Text("SIGN UP")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(nearBlack)

            Text("Fill in all informations")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.50, green: 0.50, blue: 0.52))

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
                .fill(cardCream)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(cardTan)
                        .offset(x: 7, y: 7)
                )
        )
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        HStack(spacing: 12) {
            // Google — white pill, original-color logo from assets
            Button { signInWithGoogle() } label: {
                HStack(spacing: 10) {
                    if isLoadingGoogle {
                        ProgressView().scaleEffect(0.75)
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
                        .foregroundStyle(Color.black)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white))
            }
            .buttonStyle(.plain)
            .disabled(isLoadingGoogle)

            // Apple — black pill, white logo (HIG standard)
            Button { signInWithApple() } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.white)
                    Text("Apple")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.black))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 38)
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

    // MARK: - Input Row

    private var inputRow: some View {
        HStack(spacing: 10) {
            Group {
                if currentStep.isSecure {
                    SecureField(currentStep.placeholder, text: $inputText)
                } else {
                    TextField(currentStep.placeholder, text: $inputText)
                        .keyboardType(currentStep.keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .id(currentStep)
            // SF Pro Text Regular, 18pt — matches system input fields
            .font(.system(size: 18, weight: .regular))
            // Force light-mode rendering so typed text is dark and
            // placeholder renders as medium gray regardless of app colour scheme.
            .environment(\.colorScheme, .light)
            .foregroundStyle(nearBlack)
            .tint(.blue)   // cursor colour
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
    }

    private var trailingIcon: String {
        if isSubmitting { return "arrow.2.circlepath" }
        return inputText.isEmpty ? currentStep.identityIcon : currentStep.actionIcon
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
            Text("ACCOUNT CREATED")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(Color(red: 0.10, green: 0.55, blue: 0.24))
                .offset(x: 2, y: 2)
            Text("ACCOUNT CREATED")
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
            advance()
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
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func signInWithApple() {
        let coordinator = AppleSignInCoordinator { success in
            appleCoordinator = nil
            if success { onSuccess() }
        }
        appleCoordinator = coordinator
        coordinator.startSignIn()
    }

    private func signInWithGoogle() {
        isLoadingGoogle = true
        Task {
            do {
                try await GoogleSignInService.shared.signIn()
                isLoadingGoogle = false
                onSuccess()
            } catch let err as ASWebAuthenticationSessionError where err.code == .canceledLogin {
                isLoadingGoogle = false
            } catch {
                isLoadingGoogle = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SignUpCardView()
}
