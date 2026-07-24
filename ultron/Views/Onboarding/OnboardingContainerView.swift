import SwiftUI

// MARK: - Step enum

private enum OBStep: Int {
    case welcome, intent, frequency, northStar, ready
}

// MARK: - Option models

private struct IntentOption: Identifiable {
    let id: String
    let icon: String
    let label: String
}

private struct FrequencyOption: Identifiable {
    let id: String
    let icon: String
    let label: String
    let sub: String
}

private let intentOptions: [IntentOption] = [
    .init(id: "understand", icon: "person.fill.viewfinder",      label: "Understand myself better"),
    .init(id: "change",     icon: "arrow.triangle.2.circlepath", label: "Navigate a big change"),
    .init(id: "habit",      icon: "calendar.badge.checkmark",    label: "Build a journaling habit"),
    .init(id: "moods",      icon: "heart.text.square",           label: "Track my moods"),
    .init(id: "goal",       icon: "location.north.fill",         label: "Work toward a goal"),
]

private let frequencyOptions: [FrequencyOption] = [
    .init(id: "never",      icon: "sparkles",               label: "First time",        sub: "I've never tried journaling"),
    .init(id: "tried",      icon: "arrow.counterclockwise", label: "Tried but stopped", sub: "Didn't quite make it stick"),
    .init(id: "occasional", icon: "moon.stars",             label: "Occasionally",      sub: "When something important happens"),
    .init(id: "regular",    icon: "checkmark.seal.fill",    label: "Already a habit",   sub: "It's part of my routine"),
]

// MARK: - Container

struct OnboardingContainerView: View {
    @EnvironmentObject var appVM: AppViewModel

    @State private var step: OBStep = .welcome
    @State private var selectedIntents: Set<String> = []
    @State private var frequency: String? = nil
    @State private var goalText: String = ""

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            switch step {
            case .welcome:
                OBWelcomeView(
                    onNext:   { go(to: .intent) },
                    onSignIn: { appVM.advance(to: .auth) }
                )
                .transition(slideTransition)
                .id(OBStep.welcome.rawValue)

            case .intent:
                OBIntentView(
                    selected: $selectedIntents,
                    onNext:  { go(to: .frequency) },
                    onSkip:  { go(to: .frequency) }
                )
                .transition(slideTransition)
                .id(OBStep.intent.rawValue)

            case .frequency:
                OBFrequencyView(
                    selected: $frequency,
                    onNext:  { go(to: .northStar) },
                    onSkip:  { go(to: .northStar) }
                )
                .transition(slideTransition)
                .id(OBStep.frequency.rawValue)

            case .northStar:
                OBNorthStarView(
                    goalText: $goalText,
                    selectedIntents: selectedIntents,
                    onNext:  { go(to: .ready) },
                    onSkip:  { go(to: .ready) }
                )
                .transition(slideTransition)
                .id(OBStep.northStar.rawValue)

            case .ready:
                OBReadyView(
                    selectedIntents: selectedIntents,
                    goalText: goalText,
                    onBegin: { appVM.finishOnboarding(goal: goalText) }
                )
                .transition(slideTransition)
                .id(OBStep.ready.rawValue)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: step)
    }

    private var slideTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal:   .move(edge: .leading).combined(with: .opacity)
        )
    }

    private func go(to next: OBStep) { step = next }
}

// MARK: - Progress dots (shown on steps 2–4)

private struct OBProgressDots: View {
    let current: Int   // 0-based out of 3

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= current
                          ? AppTheme.Colors.accentGold
                          : AppTheme.Colors.bgElevated)
                    .frame(width: i == current ? 20 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: current)
            }
        }
    }
}

// MARK: - Screen 1: Welcome

private struct OBWelcomeView: View {
    let onNext: () -> Void
    let onSignIn: () -> Void

