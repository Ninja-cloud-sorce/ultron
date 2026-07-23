import SwiftUI
import Combine

enum SignInField: Hashable { case email, password }
enum MonsterMood: Equatable { case idle, typing, pressing, success, error }

@MainActor
final class SignInViewModel: ObservableObject {
    // MARK: - Form
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    @Published var focusedField: SignInField?

    // MARK: - Auth state
    @Published var isLoading = false
    @Published var isSuccess = false
    @Published var errorMessage: String?
    @Published var passwordFieldHasError = false

    // MARK: - Monster
    @Published var monsterMood: MonsterMood = .idle

    let onSuccess: () -> Void
    let onSkip:    () -> Void
    private let service: AuthenticationService

    init(service: AuthenticationService = MockAuthenticationService.shared,
         onSuccess: @escaping () -> Void,
         onSkip: @escaping () -> Void = {}) {
        self.service   = service
        self.onSuccess = onSuccess
        self.onSkip    = onSkip
    }

    // MARK: - Public actions

    func signIn() {
        Task { await performSignIn() }
    }

    func signInWithGoogle() {
        Task {
            isLoading = true
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
        Task {
            isLoading = true
            monsterMood = .pressing
            do {
                try await service.signInWithApple()
                triggerSuccess()
            } catch {
                triggerError(error)
            }
        }
    }

    var canSubmit: Bool { !email.isEmpty && !password.isEmpty && !isLoading && !isSuccess }

    func skipAuth() { onSkip() }

    // MARK: - Private

    private func performSignIn() async {
        monsterMood = .pressing
        isLoading = true
        errorMessage = nil
        passwordFieldHasError = false
        do {
            try await service.signIn(email: email, password: password)
            triggerSuccess()
        } catch {
            triggerError(error)
        }
    }

    private func triggerSuccess() {
        isLoading = false
        monsterMood = .success
        isSuccess = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            self.onSuccess()
        }
    }

    private func triggerError(_ error: Error) {
        isLoading = false
        monsterMood = .error
        passwordFieldHasError = true
        errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        Task {
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            monsterMood = .idle
            passwordFieldHasError = false
            errorMessage = nil
        }
    }
}
