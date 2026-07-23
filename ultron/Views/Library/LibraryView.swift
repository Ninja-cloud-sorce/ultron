import SwiftUI

// MARK: - Private Types

private enum LibraryTab: String, CaseIterable {
    case timeline  = "Timeline"
    case onThisDay = "On This Day"
    case favorites = "Favorites"
}

private struct LibraryMonthGroup: Identifiable {
    // FIX (Root Cause 1): Use the month-year label as the stable ID.
    // Previously `let id = UUID()` generated a new random ID on every recompute,
    // causing ForEach to treat every item as deleted+re-inserted — firing transition
    // animations that masked the actual bookmark state change.
    var id: String { label }

    let label  : String         // "July 2026"
    let anchor : Date           // start-of-month, for sort order
    let entries: [JournalEntry] // sorted newest-first
}

// MARK: - Library View

struct LibraryView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var searchText            = ""
    @State private var selectedTab           = LibraryTab.timeline
    @State private var cardsIn               = false
    @State private var favoritesFilterActive  = false
    @Namespace private var tabLine

    // MARK: – Data sources

    private var searchFiltered: [JournalEntry] {
        var source = favoritesFilterActive
            ? journalVM.entries.filter { $0.isBookmarked }
            : journalVM.entries
        guard !searchText.isEmpty else { return source }
        let q = searchText.lowercased()
        source = source.filter {
            $0.title.lowercased().contains(q)           ||
            $0.text.lowercased().contains(q)            ||
            $0.tags.contains { $0.lowercased().contains(q) }
        }
        return source
    }

    private var timelineGroups: [LibraryMonthGroup] {
        let cal = Calendar.current
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM yyyy"
        var dict: [String: (Date, [JournalEntry])] = [:]
        for e in searchFiltered {
            let key = fmt.string(from: e.date)
            if dict[key] == nil {
                let anchor = cal.date(from: cal.dateComponents([.year, .month], from: e.date)) ?? e.date
                dict[key] = (anchor, [])
            }
            dict[key]!.1.append(e)
        }
        return dict
            .map { LibraryMonthGroup(label: $0.key, anchor: $0.value.0,
                                     entries: $0.value.1.sorted { $0.date > $1.date }) }
            .sorted { $0.anchor > $1.anchor }
    }

    private var onThisDayEntries: [JournalEntry] {
        let cal = Calendar.current
        let now = Date()
        let m = cal.component(.month, from: now)
        let d = cal.component(.day,   from: now)
        var base = journalVM.entries
        if favoritesFilterActive { base = base.filter { $0.isBookmarked } }
        return base.filter {
            cal.component(.month, from: $0.date) == m &&
            cal.component(.day,   from: $0.date) == d &&
            !cal.isDateInToday($0.date)
        }.sorted { $0.date > $1.date }
    }

    private var favoriteEntries: [JournalEntry] {
        journalVM.entries.filter { $0.isBookmarked }.sorted { $0.date > $1.date }
    }

    // MARK: – Body

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            VStack(spacing: 0) {
                headerSection
                searchSection
                tabsSection
                Rectangle().fill(AppTheme.Colors.borderSubtle).frame(height: 1)
                contentSection
            }
        }
        .hideNavigationBar()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeOut(duration: 0.35)) { cardsIn = true }
            }
        }
    }

    // MARK: – Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Back")

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        favoritesFilterActive.toggle()
                    }
                } label: {
                    Image(systemName: favoritesFilterActive ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(favoritesFilterActive
                                         ? AppTheme.Colors.accentGold : .white)
                        .frame(width: 38, height: 38)
                        .background(favoritesFilterActive
                                     ? AppTheme.Colors.accentGold.opacity(0.15)
                                     : AppTheme.Colors.bgElevated)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(favoritesFilterActive
                                            ? AppTheme.Colors.accentGold.opacity(0.35)
                                            : Color.clear, lineWidth: 1)
                        )
                        .symbolEffect(.bounce, value: favoritesFilterActive)
                }
                .accessibilityLabel(favoritesFilterActive
                                    ? "Showing Favorite Journals"
                                    : "Showing All Journals")
            }
            .padding(.bottom, 4)

            Text("Library")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)
            Text("Your memories, organized.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.top, 56)
        .padding(.bottom, AppTheme.Spacing.m)
    }

    // MARK: – Search

    private var searchSection: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15))
                .foregroundColor(AppTheme.Colors.textTertiary)
            TextField("Search your memories...", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .tint(AppTheme.Colors.accentGold)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, AppTheme.Spacing.m)
        .padding(.bottom, AppTheme.Spacing.m)
    }

    // MARK: – Tabs

    private var tabsSection: some View {
        HStack(spacing: 0) {
            ForEach(LibraryTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.rawValue)
                            .font(.system(size: 14,
                                          weight: selectedTab == tab ? .semibold : .regular))
                            .foregroundColor(selectedTab == tab ? .white
                                                                : AppTheme.Colors.textTertiary)
                            .padding(.vertical, 12)
                        ZStack {
                            Color.clear.frame(height: 2)
                            if selectedTab == tab {
                                AppTheme.Colors.accentGold
                                    .frame(height: 2)
                                    .matchedGeometryEffect(id: "tabIndicator", in: tabLine)
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.m)
    }

    // MARK: – Content router

    @ViewBuilder
    private var contentSection: some View {
        ScrollView(showsIndicators: false) {
            Group {
                switch selectedTab {
                case .timeline:  timelineContent
                case .onThisDay: onThisDayContent
                case .favorites: favoritesContent
                }
            }
        }
    }

    // MARK: – Timeline

    @ViewBuilder
    private var timelineContent: some View {
        if timelineGroups.isEmpty {
            if favoritesFilterActive {
                LibraryFavoritesFilterEmptyState().padding(.top, 60).transition(.opacity)
            } else {
                LibraryEmptyState(icon: "books.vertical",
                                  title: "No entries yet",
                                  message: "Start writing to fill your library.")
                    .padding(.top, 60)
            }
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(timelineGroups) { group in
                    Text(group.label)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .padding(.top, AppTheme.Spacing.l)
                        .padding(.bottom, AppTheme.Spacing.s)

                    ForEach(Array(group.entries.enumerated()), id: \.element.id) { idx, entry in
                        timelineRow(entry: entry,
                                    isLastInGroup: idx == group.entries.count - 1,
                                    delay: Double(idx) * 0.04)
                    }
                }
                Spacer(minLength: 100)
            }
            .animation(.easeInOut(duration: 0.25), value: favoritesFilterActive)
        }
    }

    @ViewBuilder
    private func timelineRow(entry: JournalEntry,
                              isLastInGroup: Bool,
                              delay: Double) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Timeline spine — uses value-type snapshot only for mood color (never changes on bookmark)
            VStack(spacing: 0) {
                Spacer().frame(height: 18)
                Circle()
                    .fill(entry.mood.color.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .shadow(color: entry.mood.color.opacity(0.5), radius: 4)
                if !isLastInGroup {
                    Rectangle()
                        .fill(AppTheme.Colors.borderSubtle)
                        .frame(width: 1.5)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 8)
            .padding(.leading, AppTheme.Spacing.l)

            // FIX (Root Cause 2): Pass only the stable entryID.
            // MemoryCard subscribes to journalVM directly via @EnvironmentObject and
            // reads the CURRENT entry on every render — no stale snapshot.
            MemoryCard(entryID: entry.id)
                .padding(.trailing, AppTheme.Spacing.m)
                .padding(.bottom, AppTheme.Spacing.m)
        }
        .opacity(cardsIn ? 1 : 0)
        .offset(y: cardsIn ? 0 : 10)
        .animation(.easeOut(duration: 0.35).delay(delay), value: cardsIn)
        .transition(.opacity)
    }

    // MARK: – On This Day

    @ViewBuilder
    private var onThisDayContent: some View {
        if onThisDayEntries.isEmpty {
            if favoritesFilterActive {
                LibraryFavoritesFilterEmptyState().padding(.top, 60).transition(.opacity)
            } else {
                LibraryEmptyState(icon: "calendar.badge.clock",
                                  title: "Nothing yet",
                                  message: "Keep journaling — your past self will have stories to share.")
                    .padding(.top, 60)
            }
        } else {
            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("On This Day")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text("Memories from previous years")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.top, AppTheme.Spacing.l)

                ForEach(onThisDayEntries) { entry in
                    OnThisDayCard(entryID: entry.id)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .opacity(cardsIn ? 1 : 0)
                        .animation(.easeOut(duration: 0.35), value: cardsIn)
                        .transition(.opacity)
                }
                Spacer(minLength: 100)
            }
            .animation(.easeInOut(duration: 0.25), value: favoritesFilterActive)
        }
    }

    // MARK: – Favorites tab

    @ViewBuilder
    private var favoritesContent: some View {
        if favoriteEntries.isEmpty {
            LibraryFavoritesFilterEmptyState().padding(.top, 60)
        } else {
            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                Text("\(favoriteEntries.count) saved \(favoriteEntries.count == 1 ? "memory" : "memories")")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, AppTheme.Spacing.l)

                ForEach(Array(favoriteEntries.enumerated()), id: \.element.id) { i, entry in
                    MemoryCard(entryID: entry.id)
                        .padding(.horizontal, AppTheme.Spacing.m)
                        .opacity(cardsIn ? 1 : 0)
                        .offset(y: cardsIn ? 0 : 10)
                        .animation(.easeOut(duration: 0.35).delay(Double(i) * 0.04), value: cardsIn)
                        .transition(.opacity)
                }
                Spacer(minLength: 100)
            }
        }
    }
}