    @State private var pulse    = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Pulsing glow orb + icon
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGold.opacity(pulse ? 0.18 : 0.07))
                    .frame(width: 170, height: 170)
                    .scaleEffect(pulse ? 1.12 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                        value: pulse
                    )

                Circle()
                    .fill(AppTheme.Colors.accentGold.opacity(0.10))
                    .frame(width: 110, height: 110)

                Image(systemName: "location.north.fill")
                    .font(.system(size: 54, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.Colors.accentGold, AppTheme.Colors.accentTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .padding(.bottom, 48)

            // Headline
            VStack(spacing: 14) {
                Text("Compass")
                    .font(.system(size: 46, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                Text("Your mindful AI companion for\nclearer thinking and deeper growth.")
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 36)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)

            Spacer()

            VStack(spacing: 14) {
                GlowButton(title: "Get Started", icon: "arrow.right") { onNext() }
                    .padding(.horizontal, 24)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Button("Sign In", action: onSignIn)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.accentGold)
                }
            }
            .padding(.bottom, 56)
            .opacity(appeared ? 1 : 0)
            .animation(.easeIn(duration: 0.4).delay(0.45), value: appeared)
        }
        .onAppear {
            pulse    = true
            appeared = true
        }
    }
}

// MARK: - Screen 2: Intent (multi-select)

private struct OBIntentView: View {
    @Binding var selected: Set<String>
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OBProgressDots(current: 0)
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer().frame(height: 36)

