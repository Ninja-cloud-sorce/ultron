import Foundation

/// Cleans raw OCR text using Gemini: fixes recognition errors, restores punctuation,
/// preserves the author's wording. NEVER summarises or rewrites content.
/// Falls back to the raw text on any error so the capture flow never stalls.
final class GeminiCleaningService {

    static let shared = GeminiCleaningService()

    private let apiKey: String?
    private let session: URLSession
    private let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    private init() {
        if let url    = Bundle.main.url(forResource: "Config", withExtension: "plist"),
           let config = NSDictionary(contentsOf: url) as? [String: Any],
           let key    = config["GEMINI_API_KEY"] as? String, !key.isEmpty {
            self.apiKey = key
        } else {
            self.apiKey = nil
        }
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 20
        cfg.timeoutIntervalForResource = 40
        self.session = URLSession(configuration: cfg)
    }

    /// Returns cleaned text. On any failure returns `rawText` unchanged.
    func clean(_ rawText: String) async -> String {
        guard let key = apiKey, !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return rawText
        }
        do {
            return try await callGemini(text: rawText, key: key)
        } catch {
            return rawText
        }
    }

    // MARK: - Private

    private func callGemini(text: String, key: String) async throws -> String {
        guard let url = URL(string: endpoint) else { return text }

        let prompt = """
        You are a precise OCR correction assistant. The text below was extracted by an OCR scanner \
        from a handwritten journal page and may contain recognition errors, missing punctuation, \
        and broken paragraph structure.

        Your task:
        1. Fix OCR recognition mistakes (wrong letters, merged/split words).
        2. Restore natural punctuation and paragraph breaks.
        3. Preserve the author's exact vocabulary, tone, and sentence structure.
        4. Do NOT summarise, shorten, expand, or rephrase any content.
        5. Return ONLY the corrected text — no preamble, no explanation, no markdown.

        OCR text:
        \(text)
        """

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody   = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return text
        }

        guard
            let root       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let candidates = root["candidates"]  as? [[String: Any]],
            let content    = candidates.first?["content"] as? [String: Any],
            let parts      = content["parts"]    as? [[String: Any]],
            let cleaned    = parts.first?["text"] as? String
        else { return text }

        let trimmed = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? text : trimmed
    }
}
