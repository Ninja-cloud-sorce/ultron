import Foundation
import Combine

/// In-memory session flag — resets on force-quit, survives tab switches.
/// No UserDefaults persistence: force-quit → replay; tab switch → no replay.
@MainActor
final class AppSessionState: ObservableObject {
    @Published var hasPlayedMascotGreeting = false
}
