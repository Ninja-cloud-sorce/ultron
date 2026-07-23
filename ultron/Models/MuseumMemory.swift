import Foundation

enum MemoryType: String, CaseIterable {
    case lessons  = "Lessons"
    case quotes   = "Quotes"
    case memories = "Memories"
}

struct MuseumMemory: Identifiable {
    let id: UUID = UUID()
    let type: MemoryType
    let title: String
    let content: String
    let date: Date
    let imageName: String?
}

extension MuseumMemory {
    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    static let samples: [MuseumMemory] = [
        MuseumMemory(type: .lessons,
                     title: "Biggest Lesson",
                     content: "Progress is quiet, but always happening.",
                     date: Date().addingTimeInterval(-30 * 86400),
                     imageName: nil),
        MuseumMemory(type: .lessons,
                     title: "On Patience",
                     content: "Not every day needs to be transformative. Ordinary days are the foundation.",
                     date: Date().addingTimeInterval(-20 * 86400),
                     imageName: nil),
        MuseumMemory(type: .quotes,
                     title: "Favorite Quote",
                     content: "Be proud of how far you've come.",
                     date: Date().addingTimeInterval(-15 * 86400),
                     imageName: nil),
        MuseumMemory(type: .quotes,
                     title: "Morning Reminder",
                     content: "Show up consistently — in healthy ways.",
                     date: Date().addingTimeInterval(-7 * 86400),
                     imageName: nil),
        MuseumMemory(type: .memories,
                     title: "A New Beginning",
                     content: "Today felt like the first day of something beautiful. The morning light came through the window.",
                     date: Date().addingTimeInterval(-5 * 86400),
                     imageName: nil),
        MuseumMemory(type: .memories,
                     title: "Walking in Stillness",
                     content: "Took a long walk without my phone. Noticed how the trees move in the wind.",
                     date: Date().addingTimeInterval(-10 * 86400),
                     imageName: nil),
    ]
}
