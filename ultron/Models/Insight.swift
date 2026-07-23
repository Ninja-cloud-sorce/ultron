import Foundation

struct Insight: Identifiable {
    let id: UUID = UUID()
    let text: String
    let percentage: String
    let icon: String
}

extension Insight {
    static let samples: [Insight] = [
        Insight(text: "Your mood improves after morning activities", percentage: "71.2%", icon: "sun.max.fill"),
        Insight(text: "Gratitude entries correlate with calmer moods", percentage: "63.5%", icon: "moon.stars.fill"),
        Insight(text: "You write most on Tuesdays and Thursdays",    percentage: "58.0%", icon: "calendar"),
        Insight(text: "Calm moods follow nature-themed reflections",  percentage: "54.8%", icon: "leaf.fill"),
    ]
}
