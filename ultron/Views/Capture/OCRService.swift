import Vision
import UIKit

/// Extracts text from images using Apple's Vision framework.
/// Supports printed text, handwriting, and mixed content.
final class OCRService {

    enum OCRError: LocalizedError {
        case invalidImage
        var errorDescription: String? {
            "The scanned image could not be processed."
        }
    }

    func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let lines = request.results?
                    .compactMap { $0 as? VNRecognizedTextObservation }
                    .compactMap { $0.topCandidates(1).first?.string } ?? []
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel             = .accurate
            request.usesLanguageCorrection       = true
            request.automaticallyDetectsLanguage = true

            do {
                try VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func recognizeText(in images: [UIImage]) async throws -> String {
        var parts: [String] = []
        for (index, image) in images.enumerated() {
            let pageText = try await recognizeText(in: image)
            guard !pageText.isEmpty else { continue }
            if images.count > 1 { parts.append("— Page \(index + 1) —") }
            parts.append(pageText)
        }
        return parts.joined(separator: "\n\n")
    }
}
