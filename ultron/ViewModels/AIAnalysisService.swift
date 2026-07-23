import Foundation

/// Contract for the AI direction analysis pipeline.
///
/// Accepts a journal entry + the user's North Star, returns a DirectionAnalysis.
/// Replace MockAIAnalysisService.analyze() with a real Gemini call when ready.
///
/// Gemini prompt template (Step 4):
///   North Star: \(northStar ?? "not set")
///   Journal:    \(entry.text)
///   Analyze alignment and return JSON matching DirectionAnalysis fields.
///
/// SECURITY: Never hardcode the API key. Load it from Config.plist or Keychain only.
protocol AIAnalysisProvider {
    func analyze(entry: JournalEntry, northStar: String?) async -> DirectionAnalysis
}

final class MockAIAnalysisService: AIAnalysisProvider {
    static let shared = MockAIAnalysisService()
    private init() {}

    func analyze(entry: JournalEntry, northStar: String?) async -> DirectionAnalysis {
        try? await Task.sleep(for: .seconds(1.2))
        let score     = mockScore(text: entry.text)
        let direction = direction(for: score)
        // Only offer clarification for non-distressed entries with enough content
        let suggestion = score >= 40 ? mockClarification(for: entry) : nil
        return DirectionAnalysis(
            entryID:                 entry.id,
            date:                    entry.date,
            direction:               direction,
            alignmentScore:          score,
            reason:                  mockReason(for: direction),
            coachRecommendation:     mockCoach(for: direction),
            summary:                 mockSummary(),
            themes:                  mockThemes(),
            clarificationSuggestion: suggestion
        )
    }

    private func mockClarification(for entry: JournalEntry) -> ClarificationSuggestion? {
        let wordCount = entry.text.split(separator: " ").count
        guard wordCount > 20, Bool.random() else { return nil }

        // Prefer a sentence after the first — usually more expressive
        let sentences = entry.text
            .components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.split(separator: " ").count >= 6 }
        guard let pick = sentences.dropFirst().first ?? sentences.first else { return nil }

        let original  = pick.hasSuffix(".") ? pick : pick + "."
        let prepend   = ["Looking back on this, ",
                         "What I really meant was: ",
                         "In my own words: "].randomElement()!
        let suggested = prepend + original.prefix(1).lowercased() + original.dropFirst()
        guard suggested != original else { return nil }

        let explanation = ["I think this thought can be expressed a little more completely.",
                           "This might feel a little more natural as a full reflection.",
                           "I noticed this could come through a bit more clearly."].randomElement()!
        return ClarificationSuggestion(
            originalSentence:  original,
            suggestedSentence: suggested,
            explanation:       explanation
        )
    }

    private func mockScore(text: String) -> Int {
        let words = text.split(separator: " ").count
        var base  = 50
        if words > 100 { base += 15 } else if words > 50 { base += 8 } else if words < 20 { base -= 10 }
        base += Int.random(in: -15...15)
        return min(100, max(0, base))
    }

    private func direction(for score: Int) -> Direction {
        if score >= 65 { return .toward }
        if score >= 40 { return .neutral }
        return .away
    }

    private func mockReason(for direction: Direction) -> String {
        switch direction {
        case .toward:
            return ["Today's reflection shows clear alignment. Your mindset is building momentum.",
                    "Your entry demonstrates focused effort toward growth.",
                    "The themes in today's journal strongly support your long-term direction."].randomElement()!
        case .neutral:
            return ["A steady day — neither advancing nor retreating from your path.",
                    "Your entry shows maintenance of current state. One intentional step forward tomorrow.",
                    "Today was balanced. Identify one action to accelerate tomorrow."].randomElement()!
        case .away:
            return ["Today's patterns suggest some drift from your North Star. Awareness is the first step.",
                    "Your reflection reveals some distance from your goal. Tomorrow is a reset opportunity.",
                    "Today challenged your direction. Reflect on what pulled you off course."].randomElement()!
        }
    }

    private func mockCoach(for direction: Direction) -> String {
        switch direction {
        case .toward:
            return ["Double down on the specific action from today that felt most aligned.",
                    "Share one insight from today's progress with someone who can hold you accountable.",
                    "Schedule 30 minutes tomorrow to deepen the work you started today."].randomElement()!
        case .neutral:
            return ["Choose one small concrete action tomorrow that directly serves your North Star.",
                    "Write down one specific commitment for tomorrow morning before you sleep.",
                    "Identify the one thing that would make tomorrow a 'toward' day — and do it first."].randomElement()!
        case .away:
            return ["Start tomorrow with a 5-minute review of your North Star. Realign before the day begins.",
                    "Identify the specific trigger that pulled you off course today.",
                    "Choose the single most important thing that would move you toward your goal tomorrow."].randomElement()!
        }
    }

    private func mockSummary() -> String {
        ["A reflective entry exploring themes of growth and intentionality.",
         "Today's journal captures a moment of honest self-assessment.",
         "A thoughtful reflection on the day's experiences and learnings.",
         "An entry that reveals the user's current mental and emotional state."].randomElement()!
    }

    private func mockThemes() -> [String] {
        [["growth", "intentionality", "focus"],
         ["consistency", "self-awareness", "progress"],
         ["challenge", "resilience", "learning"],
         ["clarity", "purpose", "momentum"]].randomElement()!
    }
}
