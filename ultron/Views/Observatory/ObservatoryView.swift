import SwiftUI

struct ObservatoryView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    let weekLabels = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    let weekValues: [Double] = [3, 5, 2, 7, 4, 6, 5]
    let moodValues: [Double] = [4, 6, 3, 7, 5, 6, 7]

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                                .padding(12)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text("Observatory")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.left").opacity(0).padding(12)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, 60)

                    // Stats
                    HStack(spacing: AppTheme.Spacing.m) {
                        StatCard(icon: "flame.fill", value: "\(journalVM.currentStreak)", label: "Day Streak", accentColor: AppTheme.Colors.accentGold, trend: "+2")
                        StatCard(icon: "book.fill",  value: "\(journalVM.totalEntries)",  label: "Entries",    accentColor: AppTheme.Colors.accentTeal)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Weekly entries chart
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        SectionHeader(title: "Entries This Week", actionLabel: nil)
                        VStack(spacing: AppTheme.Spacing.s) {
                            BarGraph(values: weekValues, labels: weekLabels, accentColor: AppTheme.Colors.accentGold)
                            HStack {
                                Text("Total: \(Int(weekValues.reduce(0, +))) entries")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                Spacer()
                            }
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    // Mood chart
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                        SectionHeader(title: "Mood Trend", actionLabel: nil)
                        VStack(spacing: AppTheme.Spacing.s) {
                            BarGraph(values: moodValues, labels: weekLabels, accentColor: AppTheme.Colors.accentTeal)
                            HStack {
                                Text("Average mood: Calm")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                                Spacer()
                            }
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    // Mood frequency
                    VStack(spacing: AppTheme.Spacing.m) {
                        SectionHeader(title: "Mood Frequency", actionLabel: nil)
                        VStack(spacing: AppTheme.Spacing.s) {
                            ForEach(Mood.allCases, id: \.rawValue) { mood in
                                MoodFrequencyRow(mood: mood, count: Int.random(in: 1...10), total: 10)
                            }
                        }
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .hideNavigationBar()
    }
}

struct MoodFrequencyRow: View {
    let mood: Mood
    let count: Int
    let total: Int
    @State private var appeared = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: mood.icon)
                .font(.system(size: 14))
                .foregroundColor(mood.color)
                .frame(width: 24)
            Text(mood.rawValue)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .frame(width: 70, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.borderSubtle)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(mood.color.opacity(0.7))
                        .frame(width: appeared ? geo.size.width * CGFloat(count) / CGFloat(total) : 2)
                        .animation(.easeInOut(duration: 0.8), value: appeared)
                }
            }
            .frame(height: 8)
            Text("\(count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .frame(width: 20)
        }
        .onAppear { appeared = true }
    }
}
