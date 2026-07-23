import SwiftUI

struct NotificationsView: View {
    @StateObject private var notif = NotificationManager.shared
    @State private var showSettings = false

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if !notif.isAuthorized {
                        permissionBanner
                    }

                    SettingsSection(title: "Daily Reminder") {
                        SettingsToggleRow(
                            icon: "bell.fill",
                            iconColor: AppTheme.Colors.accentGold,
                            title: "Daily Reminder",
                            isOn: $notif.dailyEnabled
                        )
                        if notif.dailyEnabled {
                            SettingsRow(icon: "clock.fill", iconColor: AppTheme.Colors.accentGold, title: "Reminder Time") {
                                DatePicker("", selection: $notif.dailyTime, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                            }
                        }
                    }

                    SettingsSection(title: "Activity") {
                        SettingsToggleRow(
                            icon: "flame.fill",
                            iconColor: Color(hex: "#F4845F"),
                            title: "Streak Reminder",
                            isOn: $notif.streakEnabled
                        )
                        SettingsToggleRow(
                            icon: "chart.bar.fill",
                            iconColor: AppTheme.Colors.accentTeal,
                            title: "Weekly Digest",
                            isOn: $notif.weeklyEnabled
                        )
                        SettingsToggleRow(
                            icon: "sparkles",
                            iconColor: Color(hex: "#9B8BE6"),
                            title: "Motivational Quotes",
                            isOn: $notif.quotesEnabled
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
        .task { await notif.refreshStatus() }
    }

    private var permissionBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "bell.slash.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppTheme.Colors.accentRose)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Notifications are \(notif.isDenied ? "blocked" : "not enabled")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(notif.isDenied
                         ? "Go to Settings → Compass to enable notifications."
                         : "Allow notifications to receive reminders.")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(16)
            .background(AppTheme.Colors.accentRose.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.accentRose.opacity(0.3), lineWidth: 1))

            if notif.isDenied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.accentGold)
            } else {
                Button {
                    Task {
                        let granted = await notif.requestPermission()
                        if !granted { showSettings = true }
                    }
                } label: {
                    Text("Enable Notifications")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppTheme.Colors.accentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }
}
