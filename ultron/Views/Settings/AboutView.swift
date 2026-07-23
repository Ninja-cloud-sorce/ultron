import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    appHeader
                    SettingsSection(title: "App Info") {
                        SettingsRow(icon: "info.circle.fill", iconColor: AppTheme.Colors.textSecondary, title: "Version") {
                            Text("\(appVersion) (\(buildNumber))")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        SettingsRow(icon: "person.fill", iconColor: AppTheme.Colors.textSecondary, title: "Developer") {
                            Text("Compass Team")
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                    }
                    SettingsSection(title: "Feedback") {
                        Button { openURL("mailto:support@compassapp.io") } label: {
                            SettingsNavRow(icon: "envelope.fill", iconColor: AppTheme.Colors.accentGold, title: "Send Feedback")
                        }
                        .buttonStyle(.plain)

                        Button {
                            guard let url = URL(string: "itms-apps://itunes.apple.com/app/id000000000?action=write-review") else { return }
                            UIApplication.shared.open(url)
                        } label: {
                            SettingsNavRow(icon: "star.fill", iconColor: AppTheme.Colors.accentGold, title: "Rate Compass")
                        }
                        .buttonStyle(.plain)
                    }
                    SettingsSection(title: "Legal") {
                        Button { openURL("https://example.com/privacy") } label: {
                            SettingsNavRow(icon: "hand.raised.fill", iconColor: AppTheme.Colors.textTertiary, title: "Privacy Policy")
                        }
                        .buttonStyle(.plain)

                        Button { openURL("https://example.com/terms") } label: {
                            SettingsNavRow(icon: "doc.text.fill", iconColor: AppTheme.Colors.textTertiary, title: "Terms of Service")
                        }
                        .buttonStyle(.plain)

                        Button { openURL("https://example.com/licenses") } label: {
                            SettingsNavRow(icon: "books.vertical.fill", iconColor: AppTheme.Colors.textTertiary, title: "Open Source Licenses")
                        }
                        .buttonStyle(.plain)
                    }
                    Text("Made with ♥ for reflective minds")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                        .padding(.top, 8)
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("About Compass")
        .navigationBarTitleDisplayMode(.large)
    }

    private var appHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 84, height: 84)
                Image(systemName: "location.north.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.Colors.accentGold)
            }
            Text("Compass")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .foregroundStyle(AppTheme.Colors.textPrimary)
            Text("Your AI-powered journaling companion")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
