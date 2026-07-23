import Foundation

enum Direction: String, Codable {
    case toward
    case neutral
    case away

    var emoji: String {
        switch self {
        case .toward:  return "🧭"
        case .neutral: return "⚖️"
        case .away:    return "↩️"
        }
    }

    var shortLabel: String {
        switch self {
        case .toward:  return "Moving Toward Your North Star"
        case .neutral: return "Holding Steady"
        case .away:    return "Drifting From Your Path"
        }
    }

    var hexColor: String {
        switch self {
        case .toward:  return "#7BC67E"
        case .neutral: return "#F0B429"
        case .away:    return "#E8758A"
        }
    }
}

struct DirectionAnalysis: Identifiable, Codable {
    var id: UUID = UUID()
    let entryID: UUID
    let date: Date
    let direction: Direction
    let alignmentScore: Int
    let reason: String
    let coachRecommendation: String
    let summary: String
    let themes: [String]
    var clarificationSuggestion: ClarificationSuggestion? = nil
}
