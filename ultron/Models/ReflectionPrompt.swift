import Foundation

struct ReflectionPrompt: Identifiable {
    var id: UUID = UUID()
    var category: PromptCategory
    var question: String
    var isCompleted: Bool = false

    enum PromptCategory: String, CaseIterable {
        case gratitude   = "Gratitude"
        case growth      = "Growth"
        case mindfulness = "Mindfulness"
        case connection  = "Connection"
        case purpose     = "Purpose"
        case resilience  = "Resilience"

        var icon: String {
            switch self {
            case .gratitude:   return "heart.fill"
            case .growth:      return "leaf.fill"
            case .mindfulness: return "moon.stars.fill"
            case .connection:  return "person.2.fill"
            case .purpose:     return "star.fill"
            case .resilience:  return "mountain.2.fill"
            }
        }

        var color: String {
            switch self {
            case .gratitude:   return "#C084FC"
            case .growth:      return "#86EFAC"
            case .mindfulness: return "#4FC3C3"
            case .connection:  return "#F0B429"
            case .purpose:     return "#E8758A"
            case .resilience:  return "#6B8CB8"
            }
        }
    }
}

extension ReflectionPrompt {
    static let samples: [ReflectionPrompt] = [
        ReflectionPrompt(category: .gratitude,   question: "What three things are you grateful for today?"),
        ReflectionPrompt(category: .growth,      question: "What did you learn about yourself this week?"),
        ReflectionPrompt(category: .mindfulness, question: "Describe a moment of peace you experienced recently."),
        ReflectionPrompt(category: .connection,  question: "Who made you feel seen and heard lately?"),
        ReflectionPrompt(category: .purpose,     question: "What gives your life meaning right now?"),
        ReflectionPrompt(category: .resilience,  question: "How did you overcome a challenge this month?"),
    ]
}
