import SwiftUI

struct HomeScreenView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showReflectionCard = true

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning" }
        if h < 17 { return "Good afternoon" }
        return "Good evening"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {

                    // MARK: Header
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text(greeting + ", Op.")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(AppTheme.Colors.textPrimary)

                            Text(formattedDate)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(.top, 2)

                            Text("\(journalVM.totalEntries) reflections written")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }

                        Spacer()

                        // Mascot bear with floating heart
                        ZStack(alignment: .topTrailing) {
                            BearMascotView()

                            Text("❤️")
                                .font(.system(size: 14))
                                .offset(x: 6, y: -6)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, 60)

                    // MARK: Today's Reflection card
                    if showReflectionCard {
                        TodayReflectionCard {
                            withAnimation(.easeOut(duration: 0.25)) {
                                showReflectionCard = false
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: Stats row
                    HStack(spacing: AppTheme.Spacing.m) {
                        HomeStatCard(icon: "book.fill",                   value: "\(journalVM.totalEntries)", label: "Entries")
                        HomeStatCard(icon: "calendar.badge.checkmark",    value: "\(journalVM.currentStreak)", label: "This Week")
                        HomeStatCard(icon: "calendar",                    value: "31",                        label: "This Month")
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // MARK: Recent Entries
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("RECENT ENTRIES")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .tracking(1.5)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.Spacing.m)

                        VStack(spacing: 0) {
                            ForEach(Array(journalVM.entries.prefix(3).enumerated()), id: \.element.id) { i, entry in
                                RecentEntryRow(entry: entry)
                                if i < min(journalVM.entries.count, 3) - 1 {
                                    Rectangle()
                                        .fill(AppTheme.Colors.borderSubtle)
                                        .frame(height: 1)
                                        .padding(.leading, AppTheme.Spacing.m)
                                }
                            }
                        }
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
    }
}

// MARK: - Bear Mascot
struct BearMascotView: View {
    var body: some View {
        // Crop lan2 image to focus on the bear character (lower-center of the image)
        ZStack {
            Circle()
                .fill(AppTheme.Colors.bgElevated)
                .frame(width: 76, height: 76)
                .overlay(Circle().stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))

            Image("lan2")
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .offset(x: 0, y: 35)   // shift down to center on the bear character
                .frame(width: 68, height: 68)
                .clipShape(Circle())
        }
    }
}

// MARK: - Today's Reflection Card
struct TodayReflectionCard: View {
    let onDismiss: () -> Void

    private var dailyPrompt: String {
        let prompts = [
            "What's on your mind today?",
            "What are you grateful for right now?",
            "What did you learn about yourself this week?",
            "Describe something that brought you peace today.",
            "What is one thing you want to let go of?",
        ]
        let dayIndex = Calendar.current.component(.dayOfYear, from: Date()) % prompts.count
        return prompts[dayIndex]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                Text("TODAY'S REFLECTION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppTheme.Colors.accentGold)
                    .tracking(1.5)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .padding(6)
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dailyPrompt)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(2)

                    Text("Tap to write · \(hoursAgoString) hours ago")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
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

    private var hoursAgoString: String {
        let h = Calendar.current.component(.hour, from: Date())
        return "\(max(1, 24 - h))"
    }
}

// MARK: - Home Stat Card
struct HomeStatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.s) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.Colors.textSecondary)

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
    }
}

// MARK: - Recent Entry Row
struct RecentEntryRow: View {
    let entry: JournalEntry

    private var timeAgo: String {
        let diff = Date().timeIntervalSince(entry.date)
        if diff < 3600 { return "\(max(1, Int(diff / 60)))m ago" }
        if diff < 86400 { return "\(Int(diff / 3600))h ago" }
        return "\(Int(diff / 86400))d ago"
    }

    private var preview: String {
        let text = entry.text.isEmpty ? entry.title : entry.text
        return text
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            Text(preview)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(timeAgo)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .fixedSize()
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.vertical, 14)
    }
}
