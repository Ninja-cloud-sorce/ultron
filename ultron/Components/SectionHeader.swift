import SwiftUI

struct SectionHeader: View {
    let title: String
    var actionLabel: String? = "See All"
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
            if let label = actionLabel, let action = onAction {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accentGold)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
    }
}
