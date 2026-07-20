import SwiftUI

struct MuseumCard: View {
    let entry: JournalEntry
    var isLarge: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.dayString)
                        .font(.system(size: isLarge ? 32 : 24, weight: .bold))
                        .foregroundColor(AppTheme.Colors.accentGold)
                    Text(entry.monthString)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                Spacer()
                Text(entry.mood.emoji)
                    .font(.system(size: isLarge ? 24 : 18))
            }

            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.system(size: isLarge ? 17 : 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }

            Text(entry.excerpt)
                .font(.system(size: isLarge ? 14 : 12))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(isLarge ? 4 : 2)

            Rectangle()
                .fill(entry.mood.color.opacity(0.5))
                .frame(height: 2)
                .clipShape(Capsule())
        }
        .padding(AppTheme.Spacing.m)
        .frame(width: isLarge ? nil : 160, alignment: .leading)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
