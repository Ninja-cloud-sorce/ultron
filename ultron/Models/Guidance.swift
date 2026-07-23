import Foundation

struct Guidance: Identifiable {
    let id: UUID = UUID()
    let message: String
    let insight: String
    let caption: String = "Generated from your recent reflections."
}

extension Guidance {
    // Mock guidance data. Replace with AI-generated content in GuidanceViewModel.requestGuidance().
    static let samples: [Guidance] = [
        Guidance(
            message: "Keep learning.\nYour recent entries show that you become happiest when solving difficult problems.",
            insight: "You've written about learning 12 times this month."
        ),
        Guidance(
            message: "Your consistency is your superpower.\nYou've shown up for yourself even on the hardest days.",
            insight: "Your writing has become noticeably more optimistic over the last two weeks."
        ),
        Guidance(
            message: "Rest is not retreat.\nYour reflections reveal a pattern of growth that comes through stillness.",
            insight: "You consistently reflect after difficult days."
        ),
        Guidance(
            message: "You are becoming the person you always hoped to be.\nTrust the process you've built.",
            insight: "Gratitude appears in 8 of your last 10 entries."
        ),
    ]
}
