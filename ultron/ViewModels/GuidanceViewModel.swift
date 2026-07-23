import Foundation
import Combine

@MainActor
final class GuidanceViewModel: ObservableObject {
    @Published var guidance: Guidance?
    @Published var isLoading = false

    func requestGuidance() async {
        isLoading = true
        guidance = nil

        // Simulate generation delay. Replace this block with real Gemini call:
        // let result = try await GeminiService.shared.generateGuidance(context: journalContext)
        try? await Task.sleep(nanoseconds: 1_600_000_000)

        guidance = Guidance.samples.randomElement()
        isLoading = false
    }

    func reset() {
        guidance = nil
        isLoading = false
    }
}
