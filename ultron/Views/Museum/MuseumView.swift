import SwiftUI

struct MuseumView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var filteredEntries: [JournalEntry] {
        if searchText.isEmpty { return journalVM.entries }
        return journalVM.entries.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.text.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
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
                    VStack(spacing: 2) {
                        Text("Museum")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        Text("Your memory archive")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0).padding(12)
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.top, 60)
                .padding(.bottom, AppTheme.Spacing.m)

                SearchBar(text: $searchText, placeholder: "Search memories…")
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.m)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Featured large card
                        if let first = filteredEntries.first {
                            MuseumCard(entry: first, isLarge: true)
                                .padding(.horizontal, AppTheme.Spacing.m)
                        }

                        // Horizontal row of small cards
                        if filteredEntries.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.m) {
                                    ForEach(filteredEntries.dropFirst()) { entry in
                                        MuseumCard(entry: entry)
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.m)
                            }
                        }

                        // Full list
                        VStack(spacing: AppTheme.Spacing.m) {
                            SectionHeader(title: "All Memories", actionLabel: nil)
                            ForEach(filteredEntries) { entry in
                                JournalEntryCard(entry: entry) {
                                    journalVM.toggleBookmark(entry.id)
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.m)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, AppTheme.Spacing.s)
                }
            }
        }
        .hideNavigationBar()
    }
}
