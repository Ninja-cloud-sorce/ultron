import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    let filters = ["All", "Bookmarked", "Gratitude", "Growth", "Mindfulness"]

    var filteredItems: [LibraryItem] {
        var items = LibraryItem.samples
        if selectedFilter == "Bookmarked" { items = items.filter { $0.isBookmarked } }
        else if selectedFilter != "All"   { items = items.filter { $0.category == selectedFilter } }
        if !searchText.isEmpty { items = items.filter { $0.title.localizedCaseInsensitiveContains(searchText) } }
        return items
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
                    Text("Library")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.left").opacity(0).padding(12)
                }
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.top, 60)
                .padding(.bottom, AppTheme.Spacing.m)

                SearchBar(text: $searchText)
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, AppTheme.Spacing.m)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.s) {
                        ForEach(filters, id: \.self) { filter in
                            FilterChip(label: filter, isSelected: selectedFilter == filter) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                }
                .padding(.bottom, AppTheme.Spacing.m)

                // Items
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.m) {
                        ForEach(filteredItems) { item in
                            LibraryItemRow(item: item)
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, AppTheme.Spacing.s)
                }
            }
        }
        .hideNavigationBar()
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .black : AppTheme.Colors.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.bgElevated)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? .clear : AppTheme.Colors.borderSubtle, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct LibraryItemRow: View {
    let item: LibraryItem

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(AppTheme.Colors.accentTeal.opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.Colors.accentTeal)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Text(item.excerpt)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(item.category)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.Colors.accentTeal)
                    Text("·")
                        .foregroundColor(AppTheme.Colors.textTertiary)
                    Text("\(item.readTime) min read")
                        .font(.system(size: 11))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }

            Spacer()

            Image(systemName: item.isBookmarked ? "bookmark.fill" : "bookmark")
                .foregroundColor(item.isBookmarked ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
                .font(.system(size: 16))
        }
        .padding(AppTheme.Spacing.m)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
    }
}
