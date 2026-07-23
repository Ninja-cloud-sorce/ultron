import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
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
                .preferredColorScheme(theme.preferredColorScheme)
                .id(theme.activeTheme.rawValue)
        }
    }
}
