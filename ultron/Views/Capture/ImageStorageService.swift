import UIKit

/// Persists scanned journal images to the local Documents directory.
/// The captures directory is scoped to the current user's UID via UserContext
/// so no two accounts share image storage.
/// Only the image filename is stored in the model — the full path is reconstructed
/// at load time using the current user's directory.
final class ImageStorageService {

    static let shared = ImageStorageService()
    private init() {}

    enum StorageError: LocalizedError {
        case encodingFailed, directoryCreationFailed
        var errorDescription: String? {
            switch self {
            case .encodingFailed:          return "Failed to encode the scanned image."
            case .directoryCreationFailed: return "Failed to create the capture storage directory."
            }
        }
    }

    // Computed: resolves against the active uid so each user has an isolated images folder.
    private var capturesDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(
            "\(UserContext.shared.uid)_journal_captures",
            isDirectory: true
        )
    }

    /// Saves a UIImage as JPEG and returns a relative path (relative to Documents).
    @discardableResult
    func save(_ image: UIImage) throws -> String {
        let dir = capturesDirectory
        if !FileManager.default.fileExists(atPath: dir.path) {
            do { try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true) }
            catch { throw StorageError.directoryCreationFailed }
        }
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw StorageError.encodingFailed
        }
        let filename = "\(UUID().uuidString).jpg"
        try data.write(to: dir.appendingPathComponent(filename))
        // Store only the filename — loadImage() reconstructs the full path from the
        // current user's captures directory so the path survives account switches.
        return "journal_captures/\(filename)"
    }

    func loadImage(relativePath: String) -> UIImage? {
        // Extract the filename and look in the current user's UID-scoped directory.
        let filename = URL(fileURLWithPath: relativePath).lastPathComponent
        let userScopedPath = capturesDirectory.appendingPathComponent(filename).path
        if let img = UIImage(contentsOfFile: userScopedPath) { return img }

        // Fallback: images captured before the isolation fix lived in the global
        // 'journal_captures/' directory — support loading them transparently.
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return UIImage(contentsOfFile: docs.appendingPathComponent(relativePath).path)
    }
}
