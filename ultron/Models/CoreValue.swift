import SwiftUI

struct CoreValue: Identifiable {
    let id: UUID = UUID()
    let name: String
    let progress: Double  // 0.0 – 1.0
    let color: Color
}

extension CoreValue {
    static let samples: [CoreValue] = [
        CoreValue(name: "Growth",     progress: 0.50, color: Color(hex: "#86EFAC")),
        CoreValue(name: "Kindness",   progress: 0.70, color: Color(hex: "#C084FC")),
        CoreValue(name: "Curiosity",  progress: 0.55, color: Color(hex: "#4FC3C3")),
        CoreValue(name: "Discipline", progress: 0.65, color: Color(hex: "#F0B429")),
    ]
}
