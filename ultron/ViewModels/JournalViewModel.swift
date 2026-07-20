import SwiftUI
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = JournalEntry.sampleEntries
    @Published var currentStreak: Int = 7
    @Published var totalEntries: Int = 24
    @Published var moodHistory: [Mood] = [.calm, .radiant, .grateful, .neutral, .hopeful, .calm, .radiant]

    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        totalEntries += 1
    }

    func toggleBookmark(_ id: UUID) {
        if let idx = entries.firstIndex(where: { $0.id == id }) {
            entries[idx].isBookmarked.toggle()
        }
    }

    var bookmarkedEntries: [JournalEntry] {
        entries.filter { $0.isBookmarked }
    }

    func entries(for date: Date) -> [JournalEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: date) }
    }
}

extension JournalEntry {
    static let sampleEntries: [JournalEntry] = [
        JournalEntry(date: Date(),                              mood: .radiant,  title: "A New Beginning",       text: "Today felt like the first day of something beautiful. The morning light came through the window and I felt genuinely at peace with where I am.",          tags: ["morning", "peace"],       isBookmarked: true),
        JournalEntry(date: Date().addingTimeInterval(-86400),   mood: .calm,     title: "Walking in Stillness",  text: "Took a long walk without my phone. Noticed how the trees move in the wind and remembered that I don't have to have all the answers.",                    tags: ["nature", "mindfulness"],  isBookmarked: false),
        JournalEntry(date: Date().addingTimeInterval(-172800),  mood: .grateful, title: "Small Gifts",           text: "Three things: a warm cup of tea, a message from an old friend, and the smell of rain. That's enough.",                                                   tags: ["gratitude"],              isBookmarked: false),
        JournalEntry(date: Date().addingTimeInterval(-259200),  mood: .hopeful,  title: "Looking Forward",       text: "I made a list of things I want to explore this season. Not goals — just curiosities. It felt freeing.",                                                   tags: ["growth", "intention"],    isBookmarked: true),
        JournalEntry(date: Date().addingTimeInterval(-345600),  mood: .neutral,  title: "Just a Day",            text: "Not every day needs to be transformative. Today was ordinary, and that's okay.",                                                                           tags: ["acceptance"],             isBookmarked: false),
    ]
}
