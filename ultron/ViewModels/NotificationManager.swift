import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var isDenied     = false

    // Morning reminder — user-adjustable time, defaults to 08:00.
    @Published var dailyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyEnabled, forKey: "notif_daily")
            dailyEnabled ? scheduleMorningReminder() : cancelReminder("compass_morning")
        }
    }
    @Published var dailyTime: Date {
        didSet {
            UserDefaults.standard.set(dailyTime, forKey: "notif_daily_time")
            if dailyEnabled { scheduleMorningReminder() }
        }
    }

    // Evening reflection — fixed at 21:00.
    @Published var streakEnabled: Bool {
        didSet {
            UserDefaults.standard.set(streakEnabled, forKey: "notif_streak")
            streakEnabled ? scheduleEveningReminder() : cancelReminder("compass_evening")
        }
    }

    // Weekly reflection — fixed at Sunday 19:00.
    @Published var weeklyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weeklyEnabled, forKey: "notif_weekly")
            weeklyEnabled ? scheduleWeeklyReflection() : cancelReminder("compass_weekly")
        }
    }

    // Motivational quotes — no artwork.
    @Published var quotesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(quotesEnabled, forKey: "notif_quotes")
            quotesEnabled ? scheduleQuotes() : cancelReminders((0..<5).map { "compass_quote_\($0)" })
        }
    }

    private override init() {
        // 1. Initialize all stored properties before calling super.init().
        let ud = UserDefaults.standard
        dailyEnabled  = ud.object(forKey: "notif_daily")   as? Bool ?? false
        streakEnabled = ud.object(forKey: "notif_streak")  as? Bool ?? false
        weeklyEnabled = ud.object(forKey: "notif_weekly")  as? Bool ?? false
        quotesEnabled = ud.object(forKey: "notif_quotes")  as? Bool ?? false

        if let saved = ud.object(forKey: "notif_daily_time") as? Date {
            dailyTime = saved
        } else {
            var c = DateComponents(); c.hour = 8; c.minute = 0
            dailyTime = Calendar.current.date(from: c) ?? Date()
        }

        super.init()

        // 2. Use self only after super.init().
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["compass_daily", "compass_streak"])
        UNUserNotificationCenter.current().delegate = self

        Task { await refreshStatus() }
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            isDenied     = !granted
            return granted
        } catch {
            isDenied = true
            return false
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        isDenied     = settings.authorizationStatus == .denied
    }

    /// Re-schedules all enabled notifications. Call on app launch and when system appearance changes.
    func rescheduleAll() {
        guard isAuthorized else { return }
        if dailyEnabled  { scheduleMorningReminder() }
        if streakEnabled { scheduleEveningReminder() }
        if weeklyEnabled { scheduleWeeklyReflection() }
        if quotesEnabled { scheduleQuotes() }
    }

    // MARK: - Scheduling

    private func scheduleMorningReminder() {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Good morning 🌿"
        content.body  = "What's one intention you'd like to carry with you today?"
        content.sound = .default
        if let a = makeAttachment(assetName: "morning") { content.attachments = [a] }

        var comps = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
        comps.second = 0
        add("compass_morning", content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
    }

    private func scheduleEveningReminder() {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your day deserves a moment. ✨"
        content.body  = "Before you sleep, capture one thought you'll be grateful to remember."
        content.sound = .default
        if let a = makeAttachment(assetName: "reminder") { content.attachments = [a] }

        var comps = DateComponents()
        comps.hour = 21; comps.minute = 0; comps.second = 0
        add("compass_evening", content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
    }

    private func scheduleWeeklyReflection() {
        guard isAuthorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "Pause. Reflect. Grow. ⭐"
        content.body  = "Take a few minutes to look back on your week and celebrate your progress."
        content.sound = .default
        if let a = makeAttachment(assetName: "sunday") { content.attachments = [a] }

        // weekday = 1 → Sunday in the Gregorian calendar.
        var comps = DateComponents()
        comps.weekday = 1; comps.hour = 19; comps.minute = 0; comps.second = 0
        add("compass_weekly", content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
    }

    private func scheduleQuotes() {
        guard isAuthorized else { return }
        let quotes = [
            "The secret of getting ahead is getting started.",
            "Small steps every day lead to big change.",
            "Your journal is a map of your growth.",
            "Clarity comes through reflection.",
            "Write your story, own your journey."
        ]
        for (i, quote) in quotes.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Daily Compass ✨"
            content.body  = quote
            content.sound = .default
            var comps = DateComponents(); comps.hour = 9; comps.minute = i * 3
            add("compass_quote_\(i)", content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        }
    }

    // MARK: - Artwork Attachment

    private func makeAttachment(assetName: String) -> UNNotificationAttachment? {
        guard let image = UIImage(named: assetName) else { return nil }

        let uuid = UUID().uuidString
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

        // PNG first — preserves transparency (alpha channel). JPEG destroys it.
        if let png = image.pngData() {
            let url = cacheDir.appendingPathComponent("notif_\(uuid).png")
            if let a = writeAndAttach(data: png, to: url, identifier: assetName) { return a }
        }
        // JPEG fallback — only for fully-opaque images where transparency doesn't matter.
        if let jpeg = image.jpegData(compressionQuality: 0.92) {
            let url = cacheDir.appendingPathComponent("notif_\(uuid).jpg")
            if let a = writeAndAttach(data: jpeg, to: url, identifier: assetName) { return a }
        }
        return nil
    }

    private func writeAndAttach(data: Data, to url: URL, identifier: String) -> UNNotificationAttachment? {
        do {
            try data.write(to: url, options: .atomic)
            return try UNNotificationAttachment(identifier: identifier, url: url, options: nil)
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private func add(_ id: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) {
        UNUserNotificationCenter.current()
            .add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func cancelReminder(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func cancelReminders(_ ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Show banner + sound even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
