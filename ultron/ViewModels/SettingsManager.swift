import Foundation
import UIKit
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    // Base key names — at runtime every key is prefixed with the current uid via k().
    private enum K {
        static let username        = "settings_username"
        static let userTitle       = "settings_user_title"
        static let journeyQuote    = "settings_journey_quote"
        static let avatarDataLegacy = "settings_avatar_data"
        static let hapticFeedback  = "settings_haptic"
        static let autoSave        = "settings_auto_save"
        static let defaultTemplate = "settings_template"
        static let writingGoal     = "settings_writing_goal"
        static let aiSummaries     = "settings_ai_summaries"
        static let moodDetection   = "settings_mood_detection"
        static let themeExtract    = "settings_theme_extract"
        static let aiCoach         = "settings_ai_coach"
        static let goalAlignment   = "settings_goal_alignment"
        static let semanticSearch  = "settings_semantic_search"
        static let faceIDLock      = "settings_face_id"
        static let hidePreview     = "settings_hide_preview"
        static let autoBackup      = "settings_auto_backup"
        static let lastBackupDate  = "settings_last_backup"
        static let captureEnabled  = "settings_capture"
        static let ocrEnabled      = "settings_ocr"
    }

    // MARK: - UID-scoped storage helpers

    /// Returns a UserDefaults key scoped to the currently authenticated user.
    private func k(_ base: String) -> String { UserContext.shared.key(base) }

    /// File path for the user's avatar — unique per uid.
    private var avatarFileURL: URL { UserContext.shared.fileURL("compass_avatar.jpg") }

    // When true, didSet observers skip the UserDefaults write (used during reset).
    private var isSuppressingPersist = false

    // MARK: - Published properties

    @Published var username: String        { didSet { persist(username,        k(K.username)) } }
    @Published var userTitle: String       { didSet { persist(userTitle,       k(K.userTitle)) } }
    @Published var journeyQuote: String    { didSet { persist(journeyQuote,    k(K.journeyQuote)) } }
    @Published var avatarData: Data? {
        didSet {
            guard !isSuppressingPersist else { return }
            writeAvatar(avatarData)
        }
    }
    @Published var hapticFeedback: Bool    { didSet { persist(hapticFeedback,  k(K.hapticFeedback)) } }
    @Published var autoSave: Bool          { didSet { persist(autoSave,        k(K.autoSave)) } }
    @Published var defaultTemplate: String { didSet { persist(defaultTemplate, k(K.defaultTemplate)) } }
    @Published var writingGoal: Int        { didSet { persist(writingGoal,     k(K.writingGoal)) } }
    @Published var aiSummaries: Bool       { didSet { persist(aiSummaries,     k(K.aiSummaries)) } }
    @Published var moodDetection: Bool     { didSet { persist(moodDetection,   k(K.moodDetection)) } }
    @Published var themeExtraction: Bool   { didSet { persist(themeExtraction, k(K.themeExtract)) } }
    @Published var aiCoach: Bool           { didSet { persist(aiCoach,         k(K.aiCoach)) } }
    @Published var goalAlignment: Bool     { didSet { persist(goalAlignment,   k(K.goalAlignment)) } }
    @Published var semanticSearch: Bool    { didSet { persist(semanticSearch,  k(K.semanticSearch)) } }
    @Published var faceIDLock: Bool        { didSet { persist(faceIDLock,      k(K.faceIDLock)) } }
    @Published var hidePreview: Bool       { didSet { persist(hidePreview,     k(K.hidePreview)) } }
    @Published var autoBackup: Bool        { didSet { persist(autoBackup,      k(K.autoBackup)) } }
    @Published var lastBackupDate: Date? {
        didSet {
            if let d = lastBackupDate { persist(d, k(K.lastBackupDate)) }
        }
    }
    @Published var captureEnabled: Bool    { didSet { persist(captureEnabled,  k(K.captureEnabled)) } }
    @Published var ocrEnabled: Bool        { didSet { persist(ocrEnabled,      k(K.ocrEnabled)) } }

    private let ud = UserDefaults.standard

    private init() {
        // Load from the uid-scoped keys that are current at init time.
        // If the uid hasn't been set yet (first launch before sign-in),
        // reads fall back to defaults because no data exists for "anonymous".
        username        = ud.string(forKey: UserContext.shared.key(K.username)) ?? "Wanderer"
        userTitle       = ud.string(forKey: UserContext.shared.key(K.userTitle)) ?? "Explorer • Level 1"
        journeyQuote    = ud.string(forKey: UserContext.shared.key(K.journeyQuote)) ?? "Every entry is a step forward."
        avatarData      = nil  // loaded below after all stored properties are set
        hapticFeedback  = ud.object(forKey: UserContext.shared.key(K.hapticFeedback)) as? Bool ?? true
        autoSave        = ud.object(forKey: UserContext.shared.key(K.autoSave)) as? Bool ?? true
        defaultTemplate = ud.string(forKey: UserContext.shared.key(K.defaultTemplate)) ?? "Free Write"
        writingGoal     = ud.object(forKey: UserContext.shared.key(K.writingGoal)) as? Int ?? 200
        aiSummaries     = ud.object(forKey: UserContext.shared.key(K.aiSummaries)) as? Bool ?? true
        moodDetection   = ud.object(forKey: UserContext.shared.key(K.moodDetection)) as? Bool ?? true
        themeExtraction = ud.object(forKey: UserContext.shared.key(K.themeExtract)) as? Bool ?? true
        aiCoach         = ud.object(forKey: UserContext.shared.key(K.aiCoach)) as? Bool ?? true
        goalAlignment   = ud.object(forKey: UserContext.shared.key(K.goalAlignment)) as? Bool ?? true
        semanticSearch  = ud.object(forKey: UserContext.shared.key(K.semanticSearch)) as? Bool ?? true
        faceIDLock      = ud.object(forKey: UserContext.shared.key(K.faceIDLock)) as? Bool ?? false
        hidePreview     = ud.object(forKey: UserContext.shared.key(K.hidePreview)) as? Bool ?? false
        autoBackup      = ud.object(forKey: UserContext.shared.key(K.autoBackup)) as? Bool ?? false
        lastBackupDate  = ud.object(forKey: UserContext.shared.key(K.lastBackupDate)) as? Date
        captureEnabled  = ud.object(forKey: UserContext.shared.key(K.captureEnabled)) as? Bool ?? true
        ocrEnabled      = ud.object(forKey: UserContext.shared.key(K.ocrEnabled)) as? Bool ?? true
        avatarData      = loadAvatarFromDisk()
    }

    // MARK: - User switch support

    /// Reload all settings from the current user's UID-scoped storage.
    /// Call immediately after UserContext.setUser() on sign-in.
    func reload() {
        isSuppressingPersist = true
        defer { isSuppressingPersist = false }

        username        = ud.string(forKey: k(K.username)) ?? "Wanderer"
        userTitle       = ud.string(forKey: k(K.userTitle)) ?? "Explorer • Level 1"
        journeyQuote    = ud.string(forKey: k(K.journeyQuote)) ?? "Every entry is a step forward."
        hapticFeedback  = ud.object(forKey: k(K.hapticFeedback)) as? Bool ?? true
        autoSave        = ud.object(forKey: k(K.autoSave)) as? Bool ?? true
        defaultTemplate = ud.string(forKey: k(K.defaultTemplate)) ?? "Free Write"
        writingGoal     = ud.object(forKey: k(K.writingGoal)) as? Int ?? 200
        aiSummaries     = ud.object(forKey: k(K.aiSummaries)) as? Bool ?? true
        moodDetection   = ud.object(forKey: k(K.moodDetection)) as? Bool ?? true
        themeExtraction = ud.object(forKey: k(K.themeExtract)) as? Bool ?? true
        aiCoach         = ud.object(forKey: k(K.aiCoach)) as? Bool ?? true
        goalAlignment   = ud.object(forKey: k(K.goalAlignment)) as? Bool ?? true
        semanticSearch  = ud.object(forKey: k(K.semanticSearch)) as? Bool ?? true
        faceIDLock      = ud.object(forKey: k(K.faceIDLock)) as? Bool ?? false
        hidePreview     = ud.object(forKey: k(K.hidePreview)) as? Bool ?? false
        autoBackup      = ud.object(forKey: k(K.autoBackup)) as? Bool ?? false
        lastBackupDate  = ud.object(forKey: k(K.lastBackupDate)) as? Date
        captureEnabled  = ud.object(forKey: k(K.captureEnabled)) as? Bool ?? true
        ocrEnabled      = ud.object(forKey: k(K.ocrEnabled)) as? Bool ?? true
        avatarData      = loadAvatarFromDisk()
    }

    /// Reset all in-memory values to defaults without writing to UserDefaults.
    /// Call on sign-out so the next user sees a clean default state while the
    /// previous user's data remains safely stored in their UID-scoped keys.
    func reset() {
        isSuppressingPersist = true
        defer { isSuppressingPersist = false }

        username        = "Wanderer"
        userTitle       = "Explorer • Level 1"
        journeyQuote    = "Every entry is a step forward."
        avatarData      = nil
        hapticFeedback  = true
        autoSave        = true
        defaultTemplate = "Free Write"
        writingGoal     = 200
        aiSummaries     = true
        moodDetection   = true
        themeExtraction = true
        aiCoach         = true
        goalAlignment   = true
        semanticSearch  = true
        faceIDLock      = false
        hidePreview     = false
        autoBackup      = false
        lastBackupDate  = nil
        captureEnabled  = true
        ocrEnabled      = true
    }

    var avatarImage: UIImage? { avatarData.flatMap { UIImage(data: $0) } }

    func clearAllLocalData() {
        if let domain = Bundle.main.bundleIdentifier {
            ud.removePersistentDomain(forName: domain)
        }
        try? FileManager.default.removeItem(at: avatarFileURL)
    }

    // MARK: - Private helpers

    private func persist(_ value: some Any, _ key: String) {
        guard !isSuppressingPersist else { return }
        ud.set(value, forKey: key)
    }

    private func loadAvatarFromDisk() -> Data? {
        if let data = try? Data(contentsOf: avatarFileURL) { return data }
        // One-time migration: if old data exists under the legacy key, move it to disk.
        let legacyKey = k(K.avatarDataLegacy)
        if let legacy = ud.data(forKey: legacyKey) {
            writeAvatar(legacy)
            ud.removeObject(forKey: legacyKey)
            return legacy
        }
        return nil
    }

    private func writeAvatar(_ data: Data?) {
        if let data {
            try? data.write(to: avatarFileURL, options: .atomicWrite)
        } else {
            try? FileManager.default.removeItem(at: avatarFileURL)
        }
    }
}
