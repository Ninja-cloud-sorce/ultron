import Foundation

/// Stores DirectionAnalysis values keyed by journal entry ID in UserDefaults.
final class JournalAnalysisRepository {
    static let shared = JournalAnalysisRepository()
    private init() {}

    private let storageKey = "compass_analyses_v1"
    private let decoder    = JSONDecoder()
    private let encoder    = JSONEncoder()

    private func load() -> [DirectionAnalysis] {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? decoder.decode([DirectionAnalysis].self, from: data)
        else { return [] }
        return decoded
    }

    private func persist(_ analyses: [DirectionAnalysis]) {
        guard let data = try? encoder.encode(analyses) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    func save(_ analysis: DirectionAnalysis) {
        var all = load().filter { $0.entryID != analysis.entryID }
        all.append(analysis)
        persist(all)
    }

    func analysis(forEntryID id: UUID) -> DirectionAnalysis? {
        load().first { $0.entryID == id }
    }

    func allAnalyses() -> [DirectionAnalysis] {
        load().sorted { $0.date > $1.date }
    }

    func mostRecent() -> DirectionAnalysis? {
        load().max { $0.date < $1.date }
    }

    func averageScore() -> Int {
        let all = load()
        guard !all.isEmpty else { return 0 }
        return all.map(\.alignmentScore).reduce(0, +) / all.count
    }

    func bestWeek() -> String  { weekLabel(maximizing: true) }
    func worstWeek() -> String { weekLabel(maximizing: false) }

    private func weekLabel(maximizing: Bool) -> String {
        let all = load()
        guard !all.isEmpty else { return "—" }
        let calendar = Calendar.current
        var weekScores: [Date: [Int]] = [:]
        for a in all {
            guard let start = calendar.dateInterval(of: .weekOfYear, for: a.date)?.start else { continue }
            weekScores[start, default: []].append(a.alignmentScore)
        }
        let target = weekScores.sorted {
            let avgA = $0.value.reduce(0, +) / $0.value.count
            let avgB = $1.value.reduce(0, +) / $1.value.count
            return maximizing ? avgA > avgB : avgA < avgB
        }.first
        guard let start = target?.key else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "Week of \(f.string(from: start))"
    }
}
