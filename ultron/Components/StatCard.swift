import SwiftUI

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    var accentColor: Color = AppTheme.Colors.accentGold
    var trend: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
                Spacer()
                if let trend {
                    Text(trend)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accentTeal)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(AppTheme.Colors.accentTeal.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
