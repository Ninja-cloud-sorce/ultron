import SwiftUI
import Combine

@MainActor
class JournalViewModel: ObservableObject {
    @Published private(set) var entries:   [JournalEntry] = []
    @Published var isLoading:              Bool = false
    @Published var latestAnalysis:         DirectionAnalysis? = nil

    // Derived — no @Published needed; updates fire via entries.
    var currentStreak: Int { Self.computeStreak(entryDates: _entryDateSet) }
    var totalEntries:  Int { entries.count }

    var entriesThisMonth: Int {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.entryDate, equalTo: .now, toGranularity: .month) }.count
    }

    /// Last 7 days of moods from real entries, oldest-first.
    var moodHistory: [MoodRecord] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<7).map { offset -> MoodRecord in
            let day = cal.date(byAdding: .day, value: -(6 - offset), to: today)!
            let mood = entries.first { cal.isDate($0.entryDate, inSameDayAs: day) }?.mood ?? .neutral
            return MoodRecord(date: day, mood: mood)
        }
    }

    // Stored set — rebuilt on load, updated incrementally on mutations.
    // Using a stored Set avoids allocating a new Set on every `currentStreak` or `missedDays` call.
    private(set) var _entryDateSet: Set<Date> = []

    // Computed so it always resolves against the currently authenticated user's uid.
    private var bookmarksKey: String { UserContext.shared.key("compass_bookmarked_ids_v1") }
    private let analysisService: AIAnalysisProvider
    // Stored so it can be cancelled on sign-out — prevents a stale analysis writing
    // to the repository after the user has already switched accounts.
    private var analysisTask: Task<Void, Never>?

    init(analysisService: AIAnalysisProvider = GeminiAnalysisService.shared) {
        self.analysisService = analysisService
        latestAnalysis = JournalAnalysisRepository.shared.mostRecent()
        Task { await loadPersistedEntries() }
    }

    /// Cancel any in-flight Gemini analysis. Call on sign-out.
    func cancelPendingAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
    }

    // MARK: – Public API

    func addEntry(_ entry: JournalEntry) {
        guard entry.entryDate <= Calendar.current.startOfDay(for: .now) else { return }
        entries.insert(entry, at: 0)
        _entryDateSet.insert(entry.entryDate)
        analysisTask?.cancel()
        analysisTask = Task {
            await persistToDisk()
            await analyzeEntry(entry)
            analysisTask = nil
        }
    }

    func toggleBookmark(_ id: UUID) {
        guard let idx = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[idx].isBookmarked.toggle()
        persistBookmarks()
        Task { await persistToDisk() }
    }

    func acceptClarification(entryID: UUID, clarifiedText: String) {
        guard let idx = entries.firstIndex(where: { $0.id == entryID }) else { return }
        entries[idx].clarifiedText = clarifiedText
        Task { await persistToDisk() }
    }

    func restoreEntries(_ restored: [JournalEntry]) {
        entries = restored
        _entryDateSet = Set(restored.map { $0.entryDate })
        Task { await persistToDisk() }
    }

    func hasEntry(for date: Date) -> Bool {
        _entryDateSet.contains(Calendar.current.startOfDay(for: date))
    }

    var bookmarkedEntries: [JournalEntry] {
        entries.filter { $0.isBookmarked }
    }

    func entries(for date: Date) -> [JournalEntry] {
        let cal = Calendar.current
        return entries.filter { cal.isDate($0.entryDate, inSameDayAs: date) }
    }

    /// Calendar days in the last `window` days with no entry, most-recent first.
    /// Uses the stored _entryDateSet — O(window), not O(n × window).
    func missedDays(withinDays window: Int = 14) -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        guard let earliest = entries.map({ $0.entryDate }).min() else { return [] }
        let habitStart = calendar.startOfDay(for: earliest)

        let windowStart = calendar.date(byAdding: .day, value: -(window - 1), to: today)!
        let rangeStart  = habitStart > windowStart ? habitStart : windowStart

        var missed: [Date] = []
        var cursor = rangeStart
        while cursor < today {
            if !_entryDateSet.contains(cursor) { missed.append(cursor) }
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return missed.reversed()
    }

    /// Recomputes streak from scratch from the entryDate set — no patched counter.
    static func computeStreak(entryDates: Set<Date>, calendar: Calendar = .current) -> Int {
        var streak = 0
        var cursor = calendar.startOfDay(for: .now)
        while entryDates.contains(cursor) {
            streak += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    // Cancel in-flight Gemini call when HomeView is destroyed on sign-out.
    // Task.cancel() is thread-safe — safe to call from deinit.
    deinit { analysisTask?.cancel() }

    // MARK: – Private

    private func loadPersistedEntries() async {
        isLoading = true

        let loaded = await Task.detached(priority: .utility) {
            JournalEntryStore.load()
        }.value

        let saved = Set(UserDefaults.standard.stringArray(forKey: bookmarksKey) ?? [])

        // New users start with an empty journal — no sample data seeding.
        // Sample data would leak across accounts if not isolated and is misleading in production.
        entries = loaded.map { entry in
            var e = entry
            e.isBookmarked = saved.contains(entry.id.uuidString)
            return e
        }

        _entryDateSet = Set(entries.map { $0.entryDate })
        isLoading = false
    }

    private func persistToDisk() async {
        let snapshot = entries
        await Task.detached(priority: .utility) {
            JournalEntryStore.save(snapshot)
        }.value
    }

    private func analyzeEntry(_ entry: JournalEntry) async {
        let analysis = await analysisService.analyze(entry: entry, northStar: NorthStarService.shared.goal)
        JournalAnalysisRepository.shared.save(analysis)
        latestAnalysis = analysis
    }

    private func persistBookmarks() {
        let ids = entries.filter { $0.isBookmarked }.map { $0.id.uuidString }
        UserDefaults.standard.set(ids, forKey: bookmarksKey)
    }
}

