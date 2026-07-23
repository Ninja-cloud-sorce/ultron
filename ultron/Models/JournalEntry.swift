import Foundation

enum JournalSource: String, Codable {
    case written   // typed by the user
    case captured  // scanned via document camera + OCR
}

struct JournalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: Mood = .calm
    var title: String = ""
    var text: String = ""
    var tags: [String] = []
    var isBookmarked: Bool = false
    var promptUsed: String? = nil
    var source: JournalSource = .written
    var imagePath: String? = nil    // relative path inside Documents/journal_captures/
    var clarifiedText: String? = nil

    var excerpt: String {
        text.count > 120 ? String(text.prefix(120)) + "…" : text
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }

    var monthString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }
}
