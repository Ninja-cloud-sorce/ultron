import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        guard
            let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
            let config = NSDictionary(contentsOf: url) as? [String: Any],
            let googleAppID = config["FIREBASE_GOOGLE_APP_ID"] as? String,
            let gcmSenderID = config["FIREBASE_GCM_SENDER_ID"]  as? String
        else {
            assertionFailure("Config.plist missing or incomplete — Firebase not configured.")
            return true
        }
        let options = FirebaseOptions(googleAppID: googleAppID, gcmSenderID: gcmSenderID)
        options.clientID      = config["FIREBASE_CLIENT_ID"]      as? String
        options.apiKey        = config["FIREBASE_API_KEY"]        as? String
        options.projectID     = config["FIREBASE_PROJECT_ID"]     as? String
        options.storageBucket = config["FIREBASE_STORAGE_BUCKET"] as? String
        options.bundleID      = Bundle.main.bundleIdentifier ?? ""
        FirebaseApp.configure(options: options)
        #endif
        return true
    }
}

@main
struct ultronApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var appVM   = AppViewModel()
    @StateObject private var session = AppSessionState()
    @StateObject private var theme   = ThemeManager.shared
    @StateObject private var network = NetworkMonitor.shared

    init() {
        UIWindow.appearance().backgroundColor = UIColor(
            red: 13/255.0, green: 15/255.0, blue: 26/255.0, alpha: 1
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appVM)
                .environmentObject(session)
                .environmentObject(theme)
                .environmentObject(network)
                .preferredColorScheme(theme.preferredColorScheme)
                .id(theme.activeTheme.rawValue)
                .task {
                    // Verify permission status and re-schedule on every launch so notifications
                    // survive app reinstall, reboot, or system appearance changes.
                    await NotificationManager.shared.refreshStatus()
                    NotificationManager.shared.rescheduleAll()
                }
        }
    }
}
