import Foundation
import Combine
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var isDenied = false

    @Published var dailyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dailyEnabled, forKey: "notif_daily")
            dailyEnabled ? scheduleDailyReminder() : cancelReminder("compass_daily")
        }
    }
    @Published var dailyTime: Date {
        didSet {
            UserDefaults.standard.set(dailyTime, forKey: "notif_daily_time")
            if dailyEnabled { scheduleDailyReminder() }
        }
    }
    @Published var streakEnabled: Bool {
        didSet {
            UserDefaults.standard.set(streakEnabled, forKey: "notif_streak")
            streakEnabled ? scheduleStreak() : cancelReminder("compass_streak")
        }
    }
    @Published var weeklyEnabled: Bool {
        didSet {
            UserDefaults.standard.set(weeklyEnabled, forKey: "notif_weekly")
            weeklyEnabled ? scheduleWeekly() : cancelReminder("compass_weekly")
        }
    }
    @Published var quotesEnabled: Bool {
        didSet {
            UserDefaults.standard.set(quotesEnabled, forKey: "notif_quotes")
            quotesEnabled ? scheduleQuotes() : cancelReminders((0..<5).map { "compass_quote_\($0)" })
        }
    }

    private init() {
        let ud = UserDefaults.standard
        dailyEnabled  = ud.object(forKey: "notif_daily") as? Bool ?? false
        weeklyEnabled = ud.object(forKey: "notif_weekly") as? Bool ?? false
        streakEnabled = ud.object(forKey: "notif_streak") as? Bool ?? false
        quotesEnabled = ud.object(forKey: "notif_quotes") as? Bool ?? false

        if let saved = ud.object(forKey: "notif_daily_time") as? Date {
            dailyTime = saved
        } else {
            var c = DateComponents(); c.hour = 20; c.minute = 0
            dailyTime = Calendar.current.date(from: c) ?? Date()
        }
        Task { await refreshStatus() }
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted; isDenied = !granted }
            return granted
        } catch {
            await MainActor.run { isDenied = true }
            return false
        }
    }

    func refreshStatus() async {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = s.authorizationStatus == .authorized
            isDenied     = s.authorizationStatus == .denied
        }
    }

    // MARK: - Schedule helpers

    private func scheduleDailyReminder() {
        guard isAuthorized else { return }
        let c = UNMutableNotificationContent()
        c.title = "Time to reflect ✍️"
        c.body  = "Your journal is ready for today's entry."
        c.sound = .default
        var comps = Calendar.current.dateComponents([.hour, .minute], from: dailyTime)
        comps.second = 0
        add("compass_daily", content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
    }

    private func scheduleStreak() {
        guard isAuthorized else { return }
        let c = UNMutableNotificationContent()
        c.title = "Keep your streak alive 🔥"
        c.body  = "Don't forget to journal today."
        c.sound = .default
        var comps = DateComponents(); comps.hour = 21; comps.minute = 0
        add("compass_streak", content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
    }

    private func scheduleWeekly() {
        guard isAuthorized else { return }
        let c = UNMutableNotificationContent()
        c.title = "Your weekly reflection 📊"
        c.body  = "See how your week looked through Compass's lens."
        c.sound = .default
        var comps = DateComponents(); comps.weekday = 1; comps.hour = 10; comps.minute = 0
        add("compass_weekly", content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: true))
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
            let c = UNMutableNotificationContent()
            c.title = "Daily Compass ✨"; c.body = quote; c.sound = .default
            var comps = DateComponents(); comps.hour = 9; comps.minute = i * 3
            add("compass_quote_\(i)", content: c, trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        }
    }

    private func add(_ id: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) {
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    private func cancelReminder(_ id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    private func cancelReminders(_ ids: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
