import SwiftUI

enum Mood: String, CaseIterable, Codable {
    case radiant  = "Radiant"
    case calm     = "Calm"
    case neutral  = "Neutral"
    case anxious  = "Anxious"
    case low      = "Low"
    case grateful = "Grateful"
    case hopeful  = "Hopeful"

    var emoji: String {
        switch self {
        case .radiant:  return "✨"
        case .calm:     return "🌊"
        case .neutral:  return "☁️"
        case .anxious:  return "🌀"
        case .low:      return "🌧️"
        case .grateful: return "🌸"
        case .hopeful:  return "🌅"
        }
    }

    var color: Color {
        switch self {
        case .radiant:  return Color(hex: "#F0B429")
        case .calm:     return Color(hex: "#4FC3C3")
        case .neutral:  return Color(hex: "#A8AABC")
        case .anxious:  return Color(hex: "#E8758A")
        case .low:      return Color(hex: "#6B8CB8")
        case .grateful: return Color(hex: "#C084FC")
        case .hopeful:  return Color(hex: "#86EFAC")
        }
    }

    var icon: String {
        switch self {
        case .radiant:  return "sun.max.fill"
        case .calm:     return "water.waves"
        case .neutral:  return "cloud.fill"
        case .anxious:  return "tornado"
        case .low:      return "cloud.rain.fill"
        case .grateful: return "heart.fill"
        case .hopeful:  return "sunrise.fill"
        }
    }
}
