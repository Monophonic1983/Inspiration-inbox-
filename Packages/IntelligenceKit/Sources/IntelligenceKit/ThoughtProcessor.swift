import Foundation

/// Output schema from the PRD. Validated before it is ever applied to a Thought.
public struct StructuredThought: Codable, Equatable, Sendable {
    public var title: String
    public var cleanedText: String
    public var summary: String
    public var kind: String
    public var tags: [String]
    public var actionItems: [String]
    public var openQuestions: [String]
    public var uncertain: Bool

    enum CodingKeys: String, CodingKey {
        case title, summary, kind, tags, uncertain
        case cleanedText = "cleaned_text"
        case actionItems = "action_items"
        case openQuestions = "open_questions"
    }
}

public enum ThoughtProcessorError: Error, Sendable { case modelUnavailable, invalidOutput }

/// On-device (default), Apple Foundation Models (baseline), cloud via proxy (opt-in, Phase 4).
public protocol ThoughtProcessor: Sendable {
    /// Identifies prompt + model; stored in `Thought.processorVersion`.
    var version: String { get }
    func structure(transcript: String) async throws -> StructuredThought
}

public enum SchemaValidator {
    private static let kinds: Set<String> = ["idea", "task", "question", "reminder", "quote", "journal"]

    /// Invalid output must fall back to raw text and never block saving.
    public static func decode(_ data: Data) throws -> StructuredThought {
        guard let value = try? JSONDecoder().decode(StructuredThought.self, from: data),
              !value.title.isEmpty, kinds.contains(value.kind), value.tags.count <= 3
        else { throw ThoughtProcessorError.invalidOutput }
        return value
    }
}
