import SwiftUI

struct PrivacyView: View {
    @StateObject private var settings = SettingsManager.shared
    @EnvironmentObject var journalVM: JournalViewModel
    @EnvironmentObject var appVM:     AppViewModel
    @State private var showDeleteDataAlert    = false
    @State private var showDeleteAccountAlert = false
    @State private var showExportShare        = false
    @State private var exportURL: URL?        = nil
    @State private var showStatusAlert        = false
    @State private var alertMsg               = ""

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    SettingsSection(title: "Data") {
                        Button {
                            Task {
                                let url = await prepareExportAsync()
                                exportURL = url
                                if url != nil { showExportShare = true }
                            }
                        } label: {
                            SettingsNavRow(icon: "square.and.arrow.up.fill", iconColor: AppTheme.Colors.accentTeal, title: "Export Journal Data")
                        }
                        .buttonStyle(.plain)

                        Button { showDeleteDataAlert = true } label: {
                            HStack {
                                SettingsRowBase(icon: "trash.fill", iconColor: AppTheme.Colors.accentRose, title: "Delete Local Data")
                                    .foregroundStyle(AppTheme.Colors.accentRose)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    SettingsSection(title: "Account") {
                        Button { showDeleteAccountAlert = true } label: {
                            HStack {
                                SettingsRowBase(icon: "person.badge.minus.fill", iconColor: AppTheme.Colors.accentRose, title: "Delete Account")
                                    .foregroundStyle(AppTheme.Colors.accentRose)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    SettingsSection(title: "Legal") {
                        Button { openURL("https://details2.carrd.co") } label: {
                            SettingsNavRow(icon: "hand.raised.fill", iconColor: AppTheme.Colors.textTertiary, title: "Privacy Policy")
                        }
                        .buttonStyle(.plain)

                        Button { openURL("https://conditions9.carrd.co") } label: {
                            SettingsNavRow(icon: "doc.text.fill", iconColor: AppTheme.Colors.textTertiary, title: "Terms of Service")
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.large)
        .alert("Delete Local Data", isPresented: $showDeleteDataAlert) {
            Button("Delete", role: .destructive) { deleteLocalData() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All journal entries and settings on this device will be erased. This cannot be undone.")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Delete", role: .destructive) { deleteAccount() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your account and all associated data will be permanently deleted.")
        }
        .sheet(isPresented: $showExportShare) {
            if let url = exportURL {
                ShareSheet(url: url)
            }
        }
        .alert("Notice", isPresented: $showStatusAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMsg)
        }
    }

    private func prepareExportAsync() async -> URL? {
        let entries = journalVM.entries
        return await Task.detached(priority: .utility) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            guard let data = try? encoder.encode(entries) else { return nil }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("compass_journal_export.json")
            try? data.write(to: url)
            return url
        }.value
    }

    private func deleteLocalData() {
        settings.clearAllLocalData()
        journalVM.restoreEntries([])
        appVM.signOut()
    }

    private func deleteAccount() {
        Task {
            do {
                try await FirebaseAuthenticationService.shared.deleteAccount()
                deleteLocalData()
            } catch {
                alertMsg = "Account deletion failed. Please sign out, sign back in, and try again."
                showStatusAlert = true
            }
        }
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
