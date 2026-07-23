import Foundation

struct MoodRecord: Identifiable {
    let id: UUID = UUID()
    let date: Date
    let mood: Mood

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
}

extension MoodRecord {
    static let weekSamples: [MoodRecord] = {
        let cal = Calendar.current
        let today = Date()
        let moods: [Mood] = [.calm, .hopeful, .neutral, .radiant, .grateful, .calm, .hopeful]
        return (0..<7).map { offset in
            MoodRecord(
                date: cal.date(byAdding: .day, value: -(6 - offset), to: today)!,
                mood: moods[offset]
            )
        }
    }()
}
