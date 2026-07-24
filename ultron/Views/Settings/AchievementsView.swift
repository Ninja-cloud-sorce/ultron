import SwiftUI

struct AchievementsView: View {
    @EnvironmentObject var journalVM: JournalViewModel

    private var viewModel: AchievementsViewModel {
        AchievementsViewModel(
            totalEntries:    journalVM.totalEntries,
            currentStreak:   journalVM.currentStreak,
            hasAIReflection: JournalAnalysisRepository.shared.allAnalyses().count > 0,
            hasNorthStar:    NorthStarService.shared.isSet
        )
    }

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        let vm = viewModel
        ZStack {
            AppTheme.Colors.bgPrimary.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    progressHeader(vm: vm)

                    LazyVGrid(columns: columns, spacing: 28) {
                        ForEach(vm.achievements) { achievement in
                            AchievementBadge(achievement: achievement)
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
                .padding(.top, 24)
            }
        }
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.large)
    }

    private func progressHeader(vm: AchievementsViewModel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(vm.unlockedCount) of \(vm.achievements.count) Unlocked")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Spacer()
                Text("\(Int(Double(vm.unlockedCount) / Double(max(1, vm.achievements.count)) * 100))%")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.accentGold)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.bgPrimary)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.Colors.accentGold)
                        .frame(
                            width: geo.size.width * CGFloat(vm.unlockedCount) / CGFloat(max(1, vm.achievements.count)),
                            height: 6
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: vm.unlockedCount)
                }
            }
            .frame(height: 6)
        }
        .padding(16)
        .background(AppTheme.Colors.bgElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Badge cell

private struct AchievementBadge: View {
    let achievement: Achievement

    private var accent: Color { Color(hex: achievement.colorHex) }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? accent.opacity(0.15) : AppTheme.Colors.bgElevated)
                    .frame(width: 76, height: 76)
                    .overlay(
                        Circle()
                            .stroke(
                                achievement.isUnlocked ? accent.opacity(0.5) : AppTheme.Colors.borderSubtle,
                                lineWidth: achievement.isUnlocked ? 1.5 : 1
                            )
                    )
                    .shadow(color: achievement.isUnlocked ? accent.opacity(0.22) : .clear, radius: 8, y: 4)

                if achievement.isUnlocked {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(accent)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }

            Text(achievement.title)
                .font(.system(size: 12, weight: achievement.isUnlocked ? .semibold : .regular))
                .foregroundStyle(achievement.isUnlocked ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.45)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: achievement.isUnlocked)
    }
}
