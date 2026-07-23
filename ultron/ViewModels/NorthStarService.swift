import Foundation

/// Persists and retrieves the user's single long-term North Star goal.
final class NorthStarService {
    static let shared = NorthStarService()
    private init() {}

    private let goalKey = "compass_north_star_goal_v1"
    private let seenKey = "compass_north_star_seen_v1"

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
