import SwiftUI

struct ObservatoryView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRange = "Week"

    private let ranges = ["Week", "Month", "Year", "All"]

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Header ────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(AppTheme.Colors.bgElevated)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        .padding(.bottom, AppTheme.Spacing.s)

                        Text("Observatory")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Insights from your journey")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(Color.white.opacity(0.5))
                            .tracking(0.3)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, 60)
                    .padding(.bottom, AppTheme.Spacing.l)

                    // ── Time filter ───────────────────────────────────────
                    TimeFilterPicker(options: ranges, selected: $selectedRange)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.bottom, AppTheme.Spacing.xl)

                    VStack(spacing: AppTheme.Spacing.l) {

                        // Mood Trend chart
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                                HStack {
                                    Text("Mood Trend")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(selectedRange)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.white.opacity(0.35))
                                }
                                MoodLineChart(records: MoodRecord.weekSamples)
                                    .id(selectedRange) // re-animate on range change
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Top Insights
                        GlassCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                                Text("Top Insights")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)

                                VStack(spacing: AppTheme.Spacing.m) {
                                    ForEach(Insight.samples.prefix(3)) { insight in
                                        InsightRow(insight: insight)
                                        if insight.id != Insight.samples.prefix(3).last?.id {
                                            Divider()
                                                .background(Color.white.opacity(0.08))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        // Quick stats
                        HStack(spacing: AppTheme.Spacing.m) {
                            ObsStatCard(
                                icon: "flame.fill",
                                value: "\(journalVM.currentStreak)",
                                label: "Day Streak",
                                color: AppTheme.Colors.accentGold
                            )
                            ObsStatCard(
                                icon: "book.fill",
                                value: "\(journalVM.totalEntries)",
                                label: "Total Entries",
                                color: AppTheme.Colors.accentTeal
                            )
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .hideNavigationBar()
    }
}

// MARK: - Insight Row

private struct InsightRow: View {
    let insight: Insight

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: insight.icon)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.accentGold)
            }

            Text(insight.text)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            Text(insight.percentage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, alignment: .trailing)
        }
    }
}

// MARK: - Observatory Stat Card

private struct ObsStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                Text(label)
                    .font(.system(size: 11))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            Spacer()
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
