import SwiftUI

// MARK: - ClarificationSheet

struct ClarificationSheet: View {
    let analysis:   DirectionAnalysis
    let suggestion: ClarificationSuggestion
    let onAccepted: () -> Void

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var journalVM: JournalViewModel

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Handle indicator
                    HStack {
                        Spacer()
                        Capsule()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 36, height: 4)
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.accentGold)
                            Text("A Small Thought")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                        }
                        Text("I want to make sure I captured exactly what you meant.")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    Rectangle()
                        .fill(AppTheme.Colors.borderSubtle)
                        .frame(height: 1)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.vertical, 20)

                    // Original sentence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("YOUR WORDS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.4)

                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.Colors.textTertiary.opacity(0.35))
                                .frame(width: 3)
                            Text(suggestion.originalSentence)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Divider arrow
                    HStack {
                        Spacer()
                        Image(systemName: "arrow.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.textTertiary.opacity(0.4))
                        Spacer()
                    }
                    .padding(.vertical, 12)

                    // Suggested sentence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ONE WAY TO SAY IT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.accentGold.opacity(0.7))
                            .tracking(1.4)

                        HStack(alignment: .top, spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppTheme.Colors.accentGold)
                                .frame(width: 3)
                            Text(suggestion.suggestedSentence)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                .stroke(AppTheme.Colors.accentGold.opacity(0.22), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Explanation
                    Text(suggestion.explanation)
                        .font(.system(size: 13))
                        .italic()
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.top, 14)

                    // Action buttons
                    HStack(spacing: AppTheme.Spacing.m) {
                        Button { dismiss() } label: {
                            Text("I prefer mine")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                                        .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        Button { applyAndDismiss() } label: {
                            Text("Use this")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.bgPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.Colors.accentGold)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, 24)

                    Spacer(minLength: 32)
                }
            }
        }
    }

    private func applyAndDismiss() {
        if let entry = journalVM.entries.first(where: { $0.id == analysis.entryID }) {
            var clarified = entry.text
            if let range = clarified.range(of: suggestion.originalSentence) {
                clarified.replaceSubrange(range, with: suggestion.suggestedSentence)
            }
            journalVM.acceptClarification(entryID: analysis.entryID, clarifiedText: clarified)
        }
        onAccepted()
        dismiss()
    }
}
