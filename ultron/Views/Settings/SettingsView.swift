import SwiftUI

// MARK: - Navigation destinations

enum SettingsDest: Hashable {
    case journalPrefs, notifications, privacy, backup, about, achievements
}

// MARK: - Main Settings View

struct SettingsView: View {
    @EnvironmentObject var appVM:     AppViewModel
    @EnvironmentObject var journalVM: JournalViewModel
    @EnvironmentObject var theme:     ThemeManager
    @StateObject private var settings   = SettingsManager.shared
    @State private var showSignOut      = false
    @State private var showProfile      = false
    @State private var showAppearance   = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        settingsHeader
                        profileCard
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                        achievementsCard
                        prefsSection
                            .padding(.bottom, 24)
                        moreSection
                        Spacer(minLength: 120)
                    }
                }
            }
            .navigationDestination(for: SettingsDest.self) { dest in
                switch dest {
                case .journalPrefs:   JournalPreferencesView()
                case .notifications:  NotificationsView()
                case .privacy:        PrivacyView().environmentObject(journalVM).environmentObject(appVM)
                case .backup:         BackupView().environmentObject(journalVM)
                case .about:          AboutView()
                case .achievements:   AchievementsView().environmentObject(journalVM)
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileEditView().environmentObject(journalVM)
            }
            .sheet(isPresented: $showAppearance) {
                AppearancePickerSheet().environmentObject(theme)
            }
            .alert("Sign Out", isPresented: $showSignOut) {
                Button("Sign Out", role: .destructive) { appVM.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your journal data stays on this device. You can sign back in any time.")
            }
        }
    }

    // MARK: - Header

    private var settingsHeader: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [AppTheme.Colors.bgElevated.opacity(0.6), AppTheme.Colors.bgPrimary],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 130)

            // Decorative compass rose
            Image(systemName: "location.north.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.Colors.accentGold.opacity(0.18), AppTheme.Colors.accentGold.opacity(0.04)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .offset(x: -16, y: 16)

            VStack(alignment: .leading, spacing: 6) {
                Text("Profile & Settings")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("Manage your profile, preferences & app settings")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 56)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        Button { showProfile = true } label: {
            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    avatarView
                    VStack(alignment: .leading, spacing: 4) {
                        Text(settings.username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        Text(settings.journeyQuote)
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .lineLimit(2)
                            .italic()
                    }
                    Spacer()
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(20)

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                statsRow
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var avatarView: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = settings.avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        AppTheme.Colors.accentGold.opacity(0.2)
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(AppTheme.Colors.accentGold)
                    }
                }
            }
            .frame(width: 68, height: 68)
            .clipShape(Circle())
            .overlay(Circle().stroke(AppTheme.Colors.accentGold.opacity(0.4), lineWidth: 2))

            ZStack {
                Circle().fill(AppTheme.Colors.bgSurface).frame(width: 22, height: 22)
                Image(systemName: "camera.fill").font(.system(size: 10)).foregroundStyle(AppTheme.Colors.textSecondary)
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(
                value: "\(journalVM.currentStreak)",
                label: "Day Streak",
                color: AppTheme.Colors.accentGold
            )
            statDivider
            statCell(
                value: "\(journalVM.totalEntries)",
                label: "Journals",
                color: AppTheme.Colors.accentTeal
            )
            statDivider
            statCell(
                value: "\(journalVM.bookmarkedEntries.count)",
                label: "Favorites",
                color: AppTheme.Colors.accentRose
            )
            statDivider
            statCell(
                value: "\(JournalAnalysisRepository.shared.averageScore())%",
                label: "Alignment",
                color: Color(hex: "#9B8BE6")
            )
        }
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(AppTheme.Colors.borderSubtle)
            .frame(width: 1, height: 36)
    }

    // MARK: - Achievements card

    private var achievementsVM: AchievementsViewModel {
        AchievementsViewModel(
            totalEntries:    journalVM.totalEntries,
            currentStreak:   journalVM.currentStreak,
            hasAIReflection: JournalAnalysisRepository.shared.allAnalyses().count > 0,
            hasNorthStar:    NorthStarService.shared.isSet
        )
    }

    private var achievementsCard: some View {
        NavigationLink(value: SettingsDest.achievements) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.Colors.accentGold.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.accentGold)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievements")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                        let vm = achievementsVM
                        Text("\(vm.unlockedCount) of \(vm.achievements.count) unlocked")
                            .font(.system(size: 12))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                Divider()
                    .background(AppTheme.Colors.borderSubtle)

                HStack(spacing: 0) {
                    ForEach(achievementsVM.achievements) { achievement in
                        let accent = Color(hex: achievement.colorHex)
                        ZStack {
                            Circle()
                                .fill(achievement.isUnlocked ? accent.opacity(0.16) : AppTheme.Colors.bgPrimary)
                                .frame(width: 38, height: 38)
                                .overlay(Circle().stroke(achievement.isUnlocked ? accent.opacity(0.4) : AppTheme.Colors.borderSubtle, lineWidth: 1))
                            Image(systemName: achievement.icon)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(achievement.isUnlocked ? accent : AppTheme.Colors.textTertiary)
                        }
                        .opacity(achievement.isUnlocked ? 1.0 : 0.4)
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Preferences section

    private var prefsSection: some View {
        VStack(spacing: 0) {
            sectionLabel("PREFERENCES")
            VStack(spacing: 0) {
                Button { showAppearance = true } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "#9B8BE6").opacity(0.18))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "paintbrush.fill")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(Color(hex: "#9B8BE6"))
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Appearance")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Themes, display & visual style")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                rowDivider
                prefsRow(icon: "bell.fill",           bg: AppTheme.Colors.accentGold, title: "Notifications",  sub: "Daily reminders, streak alerts",   dest: .notifications)
                rowDivider
                prefsRow(icon: "lock.shield.fill",    bg: Color(hex: "#F4845F"), title: "Privacy & Security",  sub: "Face ID, data export, account",    dest: .privacy)
                rowDivider
                prefsRow(icon: "icloud.fill",         bg: AppTheme.Colors.accentTeal, title: "Backup & Sync",  sub: "Cloud backup & restore data",      dest: .backup)
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func prefsRow(icon: String, bg: Color, title: String, sub: String, dest: SettingsDest) -> some View {
        NavigationLink(value: dest) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(bg.opacity(0.18))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(bg)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - More section

    private var moreSection: some View {
        VStack(spacing: 0) {
            sectionLabel("MORE")
            VStack(spacing: 0) {
                NavigationLink(value: SettingsDest.about) {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.Colors.textTertiary.opacity(0.15))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundStyle(AppTheme.Colors.textSecondary)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("About Compass")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(AppTheme.Colors.textPrimary)
                            Text("Version, feedback & open source")
                                .font(.system(size: 12))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)

                rowDivider

                Button { showSignOut = true } label: {
                    HStack(spacing: 14) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(hex: "#E8758A").opacity(0.15))
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(hex: "#E8758A"))
                            )
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(hex: "#E8758A"))
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.Colors.textTertiary)
            .tracking(1.4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
    }

    private var rowDivider: some View {
        Divider()
            .background(AppTheme.Colors.borderSubtle)
            .padding(.leading, 72)
    }
}

