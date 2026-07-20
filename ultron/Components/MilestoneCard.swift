import SwiftUI

struct MilestoneCard: View {
    let milestone: Milestone

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(milestone.isUnlocked
                          ? AppTheme.Colors.accentGold.opacity(0.2)
                          : AppTheme.Colors.bgElevated)
                    .frame(width: 52, height: 52)
                Image(systemName: milestone.icon)
                    .font(.system(size: 22))
                    .foregroundColor(milestone.isUnlocked ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
            }
            .shadow(color: milestone.isUnlocked ? AppTheme.Colors.accentGold.opacity(0.3) : .clear, radius: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(milestone.isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                Text(milestone.description)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .lineLimit(2)
                if milestone.isUnlocked, let date = milestone.unlockedDate {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accentTeal)
                } else {
                    Text("\(milestone.requiredEntries) entries required")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }

            Spacer()

            if milestone.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(AppTheme.Colors.accentGold)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .font(.system(size: 14))
            }
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(milestone.isUnlocked
                        ? AppTheme.Colors.accentGold.opacity(0.25)
                        : AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
