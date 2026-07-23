import Foundation
import UIKit
import Combine

final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    private enum K {
        static let username        = "settings_username"
        static let userTitle       = "settings_user_title"
        static let journeyQuote    = "settings_journey_quote"
        static let avatarData      = "settings_avatar_data"
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

    @Published var username: String        { didSet { ud.set(username, forKey: K.username) } }
    @Published var userTitle: String       { didSet { ud.set(userTitle, forKey: K.userTitle) } }
    @Published var journeyQuote: String    { didSet { ud.set(journeyQuote, forKey: K.journeyQuote) } }
    @Published var avatarData: Data?       { didSet { ud.set(avatarData, forKey: K.avatarData) } }
    @Published var hapticFeedback: Bool    { didSet { ud.set(hapticFeedback, forKey: K.hapticFeedback) } }
    @Published var autoSave: Bool          { didSet { ud.set(autoSave, forKey: K.autoSave) } }
    @Published var defaultTemplate: String { didSet { ud.set(defaultTemplate, forKey: K.defaultTemplate) } }
    @Published var writingGoal: Int        { didSet { ud.set(writingGoal, forKey: K.writingGoal) } }
    @Published var aiSummaries: Bool       { didSet { ud.set(aiSummaries, forKey: K.aiSummaries) } }
    @Published var moodDetection: Bool     { didSet { ud.set(moodDetection, forKey: K.moodDetection) } }
    @Published var themeExtraction: Bool   { didSet { ud.set(themeExtraction, forKey: K.themeExtract) } }
    @Published var aiCoach: Bool           { didSet { ud.set(aiCoach, forKey: K.aiCoach) } }
    @Published var goalAlignment: Bool     { didSet { ud.set(goalAlignment, forKey: K.goalAlignment) } }
    @Published var semanticSearch: Bool    { didSet { ud.set(semanticSearch, forKey: K.semanticSearch) } }
    @Published var faceIDLock: Bool        { didSet { ud.set(faceIDLock, forKey: K.faceIDLock) } }
    @Published var hidePreview: Bool       { didSet { ud.set(hidePreview, forKey: K.hidePreview) } }
    @Published var autoBackup: Bool        { didSet { ud.set(autoBackup, forKey: K.autoBackup) } }
    @Published var lastBackupDate: Date?   { didSet { if let d = lastBackupDate { ud.set(d, forKey: K.lastBackupDate) } } }
    @Published var captureEnabled: Bool    { didSet { ud.set(captureEnabled, forKey: K.captureEnabled) } }
    @Published var ocrEnabled: Bool        { didSet { ud.set(ocrEnabled, forKey: K.ocrEnabled) } }

    private let ud = UserDefaults.standard

    private init() {
        username        = ud.string(forKey: K.username) ?? "Wanderer"
        userTitle       = ud.string(forKey: K.userTitle) ?? "Explorer • Level 1"
        journeyQuote    = ud.string(forKey: K.journeyQuote) ?? "Every entry is a step forward."
        avatarData      = ud.data(forKey: K.avatarData)
        hapticFeedback  = ud.object(forKey: K.hapticFeedback) as? Bool ?? true
        autoSave        = ud.object(forKey: K.autoSave) as? Bool ?? true
        defaultTemplate = ud.string(forKey: K.defaultTemplate) ?? "Free Write"
        writingGoal     = ud.object(forKey: K.writingGoal) as? Int ?? 200
        aiSummaries     = ud.object(forKey: K.aiSummaries) as? Bool ?? true
        moodDetection   = ud.object(forKey: K.moodDetection) as? Bool ?? true
        themeExtraction = ud.object(forKey: K.themeExtract) as? Bool ?? true
        aiCoach         = ud.object(forKey: K.aiCoach) as? Bool ?? true
        goalAlignment   = ud.object(forKey: K.goalAlignment) as? Bool ?? true
        semanticSearch  = ud.object(forKey: K.semanticSearch) as? Bool ?? true
        faceIDLock      = ud.object(forKey: K.faceIDLock) as? Bool ?? false
        hidePreview     = ud.object(forKey: K.hidePreview) as? Bool ?? false
        autoBackup      = ud.object(forKey: K.autoBackup) as? Bool ?? false
        lastBackupDate  = ud.object(forKey: K.lastBackupDate) as? Date
        captureEnabled  = ud.object(forKey: K.captureEnabled) as? Bool ?? true
        ocrEnabled      = ud.object(forKey: K.ocrEnabled) as? Bool ?? true
    }

    var avatarImage: UIImage? { avatarData.flatMap { UIImage(data: $0) } }

    func clearAllLocalData() {
        if let domain = Bundle.main.bundleIdentifier {
            ud.removePersistentDomain(forName: domain)
        }
    }
}
