import SwiftUI

struct NorthStarView: View {
    @EnvironmentObject var appVM: AppViewModel
    @State private var goalText = ""
    @FocusState private var isFocused: Bool

    private let examples = [
        "Become an iOS Engineer",
        "Become financially independent",
        "Build something people love",
        "Become more disciplined",
        "Become a better communicator"
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentGold.opacity(0.12))
                        .frame(width: 96, height: 96)
                    Text("🧭")
                        .font(.system(size: 46))
                }
                .padding(.bottom, AppTheme.Spacing.l)

                Text("What do you want\nto become?")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppTheme.Spacing.s)

                Text("Your North Star guides every reflection.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, AppTheme.Spacing.xl)

                TextField("e.g. Become an iOS Engineer", text: $goalText)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .tint(AppTheme.Colors.accentGold)
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.Colors.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .stroke(
                                isFocused
                                    ? AppTheme.Colors.accentGold.opacity(0.6)
                                    : AppTheme.Colors.borderSubtle,
                                lineWidth: 1
                            )
                    )
                    .focused($isFocused)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.m)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
                    Text("EXAMPLES")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .tracking(1.5)
                        .padding(.horizontal, AppTheme.Spacing.m)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppTheme.Spacing.s) {
                            ForEach(examples, id: \.self) { example in
                                Button { goalText = example } label: {
                                    Text(example)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .padding(.horizontal, AppTheme.Spacing.m)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.Colors.bgElevated)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }
                }
                .padding(.bottom, AppTheme.Spacing.xl)

                Spacer()

                VStack(spacing: AppTheme.Spacing.s) {
                    GlowButton(title: "Set My North Star", icon: "location.north.fill") {
                        isFocused = false
                        appVM.finishNorthStar(goal: goalText)
                    }
                    .disabled(goalText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.horizontal, AppTheme.Spacing.m)

                    Button { appVM.finishNorthStar(goal: nil) } label: {
                        Text("Skip for now")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.vertical, AppTheme.Spacing.s)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 44)
            }
        }
        .onTapGesture { isFocused = false }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}
