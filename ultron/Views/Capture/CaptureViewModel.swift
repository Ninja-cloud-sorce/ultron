import SwiftUI
import Combine
import UIKit

/// State machine for the document-capture → OCR → AI-clean → animate → save flow.
@MainActor
final class CaptureViewModel: ObservableObject {

    enum FlowState {
        case idle
        case processing([UIImage])
        case animating(UIImage, String)  // writing animation with cleaned text
        case reviewing(UIImage, String)  // kept for direct-save fallback
        case error(String)
    }

    @Published private(set) var flowState: FlowState = .idle
    @Published var isProcessing = false
    @Published var isAnimating  = false
    @Published var isReviewing  = false

    private let service: CaptureJournalService

    init() { self.service = CaptureJournalService() }
    init(service: CaptureJournalService) { self.service = service }

    func handleScannedPages(_ pages: [UIImage]) {
        guard !pages.isEmpty else { return }
        flowState    = .processing(pages)
        isProcessing = true

        Task {
            do {
                let rawText     = try await service.recognizeText(from: pages)
                let cleanedText = await GeminiCleaningService.shared.clean(rawText)
                flowState    = .animating(pages[0], cleanedText)
                isProcessing = false
                isAnimating  = true
            } catch {
                flowState    = .error(error.localizedDescription)
                isProcessing = false
            }
        }
    }

    func save(image: UIImage, text: String, mood: Mood,
              title: String, tags: [String], into journalVM: JournalViewModel) {
        do {
            let entry = try service.buildEntry(image: image, text: text,
                                               mood: mood, title: title, tags: tags)
            journalVM.addEntry(entry)
            reset()
        } catch {
            flowState = .error(error.localizedDescription)
        }
    }

    func reset() {
        flowState    = .idle
        isProcessing = false
        isAnimating  = false
        isReviewing  = false
    }
}
