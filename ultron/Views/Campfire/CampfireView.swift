import SwiftUI

struct CampfireView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var glowOpacity: Double = 0.7
    @Environment(\.dismiss) private var dismiss

    let prompts = ReflectionPrompt.samples

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero campfire
                    ZStack(alignment: .bottom) {
                        Image("campire")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 320)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .clear, AppTheme.Colors.bgPrimary],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        // Glow ring
                        Circle()
                            .fill(Color(hex: "#F0B429").opacity(glowOpacity * 0.25))
                            .frame(width: 200, height: 200)
                            .blur(radius: 40)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowOpacity)

                        VStack(spacing: AppTheme.Spacing.s) {
                            Text("The Campfire")
                                .font(.system(size: 28, weight: .bold, design: .serif))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("Gather around. Reflect. Share.")
                                .font(.system(size: 14))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                    .frame(height: 320)

                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Daily spark
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
                            SectionHeader(title: "Daily Spark", actionLabel: nil)
                            DailySparkCard()
                        }

                        // Prompts
                        VStack(spacing: AppTheme.Spacing.m) {
                            SectionHeader(title: "Reflection Prompts", onAction: {})
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: AppTheme.Spacing.m) {
                                    ForEach(prompts) { prompt in
                                        PromptCard(prompt: prompt)
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.m)
                            }
                        }

                        // Recent entries
                        VStack(spacing: AppTheme.Spacing.m) {
                            SectionHeader(title: "Around the Fire", onAction: {})
                            VStack(spacing: AppTheme.Spacing.m) {
                                ForEach(journalVM.entries.prefix(2)) { entry in
                                    JournalEntryCard(entry: entry) {
                                        journalVM.toggleBookmark(entry.id)
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.m)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.top, AppTheme.Spacing.l)
                }
            }

            // Nav back
            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppTheme.Colors.textPrimary)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(.leading, AppTheme.Spacing.m)
                    .padding(.top, 56)
                    Spacer()
                }
                Spacer()
            }
        }
        .ignoresSafeArea(edges: .top)
        .hideNavigationBar()
        .onAppear { glowOpacity = 1.0 }
    }
}

struct DailySparkCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.m) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.Colors.accentGold)
                Text("Today's Invitation")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.accentGold)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }

            Text("\"What would you do today if you knew you couldn't fail?\"")
                .font(.system(size: 17, weight: .medium, design: .serif))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .lineSpacing(5)

            GlowButton(title: "Write My Response", icon: "pencil") {}
        }
        .padding(AppTheme.Spacing.m)
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.accentGold.opacity(0.15), AppTheme.Colors.bgElevated],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(AppTheme.Colors.accentGold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, AppTheme.Spacing.m)
    }
}
