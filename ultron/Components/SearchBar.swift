import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search entries..."

    var body: some View {
        HStack(spacing: AppTheme.Spacing.s) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.Colors.textTertiary)
                .font(.system(size: 15))
            TextField(placeholder, text: $text)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .font(.system(size: 15))
                .tint(AppTheme.Colors.accentGold)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.full))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.full)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}
