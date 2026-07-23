import Foundation

struct ClarificationSuggestion: Codable {
    let originalSentence: String
    let suggestedSentence: String
    let explanation: String
}
