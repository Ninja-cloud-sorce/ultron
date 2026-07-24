import Foundation
import Combine

/// Computes achievement unlock state from real user data.
/// All inputs are injected — no hidden dependencies — making this
/// testable and Firebase-replaceable without touching the view.
@MainActor
final class AchievementsViewModel: ObservableObject {
    @Published private(set) var achievements: [Achievement]

    init(totalEntries: Int, currentStreak: Int, hasAIReflection: Bool, hasNorthStar: Bool) {
        achievements = Self.evaluate(
            totalEntries:    totalEntries,
            currentStreak:   currentStreak,
            hasAIReflection: hasAIReflection,
            hasNorthStar:    hasNorthStar
        )
    }

    // MARK: - Evaluation

    private static func evaluate(
        totalEntries:    Int,
        currentStreak:   Int,
        hasAIReflection: Bool,
        hasNorthStar:    Bool
    ) -> [Achievement] {
        [
            Achievement(
                id:          "first_journal",
                title:       "First Journal",
                description: "Create your first journal entry.",
                icon:        "pencil.line",
                colorHex:    "#4FC3C3",
                isUnlocked:  totalEntries >= 1
            ),
            Achievement(
                id:          "north_star_set",
                title:       "North Star Set",
                description: "Choose your long-term North Star goal.",
                icon:        "location.north.fill",
                colorHex:    "#F0B429",
                isUnlocked:  hasNorthStar
            ),
            Achievement(
                id:          "streak_7",
                title:       "7-Day Streak",
                description: "Write for 7 consecutive days.",
                icon:        "flame.fill",
                colorHex:    "#F4845F",
                isUnlocked:  currentStreak >= 7
            ),
            Achievement(
                id:          "ai_reflection",
                title:       "Reflection Explorer",
                description: "Use AI Reflection for the first time.",
                icon:        "sparkles",
                colorHex:    "#9B8BE6",
                isUnlocked:  hasAIReflection
            ),
            Achievement(
                id:          "journals_50",
                title:       "50 Journals",
                description: "Write 50 journal entries.",
                icon:        "book.closed.fill",
                colorHex:    "#6DB382",
                isUnlocked:  totalEntries >= 50
            ),
            Achievement(
                id:          "journals_100",
                title:       "Memory Keeper",
                description: "Write 100 journal entries.",
                icon:        "cloud.fill",
                colorHex:    "#7BC6FF",
                isUnlocked:  totalEntries >= 100
            ),
        ]
    }

    var unlockedCount: Int { achievements.filter(\.isUnlocked).count }
}
