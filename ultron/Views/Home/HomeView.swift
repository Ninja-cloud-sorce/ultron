import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appVM: AppViewModel
    @StateObject private var journalVM = JournalViewModel()
    @State private var showNewEntry = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch appVM.selectedTab {
                case 0:
                    JourneyView()
                        .environmentObject(journalVM)
                case 1:
                    CampfireView()
                        .environmentObject(journalVM)
                case 3:
                    CalendarView()
                        .environmentObject(journalVM)
                case 4:
                    SettingsView()
                default:
                    JourneyView()
                        .environmentObject(journalVM)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()

            CustomTabBar(selectedTab: $appVM.selectedTab, showNewEntry: $showNewEntry)
        }
        .sheet(isPresented: $showNewEntry) {
            NewEntryView(isPresented: $showNewEntry)
                .environmentObject(journalVM)
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.25), value: appVM.selectedTab)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showNewEntry: Bool

    let tabs: [(icon: String, label: String)] = [
        ("map.fill",      "Journey"),
        ("flame.fill",    "Campfire"),
        ("",              ""),
        ("calendar",      "Calendar"),
        ("gearshape.fill","Settings"),
    ]

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { i in
                    if i == 2 {
                        Spacer().frame(maxWidth: .infinity)
                    } else {
                        TabBarItem(
                            icon: tabs[i].icon,
                            label: tabs[i].label,
                            isSelected: selectedTab == i
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTab = i
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.m)
            .padding(.top, AppTheme.Spacing.m)
            .padding(.bottom, 24)
            .background(
                AppTheme.Colors.bgSurface
                    .shadow(color: .black.opacity(0.4), radius: 20, y: -4)
            )

            Button(action: { showNewEntry = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.accentGold)
                        .frame(width: 58, height: 58)
                        .shadow(color: AppTheme.Colors.accentGold.opacity(0.5), radius: 12, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                }
            }
            .buttonStyle(.plain)
            .offset(y: -20)
        }
    }
}

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
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.Colors.accentGold : AppTheme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
