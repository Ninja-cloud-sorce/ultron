import SwiftUI

struct JournalPreferencesView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showTemplatePicker = false

    private let templates = ["Free Write", "Gratitude", "Daily Reflection", "Morning Pages", "Goal Check-in"]
    private let goalOptions = [100, 150, 200, 300, 500, 750, 1000]

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    SettingsSection(title: "Writing") {
                        SettingsRow(icon: "doc.text.fill", iconColor: Color(hex: "#6DB382"), title: "Default Template") {
                            Button {
                                showTemplatePicker = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text(settings.defaultTemplate)
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.Colors.textTertiary)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        SettingsRow(icon: "target", iconColor: Color(hex: "#6DB382"), title: "Daily Word Goal") {
                            Menu {
                                ForEach(goalOptions, id: \.self) { goal in
                                    Button("\(goal) words") { settings.writingGoal = goal }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(settings.writingGoal) words")
                                        .font(.system(size: 13))
                                        .foregroundStyle(AppTheme.Colors.textSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundStyle(AppTheme.Colors.textTertiary)
                                }
                            }
                        }

                        SettingsToggleRow(
                            icon: "arrow.triangle.2.circlepath",
                            iconColor: Color(hex: "#6DB382"),
                            title: "Auto-Save Drafts",
                            isOn: $settings.autoSave
                        )

                        SettingsToggleRow(
                            icon: "iphone.radiowaves.left.and.right",
                            iconColor: Color(hex: "#6DB382"),
                            title: "Haptic Feedback",
                            isOn: $settings.hapticFeedback
                        )
                    }

                    SettingsSection(title: "Capture") {
                        SettingsToggleRow(
                            icon: "camera.fill",
                            iconColor: Color(hex: "#6DB382"),
                            title: "Document Capture",
                            isOn: $settings.captureEnabled
                        )
                        SettingsToggleRow(
                            icon: "text.viewfinder",
                            iconColor: Color(hex: "#6DB382"),
                            title: "OCR Text Extraction",
                            isOn: $settings.ocrEnabled
                        )
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Journal Preferences")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Default Template", isPresented: $showTemplatePicker) {
            ForEach(templates, id: \.self) { t in
                Button(t) { settings.defaultTemplate = t }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
