import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()

    var calendar: Calendar { .current }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.s) {
                        HStack {
                            Text("Calendar")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Text(Date().formatted(.dateTime.month(.wide).year()))
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                    }
                    .padding(.top, 60)

                    // Month navigator
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(8)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(Circle())
                        }
                        Spacer()
                        Text(monthTitle)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Spacer()
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppTheme.Colors.textSecondary)
                                .padding(8)
                                .background(AppTheme.Colors.bgElevated)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Day labels
                    HStack {
                        ForEach(["S","M","T","W","T","F","S"], id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: AppTheme.Spacing.s) {
                        ForEach(calendarDays, id: \.self) { date in
                            CalendarDayCell(
                                date: date,
                                isSelected: date != nil && calendar.isDate(date!, inSameDayAs: selectedDate),
                                isToday: date != nil && calendar.isDateInToday(date!),
                                hasEntry: date != nil && !journalVM.entries(for: date!).isEmpty,
                                moodColor: date != nil ? journalVM.entries(for: date!).first?.mood.color : nil
                            ) {
                                if let d = date { selectedDate = d }
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Entries for selected day
                    let dayEntries = journalVM.entries(for: selectedDate)
                    if !dayEntries.isEmpty {
                        VStack(spacing: AppTheme.Spacing.m) {
                            SectionHeader(
                                title: selectedDate.formatted(date: .abbreviated, time: .omitted),
                                actionLabel: nil
                            )
                            ForEach(dayEntries) { entry in
                                JournalEntryCard(entry: entry) { journalVM.toggleBookmark(entry.id) }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)
                    } else {
                        Text("No entries for this day")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                            .padding(.top, AppTheme.Spacing.m)
                    }

                    Spacer(minLength: 100)
                }
            }
        }
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var calendarDays: [Date?] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else { return [] }
        let weekday = calendar.component(.weekday, from: firstDay) - 1
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDay) {
                days.append(date)
            }
        }
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func previousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
    }

    private func nextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
    }
}

struct CalendarDayCell: View {
    let date: Date?
    let isSelected: Bool
    let isToday: Bool
    let hasEntry: Bool
    let moodColor: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                if let date {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 14, weight: isSelected || isToday ? .semibold : .regular))
                        .foregroundColor(
                            isSelected ? .black :
                            isToday ? AppTheme.Colors.accentGold :
                            AppTheme.Colors.textPrimary
                        )
                        .frame(width: 34, height: 34)
                        .background(
                            isSelected ? AppTheme.Colors.accentGold :
                            isToday ? AppTheme.Colors.accentGold.opacity(0.15) :
                            .clear
                        )
                        .clipShape(Circle())

                    if hasEntry {
                        Circle()
                            .fill(moodColor ?? AppTheme.Colors.accentTeal)
                            .frame(width: 5, height: 5)
                    } else {
                        Circle().fill(.clear).frame(width: 5, height: 5)
                    }
                } else {
                    Color.clear.frame(width: 34, height: 34)
                    Color.clear.frame(width: 5, height: 5)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(date == nil)
    }
}
