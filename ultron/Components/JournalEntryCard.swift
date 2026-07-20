import SwiftUI

struct JournalEntryCard: View {
    let entry: JournalEntry
    var onBookmark: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(entry.mood.color)
                        .frame(width: 8, height: 8)
                    Text(entry.mood.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(entry.mood.color)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(entry.mood.color.opacity(0.12))
                .clipShape(Capsule())

                Spacer()

                Text(entry.formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)

                Button(action: { onBookmark?() }) {
                    Image(systemName: entry.isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 14))
                        .foregroundColor(entry.isBookmarked ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
                }
            }

            if !entry.title.isEmpty {
                Text(entry.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
            }

            Text(entry.excerpt)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(AppTheme.Colors.borderSubtle)
                            .clipShape(Capsule())
                    }
                }
            }
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
