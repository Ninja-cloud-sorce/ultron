import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var dailyReminderTime = Date()
    @State private var darkModeEnabled = true
    @State private var hapticEnabled = true
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(spacing: AppTheme.Spacing.s) {
                        Text("Settings")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, 60)

                    // Profile card
                    HStack(spacing: AppTheme.Spacing.m) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.Colors.accentGold.opacity(0.2))
                                .frame(width: 64, height: 64)
                            Image(systemName: "person.fill")
                                .font(.system(size: 28))
                                .foregroundColor(AppTheme.Colors.accentGold)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Wanderer")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("Compass journaler since 2026")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.Colors.textTertiary)
                    }
                    .padding(AppTheme.Spacing.m)
                    .background(AppTheme.Colors.bgElevated)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                    .padding(.horizontal, AppTheme.Spacing.m)

                    // Notifications
                    SettingsSection(title: "Notifications") {
                        SettingsToggleRow(icon: "bell.fill", iconColor: Color(hex: "#F0B429"), title: "Daily Reminder", isOn: $notificationsEnabled)
                        if notificationsEnabled {
                            SettingsRow(icon: "clock.fill", iconColor: AppTheme.Colors.accentTeal, title: "Reminder Time") {
                                DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }

                    // Preferences
                    SettingsSection(title: "Preferences") {
                        SettingsToggleRow(icon: "moon.fill",       iconColor: Color(hex: "#C084FC"), title: "Dark Mode",   isOn: $darkModeEnabled)
                        SettingsToggleRow(icon: "iphone.radiowaves.left.and.right", iconColor: AppTheme.Colors.accentTeal, title: "Haptic Feedback", isOn: $hapticEnabled)
                    }

                    // Privacy
                    SettingsSection(title: "Privacy & Data") {
                        SettingsNavRow(icon: "lock.fill",     iconColor: Color(hex: "#E8758A"), title: "App Lock")
                        SettingsNavRow(icon: "square.and.arrow.up", iconColor: AppTheme.Colors.accentTeal, title: "Export Journal")
                        Button(action: { showDeleteConfirm = true }) {
                            SettingsRowBase(icon: "trash.fill", iconColor: Color(hex: "#E8758A"), title: "Delete All Data")
                                .foregroundColor(Color(hex: "#E8758A"))
                        }
                        .buttonStyle(.plain)
                    }

                    // About
                    SettingsSection(title: "About") {
                        SettingsNavRow(icon: "info.circle.fill",  iconColor: AppTheme.Colors.textTertiary, title: "Version 1.0.0")
                        SettingsNavRow(icon: "doc.text.fill",     iconColor: AppTheme.Colors.textTertiary, title: "Privacy Policy")
                        SettingsNavRow(icon: "hand.raised.fill",  iconColor: AppTheme.Colors.textTertiary, title: "Terms of Service")
                    }

                    Spacer(minLength: 100)
                }
            }
        }
        .alert("Delete All Data", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all your journal entries. This cannot be undone.")
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.bottom, AppTheme.Spacing.s)

            VStack(spacing: 0) {
                content
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
            .padding(.horizontal, AppTheme.Spacing.m)
        }
    }
}

struct SettingsRowBase: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.m) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(iconColor)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.Colors.textPrimary)
            Spacer()
        }
        .padding(AppTheme.Spacing.m)
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            SettingsRowBase(icon: icon, iconColor: iconColor, title: title)
            Toggle("", isOn: $isOn)
                .tint(AppTheme.Colors.accentGold)
                .padding(.trailing, AppTheme.Spacing.m)
        }
        Divider().background(AppTheme.Colors.borderSubtle).padding(.leading, 62)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack {
            SettingsRowBase(icon: icon, iconColor: iconColor, title: title)
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppTheme.Colors.textTertiary)
                .padding(.trailing, AppTheme.Spacing.m)
        }
        Divider().background(AppTheme.Colors.borderSubtle).padding(.leading, 62)
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack {
            SettingsRowBase(icon: icon, iconColor: iconColor, title: title)
            trailing.padding(.trailing, AppTheme.Spacing.m)
        }
        Divider().background(AppTheme.Colors.borderSubtle).padding(.leading, 62)
    }
}
