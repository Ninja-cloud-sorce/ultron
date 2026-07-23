import Foundation

/// Future-ready protocol for semantic memory and vector search.
///
/// Swap PlaceholderEmbeddingService for a real implementation at any time
/// without changing call sites. Intended integrations:
///   - GeminiEmbeddingService  (text-embedding-004 via Gemini API)
///   - SupabaseVectorService   (pgvector backend)
///   - PineconeEmbeddingService
///
/// Typical future flow: query → embed() → vector search → relevant journals → LLM → coaching
protocol EmbeddingProvider {
    func embed(_ text: String) async -> [Float]
    func store(embedding: [Float], forEntryID id: UUID) async
}

/// No-op placeholder — swap for a real EmbeddingProvider without changing any call sites.
final class PlaceholderEmbeddingService: EmbeddingProvider {
    static let shared = PlaceholderEmbeddingService()
    private init() {}

    func embed(_ text: String) async -> [Float] { [] }
    func store(embedding: [Float], forEntryID id: UUID) async {}
}
