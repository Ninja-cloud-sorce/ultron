import SwiftUI

struct AISettingsView: View {
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    infoCard
                    SettingsSection(title: "Analysis") {
                        SettingsToggleRow(
                            icon: "sparkles",
                            iconColor: AppTheme.Colors.accentRose,
                            title: "AI Summaries",
                            isOn: $settings.aiSummaries
                        )
                        SettingsToggleRow(
                            icon: "face.smiling.inverse",
                            iconColor: AppTheme.Colors.accentRose,
                            title: "Mood Detection",
                            isOn: $settings.moodDetection
                        )
                        SettingsToggleRow(
                            icon: "tag.fill",
                            iconColor: AppTheme.Colors.accentRose,
                            title: "Theme Extraction",
                            isOn: $settings.themeExtraction
                        )
                        SettingsToggleRow(
                            icon: "location.north.fill",
                            iconColor: AppTheme.Colors.accentRose,
                            title: "Goal Alignment",
                            isOn: $settings.goalAlignment
                        )
                    }
                    SettingsSection(title: "Features") {
                        SettingsToggleRow(
                            icon: "person.fill.questionmark",
                            iconColor: Color(hex: "#9B8BE6"),
                            title: "AI Life Coach",
                            isOn: $settings.aiCoach
                        )
                        SettingsToggleRow(
                            icon: "magnifyingglass.circle.fill",
                            iconColor: Color(hex: "#9B8BE6"),
                            title: "Semantic Search",
                            isOn: $settings.semanticSearch
                        )
                        SettingsToggleRow(
                            icon: "text.viewfinder",
                            iconColor: Color(hex: "#9B8BE6"),
                            title: "OCR Processing",
                            isOn: $settings.ocrEnabled
                        )
                    }
                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("AI & Insights")
        .navigationBarTitleDisplayMode(.large)
    }

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "cpu.fill")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.Colors.accentRose)
            Text("AI features run on-device and in the cloud. Disabling them saves battery and keeps all analysis private.")
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(16)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppTheme.Colors.borderSubtle, lineWidth: 1))
        .padding(.horizontal, 20)
    }
}
