import Foundation

/// File-backed persistence for journal entries.
/// File path is scoped to the current user's UID via UserContext so no two
/// accounts ever share the same backing file.
enum JournalEntryStore {

    // Computed so it always resolves against the uid that is active at call time.
    private static var fileURL: URL {
        UserContext.shared.fileURL("compass_entries_v1.json")
    }

    static func load() -> [JournalEntry] {
        guard let data = try? Data(contentsOf: fileURL),
              let entries = try? JSONDecoder().decode([JournalEntry].self, from: data)
        else { return [] }
        return entries
    }

    static func save(_ entries: [JournalEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomicWrite)
    }
}
