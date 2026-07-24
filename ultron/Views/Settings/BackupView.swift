import SwiftUI

struct BackupView: View {
    @StateObject private var settings = SettingsManager.shared
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var isBackingUp   = false
    @State private var isRestoring   = false
    @State private var showRestoreAlert = false
    @State private var showSuccessAlert = false
    @State private var alertMsg      = ""

    // Scoped to the current user's UID so each account's backup is isolated.
    private var backupURL: URL {
        UserContext.shared.fileURL("compass_backup.json")
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    statusCard
                    SettingsSection(title: "Manual") {
                        Button { performBackup() } label: {
                            HStack {
                                SettingsRowBase(icon: "arrow.up.doc.fill", iconColor: AppTheme.Colors.accentTeal, title: "Backup Now")
                                if isBackingUp {
                                    ProgressView().scaleEffect(0.8).padding(.trailing, 16)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isBackingUp)

                        Button { showRestoreAlert = true } label: {
                            SettingsNavRow(icon: "arrow.down.doc.fill", iconColor: AppTheme.Colors.accentGold, title: "Restore Backup")
                        }
                        .buttonStyle(.plain)
                    }
                    SettingsSection(title: "Auto Backup") {
                        SettingsToggleRow(
                            icon: "icloud.and.arrow.up.fill",
                            iconColor: AppTheme.Colors.accentTeal,
                            title: "Auto Backup",
                            isOn: $settings.autoBackup
                        )
                    }
                    infoCard
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Backup & Sync")
        .navigationBarTitleDisplayMode(.large)
        .alert("Restore Backup", isPresented: $showRestoreAlert) {
            Button("Restore", role: .destructive) { performRestore() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace your current journal entries with the backup. Current entries will be lost.")
        }
        .alert("Done", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMsg)
        }
    }

    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Backup")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Text(settings.lastBackupDate.map { formatDate($0) } ?? "Never")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Backup Size")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                    Text(backupFileSize())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.Colors.accentTeal)
                }
            }
            .padding(16)
            .background(AppTheme.Colors.bgElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        }
        .padding(.horizontal, 20)
    }

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.Colors.accentTeal)
            Text("Backups are stored locally on your device. To sync across devices, iCloud Drive backup of the app documents folder is recommended.")
                .font(.system(size: 12))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(16)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private func performBackup() {
        isBackingUp = true
        Task {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(journalVM.entries) {
                try? data.write(to: backupURL)
                settings.lastBackupDate = Date()
                alertMsg = "Backup saved successfully — \(journalVM.entries.count) entries."
            } else {
                alertMsg = "Backup failed. Please try again."
            }
            isBackingUp = false
            showSuccessAlert = true
        }
    }

    private func performRestore() {
        isRestoring = true
        Task {
            guard let data = try? Data(contentsOf: backupURL) else {
                alertMsg = "No backup file found."; showSuccessAlert = true; isRestoring = false; return
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            guard let entries = try? decoder.decode([JournalEntry].self, from: data) else {
                alertMsg = "Could not read backup file."; showSuccessAlert = true; isRestoring = false; return
            }
            await journalVM.restoreEntries(entries)
            alertMsg = "Restored \(entries.count) entries successfully."
            isRestoring = false
            showSuccessAlert = true
        }
    }

    private func backupFileSize() -> String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: backupURL.path),
              let size = attrs[.size] as? Int else { return "No backup" }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}
