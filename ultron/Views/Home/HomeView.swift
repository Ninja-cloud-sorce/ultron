import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var journalVM = JournalViewModel()
    @State private var showNewEntry = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            Group {
                switch appVM.selectedTab {
                case 0:
                    HomeScreenView()
                        .environmentObject(journalVM)
                case 1:
                    JourneyView()
                        .environmentObject(journalVM)
                case 3:
                    CalendarView()
                        .environmentObject(journalVM)
                case 4:
                    SettingsView()
                default:
                    HomeScreenView()
                        .environmentObject(journalVM)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.2), value: appVM.selectedTab)

            CustomTabBar(selectedTab: $appVM.selectedTab, showNewEntry: $showNewEntry)
        }
        .sheet(isPresented: $showNewEntry) {
            NewEntryView(isPresented: $showNewEntry)
                .environmentObject(journalVM)
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showNewEntry: Bool

    // Tab 2 is the FAB placeholder — not a real selectable tab
    private let items: [(icon: String, label: String, tag: Int)] = [
        ("house.fill",       "Home",     0),
        ("map.fill",         "Journey",  1),
        ("calendar",         "Calendar", 3),
        ("gearshape.fill",   "Settings", 4),
    ]

    var body: some View {
        ZStack {
            // Background bar
            HStack(spacing: 0) {
                // Left two tabs
                ForEach(items.prefix(2), id: \.tag) { item in
                    TabBarItem(icon: item.icon, label: item.label, isSelected: selectedTab == item.tag) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = item.tag }
                    }
                }

                // FAB space
                Spacer().frame(maxWidth: .infinity)

                // Right two tabs
                ForEach(items.suffix(2), id: \.tag) { item in
                    TabBarItem(icon: item.icon, label: item.label, isSelected: selectedTab == item.tag) {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedTab = item.tag }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, 28)
            .background(
                AppTheme.Colors.bgSurface
                    .shadow(color: .black.opacity(0.45), radius: 20, y: -4)
            )

            // FAB — centred, elevated above bar
            Button(action: { showNewEntry = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentGold)
                        .frame(width: 58, height: 58)
                        .shadow(color: AppTheme.Colors.accentGold.opacity(0.55), radius: 14, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -18)
        }
    }
}

// MARK: - Tab Bar Item
struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
