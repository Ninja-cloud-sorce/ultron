import UIKit

/// Persists scanned journal images to the local Documents directory.
/// Only relative file paths are stored in the model layer — never raw image data.
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

    private var capturesDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("journal_captures", isDirectory: true)
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
        return "journal_captures/\(filename)"
    }

    func loadImage(relativePath: String) -> UIImage? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return UIImage(contentsOfFile: docs.appendingPathComponent(relativePath).path)
    }
}
