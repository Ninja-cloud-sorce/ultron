import SwiftUI

struct CompassMonumentView: View {
    @Environment(\.dismiss) private var dismiss
    let milestones = Milestone.samples
    @State private var glowPulse = false

    var unlockedCount: Int { milestones.filter { $0.isUnlocked }.count }

    var body: some View {
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero
                    ZStack(alignment: .bottom) {
                        Image("Compass Monument")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 360)
                            .clipped()
                            .overlay(
                                LinearGradient(
                                    colors: [.clear, .clear, AppTheme.Colors.bgPrimary],
                                    startPoint: .top, endPoint: .bottom
                                )
                            )

                        // Glow at top of monument
                        Circle()
                            .fill(AppTheme.Colors.accentGold.opacity(glowPulse ? 0.4 : 0.1))
                            .frame(width: 80, height: 80)
                            .blur(radius: 20)
                            .offset(y: -120)
                            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: glowPulse)

                        VStack(spacing: AppTheme.Spacing.s) {
                            Text("Compass Monument")
                                .font(.system(size: 26, weight: .bold, design: .serif))
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Text("\(unlockedCount) of \(milestones.count) milestones reached")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.Colors.textSecondary)
                        }
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                    .frame(height: 360)

                    // Progress ring summary
                    HStack(spacing: AppTheme.Spacing.m) {
                        StatCard(icon: "star.fill",    value: "\(unlockedCount)/\(milestones.count)", label: "Milestones",  accentColor: AppTheme.Colors.accentGold)
                        StatCard(icon: "book.fill",    value: "24",                                   label: "Entries",     accentColor: AppTheme.Colors.accentTeal)
                        StatCard(icon: "flame.fill",   value: "7",                                    label: "Day Streak",  accentColor: AppTheme.Colors.accentRose)
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.top, AppTheme.Spacing.l)

                    // Milestones list
                    VStack(spacing: AppTheme.Spacing.m) {
                        SectionHeader(title: "Your Milestones", actionLabel: nil)
                            .padding(.top, AppTheme.Spacing.l)
                        ForEach(milestones) { milestone in
                            MilestoneCard(milestone: milestone)
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.m)
                    .padding(.bottom, 40)
                }
            }

            // Back button
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
        .onAppear { glowPulse = true }
    }
}