// MARK: - Memory Card
//
// FIX (Root Cause 2): MemoryCard now subscribes to journalVM directly via
// @EnvironmentObject. It receives only a stable entryID and reads the CURRENT
// JournalEntry in its body. When journalVM.entries changes (any bookmark toggle),
// this view independently re-evaluates and always reflects the live source of truth —
// regardless of how the parent ForEach identifies or orders its items.

struct MemoryCard: View {
    @EnvironmentObject private var journalVM: JournalViewModel
    let entryID: UUID

    var body: some View {
        // Always read the live entry — never a cached snapshot
        if let entry = journalVM.entries.first(where: { $0.id == entryID }) {
            cardContent(entry)
        }
    }

    @ViewBuilder
    private func cardContent(_ entry: JournalEntry) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            // ── Date + mood dot + bookmark ─────────────────────────────
            HStack(spacing: 6) {
                Text(shortDate(entry.date))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
                Circle()
                    .fill(entry.mood.color.opacity(0.8))
                    .frame(width: 5, height: 5)
                Spacer()
                bookmarkButton(entry)
            }

            // ── Title ─────────────────────────────────────────────────
            Text(entry.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            // ── Preview ───────────────────────────────────────────────
            Text(entry.excerpt)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(3)
                .lineSpacing(3)

            // ── Tags ──────────────────────────────────────────────────
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(entry.tags.prefix(5), id: \.self) { tag in
                            Text(tag.capitalized)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppTheme.Colors.accentTeal.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppTheme.Colors.accentTeal.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
    }

    private func bookmarkButton(_ entry: JournalEntry) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            journalVM.toggleBookmark(entryID)
        } label: {
            Image(systemName: entry.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(entry.isBookmarked
                                 ? AppTheme.Colors.accentGold
                                 : AppTheme.Colors.textTertiary)
                .symbolEffect(.bounce, value: entry.isBookmarked)
                .animation(.spring(response: 0.3, dampingFraction: 0.65),
                            value: entry.isBookmarked)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.isBookmarked ? "Remove from Favorites" : "Add to Favorites")
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - On This Day Card

private struct OnThisDayCard: View {
    @EnvironmentObject private var journalVM: JournalViewModel
    let entryID: UUID

    var body: some View {
        if let entry = journalVM.entries.first(where: { $0.id == entryID }) {
            cardContent(entry)
        }
    }

    @ViewBuilder
    private func cardContent(_ entry: JournalEntry) -> some View {
        let yearsAgo: Int = Calendar.current
            .dateComponents([.year], from: entry.date, to: Date()).year ?? 0
        let yearsAgoLabel = yearsAgo <= 1 ? "One year ago today" : "\(yearsAgo) years ago today"

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(yearsAgoLabel, systemImage: "clock.arrow.circlepath")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.Colors.accentGold)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(AppTheme.Colors.accentGold.opacity(0.1))
                    .clipShape(Capsule())
                Spacer()
                bookmarkButton(entry)
            }

            Text(entry.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            Text(entry.excerpt)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .lineLimit(3)
                .lineSpacing(3)

            if !entry.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text(tag.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppTheme.Colors.accentTeal.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.Colors.accentTeal.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.m)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 8, y: 4)
    }

    private func bookmarkButton(_ entry: JournalEntry) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            journalVM.toggleBookmark(entryID)
        } label: {
            Image(systemName: entry.isBookmarked ? "bookmark.fill" : "bookmark")
                .font(.system(size: 14))
                .foregroundColor(entry.isBookmarked
                                 ? AppTheme.Colors.accentGold
                                 : AppTheme.Colors.textTertiary)
                .symbolEffect(.bounce, value: entry.isBookmarked)
                .animation(.spring(response: 0.3, dampingFraction: 0.65),
                            value: entry.isBookmarked)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(entry.isBookmarked ? "Remove from Favorites" : "Add to Favorites")
    }
}

// MARK: - Favorites filter empty state

private struct LibraryFavoritesFilterEmptyState: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: "bookmark.slash")
                .font(.system(size: 44))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.bottom, 4)
            Text("No Favorite Memories")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text("Bookmark journals to quickly find the moments\nyou want to revisit.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Generic empty state

private struct LibraryEmptyState: View {
    let icon:    String
    let title:   String
    let message: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.m) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(AppTheme.Colors.textTertiary)
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
    }
}