// MARK: - Shared setting sub-screen helpers (used by sub-screens in same module)

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.m)
                .padding(.bottom, AppTheme.Spacing.s)

            VStack(spacing: 0) { content }
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
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(iconColor)
            }
            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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
        VStack(spacing: 0) {
            HStack {
                SettingsRowBase(icon: icon, iconColor: iconColor, title: title)
                Toggle("", isOn: $isOn)
                    .tint(AppTheme.Colors.accentGold)
                    .padding(.trailing, AppTheme.Spacing.m)
            }
            Divider().background(AppTheme.Colors.borderSubtle).padding(.leading, 62)
        }
    }
}

struct SettingsNavRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SettingsRowBase(icon: icon, iconColor: iconColor, title: title)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                    .padding(.trailing, AppTheme.Spacing.m)
            }
            Divider().background(AppTheme.Colors.borderSubtle).padding(.leading, 62)
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SettingsRowBase(icon: icon, iconColor: iconColor, title: title)
                trailing.padding(.trailing, AppTheme.Spacing.m)
            }
            Divider().background(AppTheme.Colors.borderSubtle).padding(.leading, 62)
        }
    }
}

// MARK: - North Star edit sheet (kept for north star flow)

struct NorthStarEditSheet: View {
    @Binding var draft: String
    let onSave: () -> Void
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.bgPrimary.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.xl) {
                    Text("What do you want\nto become?")
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, AppTheme.Spacing.xl)
                        .padding(.horizontal, AppTheme.Spacing.m)

                    TextField("Your North Star goal", text: $draft)
                        .font(.system(size: 17))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .tint(AppTheme.Colors.accentGold)
                        .padding(AppTheme.Spacing.m)
                        .background(AppTheme.Colors.bgElevated)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.large).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
                        .focused($focused)
                        .padding(.horizontal, AppTheme.Spacing.m)

                    GlowButton(title: "Save North Star", icon: "checkmark") {
                        focused = false; onSave(); dismiss()
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)

                    Spacer()
                }
            }
            .navigationTitle("North Star")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppTheme.Colors.textSecondary)
                }
            }
        }
        .onAppear { focused = true }
    }
}