            VStack(alignment: .leading, spacing: 8) {
                Text("What brings you\nto Compass?")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Pick everything that resonates.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                ForEach(intentOptions) { opt in
                    OBIntentCard(option: opt, isSelected: selected.contains(opt.id)) {
                        if selected.contains(opt.id) { selected.remove(opt.id) }
                        else { selected.insert(opt.id) }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            GlowButton(title: "Continue", icon: "arrow.right", action: onNext)
                .padding(.horizontal, 24)
                .padding(.bottom, 56)
                .disabled(selected.isEmpty)
                .opacity(selected.isEmpty ? 0.4 : 1.0)
                .animation(.easeOut(duration: 0.2), value: selected.isEmpty)
        }
    }
}

private struct OBIntentCard: View {
    let option: IntentOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? AppTheme.Colors.accentGold.opacity(0.18)
                              : AppTheme.Colors.bgElevated)
                        .frame(width: 44, height: 44)
                    Image(systemName: option.icon)
                        .font(.system(size: 17))
                        .foregroundColor(isSelected
                                         ? AppTheme.Colors.accentGold
                                         : AppTheme.Colors.textSecondary)
                }

                Text(option.label)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected
                                     ? AppTheme.Colors.textPrimary
                                     : AppTheme.Colors.textSecondary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected
                                     ? AppTheme.Colors.accentGold
                                     : AppTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected
                          ? AppTheme.Colors.accentGold.opacity(0.07)
                          : AppTheme.Colors.bgElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(
                                isSelected
                                    ? AppTheme.Colors.accentGold.opacity(0.45)
                                    : AppTheme.Colors.borderSubtle,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Screen 3: Frequency (single-select, auto-advances)

private struct OBFrequencyView: View {
    @Binding var selected: String?
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OBProgressDots(current: 1)
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer().frame(height: 36)

            VStack(alignment: .leading, spacing: 8) {
                Text("Your journaling\nbackground?")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text("Helps Compass meet you where you are.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                ForEach(frequencyOptions) { opt in
                    OBFrequencyCard(option: opt, isSelected: selected == opt.id) {
                        selected = opt.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onNext() }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}

private struct OBFrequencyCard: View {
    let option: FrequencyOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isSelected
                              ? AppTheme.Colors.accentTeal.opacity(0.18)
                              : AppTheme.Colors.bgElevated)
                        .frame(width: 44, height: 44)
                    Image(systemName: option.icon)
                        .font(.system(size: 17))
                        .foregroundColor(isSelected
                                         ? AppTheme.Colors.accentTeal
                                         : AppTheme.Colors.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.label)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Text(option.sub)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.Colors.accentTeal)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected
                          ? AppTheme.Colors.accentTeal.opacity(0.07)
                          : AppTheme.Colors.bgElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                            .stroke(
                                isSelected
                                    ? AppTheme.Colors.accentTeal.opacity(0.45)
                                    : AppTheme.Colors.borderSubtle,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Screen 4: North Star

private struct OBNorthStarView: View {
    @Binding var goalText: String
    let selectedIntents: Set<String>
    let onNext: () -> Void
    let onSkip: () -> Void

    @FocusState private var focused: Bool

    private var contextLine: String {
        if selectedIntents.contains("goal") {
            return "Your North Star keeps every reflection purposeful."
        } else if selectedIntents.contains("change") {
            return "A clear direction makes navigating change easier."
        } else {
            return "This guides every insight Compass builds for you."
        }
    }

    private let examples = [
        "Become an iOS Engineer",
        "Become financially independent",
        "Build something people love",
        "Become more disciplined",
        "Become a better communicator",
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OBProgressDots(current: 2)
                Spacer()
                Button("Skip", action: onSkip)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer().frame(height: 36)

            VStack(alignment: .leading, spacing: 8) {
                Text("Set your\nNorth Star")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(contextLine)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)

            Spacer().frame(height: 24)

            TextField("e.g. Become an iOS Engineer", text: $goalText)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .tint(AppTheme.Colors.accentGold)
                .padding(16)
                .background(AppTheme.Colors.bgElevated)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                        .stroke(
                            focused
                                ? AppTheme.Colors.accentGold.opacity(0.6)
                                : AppTheme.Colors.borderSubtle,
                            lineWidth: 1
                        )
                )
                .focused($focused)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 8) {
                Text("EXAMPLES")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .tracking(1.5)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(examples, id: \.self) { ex in
                            Button { goalText = ex } label: {
                                Text(ex)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(AppTheme.Colors.bgElevated)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.top, 16)

            Spacer()

            VStack(spacing: 12) {
                GlowButton(title: "Set My North Star", icon: "location.north.fill") {
                    focused = false
                    onNext()
                }
                .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 24)

                Button(action: { focused = false; onSkip() }) {
                    Text("Skip for now")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 44)
        }
        .onTapGesture { focused = false }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Screen 5: Ready (personalised preview)

private struct OBReadyView: View {
    let selectedIntents: Set<String>
    let goalText: String
    let onBegin: () -> Void

    @State private var appeared = false

    private struct FeatureRow {
        let icon: String
        let title: String
        let body: String
    }

    private var featureRows: [FeatureRow] {
        var rows: [FeatureRow] = []

        if !goalText.trimmingCharacters(in: .whitespaces).isEmpty || selectedIntents.contains("goal") {
            rows.append(.init(icon: "location.north.fill", title: "North Star Alignment",
                              body: "Every entry mapped back to what you're building toward."))
        }
        if selectedIntents.contains("moods") {
            rows.append(.init(icon: "heart.text.square", title: "Mood Compass",
                              body: "Track emotional patterns across days and weeks."))
        }
        if selectedIntents.contains("habit") {
            rows.append(.init(icon: "calendar.badge.checkmark", title: "Streak Tracker",
                              body: "Daily check-ins to keep your momentum going."))
        }
        if selectedIntents.contains("understand") || selectedIntents.contains("change") {
            rows.append(.init(icon: "sparkles", title: "AI Insights",
                              body: "Patterns and reflections surfaced from your entries."))
        }

        // Always show at least 2
        if rows.isEmpty {
            rows = [
                .init(icon: "sparkles", title: "AI Insights",
                      body: "Patterns and reflections surfaced from your entries."),
                .init(icon: "calendar.badge.checkmark", title: "Streak Tracker",
                      body: "Daily check-ins to keep your momentum going."),
            ]
        } else if rows.count < 2 {
            rows.append(.init(icon: "sparkles", title: "AI Insights",
                              body: "Patterns and reflections surfaced from your entries."))
        }

        return Array(rows.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Check circle
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accentGold)
            }
            .scaleEffect(appeared ? 1 : 0.4)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.05), value: appeared)

            Spacer().frame(height: 24)

            VStack(spacing: 8) {
                Text("Compass is ready.")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.textPrimary)

                if !goalText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text("Working toward: \(goalText)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accentGold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                } else {
                    Text("Personalised for the path ahead.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)

            Spacer().frame(height: 32)

            VStack(spacing: 10) {
                ForEach(Array(featureRows.enumerated()), id: \.offset) { i, row in
                    OBFeatureRow(icon: row.icon, title: row.title, subtitle: row.body)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 18)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8).delay(0.32 + Double(i) * 0.1),
                            value: appeared
                        )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            GlowButton(title: "Let's Begin", icon: "arrow.right", action: onBegin)
                .padding(.horizontal, 24)
                .padding(.bottom, 56)
                .opacity(appeared ? 1 : 0)
                .animation(.easeIn(duration: 0.3).delay(0.65), value: appeared)
        }
        .onAppear { appeared = true }
    }
}

private struct OBFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(AppTheme.Colors.accentGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
