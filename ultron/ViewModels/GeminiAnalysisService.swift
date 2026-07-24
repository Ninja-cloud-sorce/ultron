import Foundation

/// Production AI analysis using Gemini 2.0 Flash.
/// API key is read from Config.plist at runtime — never hardcoded.
final class GeminiAnalysisService: AIAnalysisProvider {

    static let shared = GeminiAnalysisService()
    private let fallback = MockAIAnalysisService.shared

    private let apiKey: String?
    private let session: URLSession

    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    private init() {
        // Graceful degradation — if key is missing, analyze() falls back to mock.
        if let url    = Bundle.main.url(forResource: "Config", withExtension: "plist"),
           let config = NSDictionary(contentsOf: url) as? [String: Any],
           let key    = config["GEMINI_API_KEY"] as? String, !key.isEmpty {
            self.apiKey = key
        } else {
            self.apiKey = nil
        }

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: cfg)
    }

    // MARK: - AIAnalysisProvider

    func analyze(entry: JournalEntry, northStar: String?) async -> DirectionAnalysis {
        guard apiKey != nil else {
            return await fallback.analyze(entry: entry, northStar: northStar)
        }
        do {
            return try await callGemini(entry: entry, northStar: northStar)
        } catch {
            // Network down, quota exceeded, or parse failure — degrade gracefully.
            return await fallback.analyze(entry: entry, northStar: northStar)
        }
    }

    // MARK: - Gemini REST call

    private func callGemini(entry: JournalEntry, northStar: String?) async throws -> DirectionAnalysis {
        guard let key = apiKey, let url = URL(string: endpoint) else {
            throw AnalysisError.badURL
        }

        let body: [String: Any] = [
            "contents": [["parts": [["text": buildPrompt(entry: entry, northStar: northStar)]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.4,
                "maxOutputTokens": 512
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = try JSONSerialization.data(withJSONObject: body)
        // API key in header — never appears in URL logs or crash reports.
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AnalysisError.httpError
        }

        return try parseResponse(data: data, entry: entry)
    }

    // MARK: - Prompt

    private func buildPrompt(entry: JournalEntry, northStar: String?) -> String {
        let goal = northStar?.trimmingCharacters(in: .whitespaces).isEmpty == false
            ? northStar! : "not set"

        return """
        You are a personal life coach analyzing a journal entry against the user's long-term goal.

        North Star Goal: \(goal)
        Journal Entry: \(entry.text)
        Mood: \(entry.mood.rawValue)

        Respond with ONLY valid JSON matching this exact schema. No markdown, no explanation, only JSON:
        {
          "direction": "toward" or "neutral" or "away",
          "alignmentScore": integer between 0 and 100,
          "reason": "1-2 sentence explanation of alignment score",
          "coachRecommendation": "1 specific actionable step for tomorrow",
          "summary": "1 sentence summary of the entry",
          "themes": ["theme1", "theme2", "theme3"],
          "clarification": {
            "originalSentence": "a sentence from the entry worth expanding",
            "suggestedSentence": "a more complete version of that sentence",
            "explanation": "why this expansion helps"
          }
        }

        Rules:
        - direction "toward" = score >= 65, "neutral" = 40-64, "away" = below 40
        - themes: 2-3 single words only
        - clarification: only include if the entry has a meaningful sentence worth expanding and entry is at least 20 words. Omit the clarification key entirely if not applicable.
        - coachRecommendation: start with an action verb, be specific
        """
    }

    // MARK: - Response parsing

    private func parseResponse(data: Data, entry: JournalEntry) throws -> DirectionAnalysis {
        // Gemini wraps the result in candidates[0].content.parts[0].text
        guard
            let root       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = root["candidates"]  as? [[String: Any]],
            let content    = candidates.first?["content"] as? [String: Any],
            let parts      = content["parts"]    as? [[String: Any]],
            let text       = parts.first?["text"] as? String,
            let jsonData   = text.data(using: .utf8),
            let json       = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            throw AnalysisError.parseError
        }

        let directionRaw = json["direction"]           as? String ?? "neutral"
        let direction    = Direction(rawValue: directionRaw) ?? .neutral
        // NSNumber covers both Int and Double that Gemini may return (e.g. 65 or 65.0).
        let score        = (json["alignmentScore"] as? NSNumber)?.intValue ?? 50
        let reason       = json["reason"]              as? String ?? ""
        let coach        = json["coachRecommendation"] as? String ?? ""
        let summary      = json["summary"]             as? String ?? ""
        let themes       = json["themes"]              as? [String] ?? []

        var clarification: ClarificationSuggestion? = nil
        if let c          = json["clarification"]      as? [String: Any],
           let original   = c["originalSentence"]      as? String,
           let suggested  = c["suggestedSentence"]     as? String,
           let explanation = c["explanation"]           as? String {
            clarification = ClarificationSuggestion(
                originalSentence:  original,
                suggestedSentence: suggested,
                explanation:       explanation
            )
        }

        return DirectionAnalysis(
            entryID:                 entry.id,
            date:                    entry.date,
            direction:               direction,
            alignmentScore:          min(100, max(0, score)),
            reason:                  reason,
            coachRecommendation:     coach,
            summary:                 summary,
            themes:                  themes,
            clarificationSuggestion: clarification
        )
    }

    // MARK: - Errors

    private enum AnalysisError: Error {
        case badURL, httpError, parseError
    }
}
