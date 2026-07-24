import Foundation

/// A single achievement that tracks a user milestone.
/// Codable and ID-stable — ready for Firebase sync in a future pass.
struct Achievement: Identifiable, Codable {
    /// Stable string ID — used as Firestore document key.
    let id: String
    let title: String
    let description: String
    let icon: String
    let colorHex: String
    var isUnlocked: Bool
    /// nil until we store real first-unlock timestamps in Firebase.
    var unlockedDate: Date?
}
