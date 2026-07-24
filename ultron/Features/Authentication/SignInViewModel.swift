import SwiftUI
import Combine

enum SignInField: Hashable { case email, password }
enum MonsterMood: Equatable { case idle, typing, pressing, success, error }

@MainActor
final class SignInViewModel: ObservableObject {
    // MARK: - Form
    @Published var email    = ""
    @Published var password = ""
    @Published var showPassword  = false
    @Published var focusedField: SignInField?

    // MARK: - Auth state
    @Published var isLoading          = false
    @Published var isSuccess          = false
    @Published var errorMessage: String?
    @Published var passwordFieldHasError = false

    // MARK: - Monster
    @Published var monsterMood: MonsterMood = .idle

    // MARK: - Forgot password
    @Published var showForgotPassword = false
    @Published var resetEmail         = ""
    @Published var isSendingReset     = false
    @Published var resetSentMessage: String?

    let onSuccess: () -> Void
    let onSkip:    () -> Void
    private let service: AuthenticationService

    // Prevents a second Task from firing if the user taps GO before the first Task runs.
    private var isSubmitting = false

    init(service: AuthenticationService = FirebaseAuthenticationService.shared,
         onSuccess: @escaping () -> Void,
         onSkip: @escaping () -> Void = {}) {
        self.service   = service
        self.onSuccess = onSuccess
        self.onSkip    = onSkip
    }

    // MARK: - Email validation

    private static let emailPredicate = NSPredicate(
        format: "SELF MATCHES %@",
        "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
    )

    var isEmailValid: Bool {
        Self.emailPredicate.evaluate(with: email.trimmingCharacters(in: .whitespaces))
    }

    /// Non-nil only when user has typed something and the format is wrong.
    var emailError: String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return isEmailValid ? nil : "Enter a valid email  (e.g. you@example.com)"
    }

    var canSubmit: Bool {
        isEmailValid && !password.isEmpty && !isLoading && !isSuccess && !isSubmitting
    }

    // MARK: - Public actions

    func signIn() {
        guard canSubmit else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            await performSignIn()
        }
    }

    func signInWithGoogle() {
        guard !isLoading else { return }
        Task {
            isLoading   = true
            monsterMood = .pressing
            do {
                try await service.signInWithGoogle()
                triggerSuccess()
            } catch {
                triggerError(error)
            }
        }
    }

    func signInWithApple() {
        guard !isLoading else { return }
        Task {
            isLoading   = true
            monsterMood = .pressing
            do {
                try await service.signInWithApple()
                triggerSuccess()
            } catch {
                triggerError(error)
            }
        }
    }

    func skipAuth() { onSkip() }

    // MARK: - Forgot password

    func sendPasswordReset() {
        guard !isSendingReset else { return }
        isSendingReset    = true
        resetSentMessage  = nil
        Task {
            do {
                try await service.sendPasswordReset(email: resetEmail.trimmingCharacters(in: .whitespaces))
                resetSentMessage = "Reset link sent — check your inbox."
            } catch {
                resetSentMessage = (error as? LocalizedError)?.errorDescription
                    ?? "Could not send reset email."
            }
            isSendingReset = false
        }
    }

    // MARK: - Private

    private func performSignIn() async {
        monsterMood           = .pressing
        isLoading             = true
        errorMessage          = nil
        passwordFieldHasError = false
        do {
            try await service.signIn(
                email:    email.trimmingCharacters(in: .whitespaces),
                password: password
            )
            triggerSuccess()
        } catch {
            triggerError(error)
        }
    }

    private func triggerSuccess() {
        isLoading   = false
        monsterMood = .success
        isSuccess   = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { self.onSuccess() }
    }

    private func triggerError(_ error: Error) {
        isLoading             = false
        monsterMood           = .error
        passwordFieldHasError = true
        errorMessage          = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            monsterMood           = .idle
            passwordFieldHasError = false
            errorMessage          = nil
        }
    }
}
