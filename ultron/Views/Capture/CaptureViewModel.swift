import SwiftUI
import Combine
import UIKit

/// State machine for the document-capture → OCR → review → save flow.
@MainActor
final class CaptureViewModel: ObservableObject {

    enum FlowState {
        case idle
        case processing([UIImage])
        case reviewing(UIImage, String)
        case error(String)
    }

    @Published private(set) var flowState: FlowState = .idle
    @Published var isProcessing = false
    @Published var isReviewing  = false

    private let service: CaptureJournalService

    // A default-parameter value is evaluated in a nonisolated context, which
    // conflicts with @MainActor. Creating the service in the init body instead
    // keeps everything on the main actor and silences the isolation warning.
    init() { self.service = CaptureJournalService() }

    init(service: CaptureJournalService) { self.service = service }

    func handleScannedPages(_ pages: [UIImage]) {
        guard !pages.isEmpty else { return }
        flowState    = .processing(pages)
        isProcessing = true

        Task {
            do {
                let text = try await service.recognizeText(from: pages)
                flowState    = .reviewing(pages[0], text)
                isProcessing = false
                isReviewing  = true
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
        isReviewing  = false
    }
}
