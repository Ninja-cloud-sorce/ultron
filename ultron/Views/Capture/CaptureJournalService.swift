import UIKit

/// Coordinates OCR and local image storage for captured journal entries.
final class CaptureJournalService {

    private let ocr:    OCRService
    private let images: ImageStorageService

    init(ocr: OCRService = OCRService(), images: ImageStorageService = .shared) {
        self.ocr    = ocr
        self.images = images
    }

    func recognizeText(from pageImages: [UIImage]) async throws -> String {
        try await ocr.recognizeText(in: pageImages)
    }

    func buildEntry(image: UIImage,
                    text: String,
                    mood: Mood,
                    title: String,
                    tags: [String]) throws -> JournalEntry {
        let path = try images.save(image)
        return JournalEntry(mood: mood, title: title, text: text,
                            tags: tags, source: .captured, imagePath: path)
    }
}
