import Foundation

enum JournalSource: String, Codable {
    case written   // typed by the user
    case captured  // scanned via document camera + OCR
}

struct JournalEntry: Identifiable, Codable {
    var id: UUID = UUID()
    var date: Date = Date()          // actual creation timestamp
    var entryDate: Date = Calendar.current.startOfDay(for: Date())  // calendar day this entry represents, normalized to midnight
    var mood: Mood = .calm
    var title: String = ""
    var text: String = ""
    var tags: [String] = []
    var isBookmarked: Bool = false
    var promptUsed: String? = nil
    var source: JournalSource = .written
    var imagePath: String? = nil    // relative path inside Documents/journal_captures/
    var clarifiedText: String? = nil

    /// True when the entry was written on a different calendar day than the one it represents.
    var wasBackfilled: Bool {
        !Calendar.current.isDate(entryDate, inSameDayAs: date)
    }

    var excerpt: String {
        text.count > 120 ? String(text.prefix(120)) + "…" : text
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: entryDate)
    }

    var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: entryDate)
    }

    var monthString: String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: entryDate)
    }
}
