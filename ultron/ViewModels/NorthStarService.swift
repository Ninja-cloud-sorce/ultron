import Foundation

/// Persists and retrieves the user's single long-term North Star goal.
/// All storage is scoped to the current user's UID via UserContext.
final class NorthStarService {
    static let shared = NorthStarService()
    private init() {}

    // Keys are computed so they automatically reflect the active uid.
    private var goalKey: String { UserContext.shared.key("compass_north_star_goal_v1") }
    private var seenKey: String { UserContext.shared.key("compass_north_star_seen_v1") }

    var goal: String? {
        get { UserDefaults.standard.string(forKey: goalKey) }
        set { UserDefaults.standard.set(newValue, forKey: goalKey) }
    }

    /// True once the North Star onboarding screen has been shown (even if skipped).
    var hasBeenSeen: Bool {
        get { UserDefaults.standard.bool(forKey: seenKey) }
        set { UserDefaults.standard.set(newValue, forKey: seenKey) }
    }

    var isSet: Bool {
        guard let g = goal else { return false }
        return !g.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
