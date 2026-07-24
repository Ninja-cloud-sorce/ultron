import SwiftUI
import Combine

// MARK: - Monster image (UIViewRepresentable bypasses iOS 26 container bg injection)

private struct MonsterImageView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIImageView {
        let iv = UIImageView(image: UIImage(named: "monster png"))
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .clear
        iv.isOpaque = false
        return iv
    }
    func updateUIView(_ uiView: UIImageView, context: Context) {}
}

// MARK: - SignInView

struct SignInView: View {
    @StateObject private var vm: SignInViewModel
    @State private var showCreateAccount = false
    @State private var shakeTrigger: CGFloat = 0
    @FocusState private var focus: SignInField?

    // Monster native resolution: 1888 × 2234
    private static let monsterAspect: CGFloat = 2234.0 / 1888.0

    init(onSuccess: @escaping () -> Void, onSkip: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: SignInViewModel(onSuccess: onSuccess, onSkip: onSkip))
    }

    var body: some View {
        GeometryReader { geo in
            let W = geo.size.width
            let monsterW = W * 0.88
            // Compute aspect from the real asset; fall back to measured value if asset missing
            let aspect: CGFloat = {
                guard let img = UIImage(named: "monster png"), img.size.width > 0 else { return 1.1833 }
                return img.size.height / img.size.width
            }()
            let monsterH = monsterW * aspect

            ZStack(alignment: .top) {

                // ── Background: sky blue flat, sharp break to body green ──
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#60C1F0"), location: 0.00),
                        .init(color: Color(hex: "#60C1F0"), location: 0.40),
                        .init(color: Color(hex: "#90DE9B"), location: 0.43),
                        .init(color: Color(hex: "#90DE9B"), location: 1.00)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {

                    // ── Title ─────────────────────────────────────────────
                    titleBlock
                        .padding(.top, 52)
                        .padding(.horizontal, 26)

                    Spacer().frame(height: 6)

                    // ── Three-layer monster composition ───────────────────
                    // Frames on each MonsterImageView directly so UIKit
                    // receives the correct bounds — framing the outer ZStack
                    // alone is insufficient because UIImageView reports its
                    // intrinsic size (full PNG resolution) back to SwiftUI.
                    ZStack(alignment: .top) {

                        // Layer A — full monster behind card (normal + error crossfade)
                        ZStack {
                            MonsterImageView()
                                .frame(width: monsterW, height: monsterH)
                            MonsterImageView()
                                .frame(width: monsterW, height: monsterH)
                                .saturation(0)
                                .colorMultiply(Color(hex: "#B03030"))
                                .opacity(vm.passwordFieldHasError ? 1 : 0)
                        }
                        .animation(.easeInOut(duration: 0.3), value: vm.passwordFieldHasError)

                        // Layer B — login card, top edge at 50 % of monster height
                        VStack(spacing: 0) {
                            Color.clear.frame(height: monsterH * 0.50)
                            loginCard
                                .padding(.horizontal, W * 0.16)
                        }
                        .frame(maxWidth: .infinity)

                        // Layer C — hands band on top of card (normal + error crossfade)
                        ZStack {
                            MonsterImageView()
                                .frame(width: monsterW, height: monsterH)
                            MonsterImageView()
                                .frame(width: monsterW, height: monsterH)
                                .saturation(0)
                                .colorMultiply(Color(hex: "#B03030"))
                                .opacity(vm.passwordFieldHasError ? 1 : 0)
                        }
                        .animation(.easeInOut(duration: 0.3), value: vm.passwordFieldHasError)
                        .mask {
                            VStack(spacing: 0) {
                                Color.clear.frame(height: monsterH * 0.44)
                                Color.black.frame(height: monsterH * 0.16)
                                Color.clear
                            }
                        }
                    }
                    .frame(width: W, height: monsterH, alignment: .top)
                    .clipped()

                    // Error message
                    if let err = vm.errorMessage {
                        Text(err)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "#B03030"))
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .padding(.horizontal, 32)
                            .padding(.top, 10)
                    }

                    // ── OR divider ────────────────────────────────────────
                    orDivider
                        .padding(.horizontal, 24)
                        .padding(.top, vm.errorMessage == nil ? 14 : 8)

                    // ── Social buttons ────────────────────────────────────
                    VStack(spacing: 12) {
                        googleButton
                        appleButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    accountFooter
                        .padding(.top, 18)
                        .padding(.bottom, 72)

                    Spacer(minLength: 0)
                }
                .background(.clear)

                // Skip button pinned to bottom center
                VStack {
                    Spacer()
                    skipButton
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 36)
                }
            }
        }
        .preferredColorScheme(.light)
        .animation(.easeInOut(duration: 0.2), value: vm.errorMessage != nil)
        .onChange(of: vm.passwordFieldHasError) { _, hasError in
            if hasError {
                withAnimation(.linear(duration: 0.45)) { shakeTrigger += 1 }
            }
        }
        .sheet(isPresented: $showCreateAccount) {
            CreateAccountView(onSuccess: vm.onSuccess)
        }
        .sheet(isPresented: $vm.showForgotPassword, onDismiss: { vm.resetSentMessage = nil; vm.resetEmail = "" }) {
            ForgotPasswordSheet(vm: vm)
        }
        .onTapGesture { focus = nil }
    }

    // MARK: - Title

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Welcome,")
                .font(.system(size: 50, weight: .thin))
                .foregroundColor(.white)
            Text("let's get signed in!")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.90))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Login card

    private var loginCard: some View {
        VStack(spacing: 0) {
            // Input fields area
            VStack(spacing: 10) {
                emailField
                passwordField
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
            .background(Color.white)

            // GO button welded to bottom of fields
            goButton
                .background(vm.passwordFieldHasError
                    ? Color(hex: "#B03030")
                    : Color(hex: "#1F7B4D"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
        .modifier(ShakeEffect(shakes: shakeTrigger))
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "envelope")
                    .font(.system(size: 14)).foregroundColor(.gray).frame(width: 18)
                    .accessibilityHidden(true)
                TextField("Email", text: $vm.email)
                    .font(.system(size: 15))
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.emailAddress)
                    .submitLabel(.next)
                    .focused($focus, equals: .email)
                    .onSubmit { focus = .password }
                    .accessibilityLabel("Email address")
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color(hex: "#F5F6F8"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(vm.emailError != nil
                            ? Color(hex: "#B03030").opacity(0.65) : Color.clear, lineWidth: 1.5)
            )
            .animation(.easeInOut(duration: 0.2), value: vm.emailError != nil)

            if let msg = vm.emailError {
                Text(msg)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: "#B03030"))
                    .padding(.leading, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityLabel(msg)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: vm.emailError)
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 10) {
                Image(systemName: "lock")
                    .font(.system(size: 14)).foregroundColor(.gray).frame(width: 18)
                    .accessibilityHidden(true)
                Group {
                    if vm.showPassword {
                        TextField("Password", text: $vm.password)
                            .textContentType(.password)
                    } else {
                        SecureField("Password", text: $vm.password)
                            .textContentType(.password)
                    }
                }
                .font(.system(size: 15))
                .submitLabel(.go)
                .focused($focus, equals: .password)
                .onSubmit { if vm.canSubmit { focus = nil; vm.signIn() } }

                Button {
                    vm.showPassword.toggle()
                } label: {
                    Image(systemName: vm.showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(vm.showPassword ? "Hide password" : "Show password")
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(Color(hex: "#F5F6F8"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(vm.passwordFieldHasError
                            ? Color(hex: "#B03030").opacity(0.70) : Color.clear, lineWidth: 1.5)
            )

            // Forgot password — right-aligned, below the field
            Button("Forgot password?") { vm.showForgotPassword = true }
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray))
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 4)
                .accessibilityLabel("Forgot password")
        }
    }

    private var goButton: some View {
        Button {
            guard vm.canSubmit else { return }
            focus = nil
            vm.signIn()
        } label: {
            ZStack {
                if vm.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.9)
                } else if vm.isSuccess {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                } else {
                    Text("go")
                        .font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity).frame(height: 50)
        }
        .disabled(!vm.canSubmit)
        .accessibilityLabel(vm.isLoading ? "Signing in" : "Sign in")
        .animation(.easeInOut(duration: 0.2), value: vm.isSuccess)
        .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
    }

    // MARK: - OR divider

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.black.opacity(0.18)).frame(height: 1)
            Text("or").font(.system(size: 14)).foregroundColor(.black.opacity(0.40))
            Rectangle().fill(Color.black.opacity(0.18)).frame(height: 1)
        }
    }

    // MARK: - Social buttons

    // Procedural four-color Google "G" — no image asset required
    private var googleGIcon: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 28, height: 28)
            Circle().trim(from: 0.75, to: 1.0)
                .stroke(Color(red: 0xEA/255, green: 0x43/255, blue: 0x35/255),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .butt))
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))
            Circle().trim(from: 0.0, to: 0.25)
                .stroke(Color(red: 0x42/255, green: 0x85/255, blue: 0xF4/255),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .butt))
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))
            Circle().trim(from: 0.25, to: 0.50)
                .stroke(Color(red: 0xFB/255, green: 0xBC/255, blue: 0x05/255),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .butt))
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))
            Circle().trim(from: 0.50, to: 0.75)
                .stroke(Color(red: 0x34/255, green: 0xA8/255, blue: 0x53/255),
                        style: StrokeStyle(lineWidth: 4.5, lineCap: .butt))
                .frame(width: 18, height: 18)
                .rotationEffect(.degrees(-90))
            Circle().fill(Color.white).frame(width: 10, height: 10)
            Capsule().fill(Color(red: 0x42/255, green: 0x85/255, blue: 0xF4/255))
                .frame(width: 6, height: 2.5)
                .offset(x: 3.5)
        }
    }

    private var googleButton: some View {
        Button { vm.signInWithGoogle() } label: {
            HStack(spacing: 12) {
                googleGIcon
                Text("Continue with Google")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.82))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(ScalePressStyle())
    }

    private var appleButton: some View {
        Button { vm.signInWithApple() } label: {
            HStack(spacing: 10) {
                Image(systemName: "apple.logo").foregroundColor(.white)
                Text("Continue with Apple")
                    .font(.system(size: 16, weight: .medium)).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(hex: "#1A1A1A"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(ScalePressStyle())
    }

    // MARK: - Footer

    private var accountFooter: some View {
        VStack(spacing: 2) {
            Text("Don't have an account?")
                .foregroundColor(.black.opacity(0.65))
            Button { showCreateAccount = true } label: {
                HStack(spacing: 4) {
                    Text("Create one").underline().fontWeight(.semibold)
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(Color(hex: "#0D6DC5"))
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 15))
    }

    private var skipButton: some View {
        Button { vm.skipAuth() } label: {
            Text("Skip for now")
                .font(.system(size: 14))
                .foregroundColor(.black.opacity(0.38))
                .underline()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private struct ScalePressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ShakeEffect: GeometryEffect {
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: 8 * sin(shakes * .pi * 6), y: 0)
        )
    }
}

// MARK: - Forgot password sheet

private struct ForgotPasswordSheet: View {
    @ObservedObject var vm: SignInViewModel
    @Environment(\.dismiss) private var dismiss

    private var resetEmailValid: Bool {
        NSPredicate(format: "SELF MATCHES %@",
                    "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}")
            .evaluate(with: vm.resetEmail.trimmingCharacters(in: .whitespaces))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#60C1F0"), location: 0.0),
                        .init(color: Color(hex: "#90DE9B"), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Reset your password")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("We'll send a link to your email.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.80))
                    }
                    .padding(.top, 24)

                    HStack(spacing: 10) {
                        Image(systemName: "envelope")
                            .font(.system(size: 14)).foregroundColor(Color(.systemGray2))
                            .frame(width: 18).accessibilityHidden(true)
                        TextField("Your email address", text: $vm.resetEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .textContentType(.emailAddress)
                            .font(.system(size: 15))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 13)
                    .background(Color(hex: "#F5F6F8"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 24)

                    if let msg = vm.resetSentMessage {
                        Text(msg)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    Button {
                        vm.sendPasswordReset()
                    } label: {
                        ZStack {
                            if vm.isSendingReset {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send Reset Link")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color(hex: "#1F7B4D").opacity(resetEmailValid ? 1 : 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!resetEmailValid || vm.isSendingReset)
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: vm.resetSentMessage)
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

// MARK: - Create account sheet

struct CreateAccountView: View {
    let onSuccess: () -> Void
    @StateObject private var caVM = CreateAccountViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var caFocus: CAField?

    enum CAField: Hashable { case email, password, confirm }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "#60C1F0"), location: 0.0),
                        .init(color: Color(hex: "#90DE9B"), location: 1.0),
                    ],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Create your account")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 24)

                    VStack(spacing: 12) {
                        // Email
                        VStack(alignment: .leading, spacing: 4) {
                            caTextField("envelope", "Email", $caVM.email,
                                        secure: false, focus: $caFocus, field: .email,
                                        next: .password)
                            if let err = caVM.emailError {
                                Text(err).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 6)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: caVM.emailError)

                        // Password
                        VStack(alignment: .leading, spacing: 4) {
                            caSecureField("lock", "Password (min 6 chars)",
                                          $caVM.password, show: $caVM.showPassword,
                                          focus: $caFocus, field: .password, next: .confirm)
                            if let err = caVM.passwordError {
                                Text(err).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 6)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: caVM.passwordError)

                        // Confirm password
                        VStack(alignment: .leading, spacing: 4) {
                            caSecureField("lock.shield", "Confirm Password",
                                          $caVM.confirm, show: $caVM.showConfirm,
                                          focus: $caFocus, field: .confirm, next: nil)
                            if let err = caVM.confirmError {
                                Text(err).font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.leading, 6)
                                    .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.2), value: caVM.confirmError)
                    }
                    .padding(.horizontal, 24)

                    if let err = caVM.errorMessage {
                        Text(err).font(.system(size: 13)).foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .transition(.opacity)
                    }

                    Button {
                        caFocus = nil
                        caVM.createAccount { onSuccess(); dismiss() }
                    } label: {
                        ZStack {
                            if caVM.isLoading { ProgressView().tint(.white) }
                            else {
                                Text("Create Account")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color(hex: "#1F7B4D").opacity(caVM.canSubmit ? 1 : 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!caVM.canSubmit)
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .animation(.easeInOut(duration: 0.2), value: caVM.errorMessage)
            }
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.light)
        .onTapGesture { caFocus = nil }
    }

    // MARK: - Field builders

    private func caTextField(
        _ icon: String, _ placeholder: String,
        _ text: Binding<String>, secure: Bool,
        focus: FocusState<CAField?>.Binding, field: CAField, next: CAField?
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundColor(Color(.systemGray2))
                .frame(width: 18).accessibilityHidden(true)
            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textContentType(.emailAddress)
                .submitLabel(next == nil ? .done : .next)
                .focused(focus, equals: field)
                .onSubmit { focus.wrappedValue = next }
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Color(hex: "#F5F6F8"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func caSecureField(
        _ icon: String, _ placeholder: String,
        _ text: Binding<String>, show: Binding<Bool>,
        focus: FocusState<CAField?>.Binding, field: CAField, next: CAField?
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14)).foregroundColor(Color(.systemGray2))
                .frame(width: 18).accessibilityHidden(true)
            Group {
                if show.wrappedValue {
                    TextField(placeholder, text: text)
                        .textContentType(field == .confirm ? .password : .newPassword)
                } else {
                    SecureField(placeholder, text: text)
                        .textContentType(field == .confirm ? .password : .newPassword)
                }
            }
            .font(.system(size: 15))
            .submitLabel(next == nil ? .done : .next)
            .focused(focus, equals: field)
            .onSubmit { focus.wrappedValue = next }

            Button {
                show.wrappedValue.toggle()
            } label: {
                Image(systemName: show.wrappedValue ? "eye.slash" : "eye")
                    .font(.system(size: 14)).foregroundColor(Color(.systemGray2))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(show.wrappedValue ? "Hide password" : "Show password")
        }
        .padding(.horizontal, 14).padding(.vertical, 13)
        .background(Color(hex: "#F5F6F8"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

@MainActor
private final class CreateAccountViewModel: ObservableObject {
    @Published var email        = ""
    @Published var password     = ""
    @Published var confirm      = ""
    @Published var showPassword = false
    @Published var showConfirm  = false
    @Published var isLoading    = false
    @Published var errorMessage: String?

    private static let emailPredicate = NSPredicate(
        format: "SELF MATCHES %@",
        "[A-Z0-9a-z._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}"
    )

    var emailError: String? {
        let t = email.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return nil }
        return Self.emailPredicate.evaluate(with: t) ? nil : "Enter a valid email address"
    }

    var passwordError: String? {
        guard !password.isEmpty else { return nil }
        return password.count >= 6 ? nil : "Must be at least 6 characters"
    }

    var confirmError: String? {
        guard !confirm.isEmpty else { return nil }
        return confirm == password ? nil : "Passwords don't match"
    }

    var canSubmit: Bool {
        emailError == nil && !email.trimmingCharacters(in: .whitespaces).isEmpty
            && passwordError == nil && !password.isEmpty
            && confirmError == nil && !confirm.isEmpty
            && !isLoading
    }

    func createAccount(completion: @escaping () -> Void) {
        guard canSubmit else { return }
        Task {
            isLoading = true; errorMessage = nil
            do {
                try await FirebaseAuthenticationService.shared.createAccount(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                completion()
            } catch {
                isLoading = false
                errorMessage = (error as? LocalizedError)?.errorDescription ?? "Something went wrong."
            }
        }
    }
}
