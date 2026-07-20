import Foundation

struct Milestone: Identifiable {
    var id: UUID = UUID()
    var title: String
    var description: String
    var icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?
    var requiredEntries: Int

    static let samples: [Milestone] = [
        Milestone(title: "First Step",      description: "Write your first journal entry",      icon: "figure.walk",         isUnlocked: true,  unlockedDate: Date(), requiredEntries: 1),
        Milestone(title: "Week Wanderer",   description: "Journal every day for 7 days",        icon: "calendar",            isUnlocked: true,  unlockedDate: Date(), requiredEntries: 7),
        Milestone(title: "Moon Keeper",     description: "Reach 30 consecutive days",           icon: "moon.stars.fill",     isUnlocked: false, unlockedDate: nil,   requiredEntries: 30),
        Milestone(title: "Season Seeker",   description: "Complete a full 90-day journey",      icon: "leaf.fill",           isUnlocked: false, unlockedDate: nil,   requiredEntries: 90),
        Milestone(title: "Compass Bearer",  description: "Write 100 journal entries",           icon: "safari.fill",         isUnlocked: false, unlockedDate: nil,   requiredEntries: 100),
        Milestone(title: "Star Cartographer", description: "Complete all reflection doors",     icon: "star.fill",           isUnlocked: false, unlockedDate: nil,   requiredEntries: 200),
    ]
}
