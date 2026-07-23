import SwiftUI
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    @Published var entries:       [JournalEntry]
    @Published var currentStreak: Int  = 7
    @Published var totalEntries:  Int  = 24
    @Published var moodHistory:    [Mood] = [.calm, .radiant, .grateful, .neutral, .hopeful, .calm, .radiant]
    @Published var latestAnalysis: DirectionAnalysis? = nil

    private let bookmarksKey    = "compass_bookmarked_ids_v1"
    private let analysisService: AIAnalysisProvider = MockAIAnalysisService.shared

    init() {
        // Start from sample entries and reapply any persisted bookmark states
        var base = JournalEntry.sampleEntries
        let saved = Set(UserDefaults.standard.stringArray(forKey: "compass_bookmarked_ids_v1") ?? [])
        for i in base.indices {
            base[i].isBookmarked = saved.contains(base[i].id.uuidString)
        }
        entries = base
        latestAnalysis = JournalAnalysisRepository.shared.mostRecent()
    }

    func addEntry(_ entry: JournalEntry) {
        entries.insert(entry, at: 0)
        totalEntries += 1
        persistBookmarks()
        Task { await analyzeEntry(entry) }
    }

    private func analyzeEntry(_ entry: JournalEntry) async {
        let analysis = await analysisService.analyze(entry: entry, northStar: NorthStarService.shared.goal)
        JournalAnalysisRepository.shared.save(analysis)
        latestAnalysis = analysis
    }

    func toggleBookmark(_ id: UUID) {
        if let idx = entries.firstIndex(where: { $0.id == id }) {
            entries[idx].isBookmarked.toggle()
        }
        persistBookmarks()
    }

    var bookmarkedEntries: [JournalEntry] {
        entries.filter { $0.isBookmarked }
    }

    func entries(for date: Date) -> [JournalEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    func acceptClarification(entryID: UUID, clarifiedText: String) {
        guard let idx = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[idx].clarifiedText = clarifiedText
    }

    // MARK: – Private

    private func persistBookmarks() {
        let ids = entries.filter { $0.isBookmarked }.map { $0.id.uuidString }
        UserDefaults.standard.set(ids, forKey: bookmarksKey)
    }
}

// MARK: - Sample data (stable UUIDs ensure bookmark persistence across launches)

extension JournalEntry {
    static let sampleEntries: [JournalEntry] = [
        JournalEntry(
            id:          UUID(uuidString: "00000001-0000-0000-0000-000000000001")!,
            date:        Date(),
            mood:        .radiant,
            title:       "A New Beginning",
            text:        "Today felt like the first day of something beautiful. The morning light came through the window and I felt genuinely at peace with where I am.",
            tags:        ["morning", "peace"],
            isBookmarked: true
        ),
        JournalEntry(
            id:          UUID(uuidString: "00000002-0000-0000-0000-000000000001")!,
            date:        Date().addingTimeInterval(-86400),
            mood:        .calm,
            title:       "Walking in Stillness",
            text:        "Took a long walk without my phone. Noticed how the trees move in the wind and remembered that I don't have to have all the answers.",
            tags:        ["nature", "mindfulness"],
            isBookmarked: false
        ),
        JournalEntry(
            id:          UUID(uuidString: "00000003-0000-0000-0000-000000000001")!,
            date:        Date().addingTimeInterval(-172800),
            mood:        .grateful,
            title:       "Small Gifts",
            text:        "Three things: a warm cup of tea, a message from an old friend, and the smell of rain. That's enough.",
            tags:        ["gratitude"],
            isBookmarked: false
        ),
        JournalEntry(
            id:          UUID(uuidString: "00000004-0000-0000-0000-000000000001")!,
            date:        Date().addingTimeInterval(-259200),
            mood:        .hopeful,
            title:       "Looking Forward",
            text:        "I made a list of things I want to explore this season. Not goals — just curiosities. It felt freeing.",
            tags:        ["growth", "intention"],
            isBookmarked: true
        ),
        JournalEntry(
            id:          UUID(uuidString: "00000005-0000-0000-0000-000000000001")!,
            date:        Date().addingTimeInterval(-345600),
            mood:        .neutral,
            title:       "Just a Day",
            text:        "Not every day needs to be transformative. Today was ordinary, and that's okay.",
            tags:        ["acceptance"],
            isBookmarked: false
        ),
    ]
}
