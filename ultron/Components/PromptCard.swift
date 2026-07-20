import SwiftUI

struct PromptCard: View {
    let prompt: ReflectionPrompt
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color(hex: prompt.category.color).opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: prompt.category.icon)
                            .font(.system(size: 18))
                            .foregroundColor(Color(hex: prompt.category.color))
                    }
                    Spacer()
                    if prompt.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppTheme.Colors.accentTeal)
                    }
                }

                Text(prompt.category.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: prompt.category.color))
                    .tracking(1.5)

                Text(prompt.question)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)

                Text("Reflect →")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: prompt.category.color))
            }
            .padding(AppTheme.Spacing.m)
            .frame(width: 200, alignment: .leading)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .stroke(Color(hex: prompt.category.color).opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
