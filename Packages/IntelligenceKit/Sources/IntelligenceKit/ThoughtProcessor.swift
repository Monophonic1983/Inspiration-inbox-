import Foundation
import Persistence

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

    public var fields: ProcessedFields {
        ProcessedFields(title: title, cleanedText: cleanedText, summary: summary, kind: ThoughtKind(rawValue: kind),
                        tags: tags, actionItems: actionItems)
    }
}

public enum ThoughtProcessorError: Error, Sendable, Equatable {
    case modelUnavailable, invalidOutput, consentRequired, network(String)
}

/// On-device (default), Apple Foundation Models (baseline), cloud via proxy (opt-in).
public protocol ThoughtProcessor: Sendable {
    /// Identifies prompt + model; stored in `Thought.processorVersion`.
    var version: String { get }
    func structure(transcript: String, script: ChineseScript) async throws -> StructuredThought
}

public enum SchemaValidator {
    private static let kinds: Set<String> = ["idea", "task", "question", "reminder", "quote", "journal"]

    /// Invalid output must fall back to raw text and never block saving.
    public static func decode(_ data: Data) throws -> StructuredThought {
        guard var value = try? JSONDecoder().decode(StructuredThought.self, from: data),
              !value.title.trimmingCharacters(in: .whitespaces).isEmpty,
              !value.cleanedText.trimmingCharacters(in: .whitespaces).isEmpty,
              kinds.contains(value.kind)
        else { throw ThoughtProcessorError.invalidOutput }
        value.tags = Array(value.tags.prefix(3))
        return value
    }

    /// Accepts model text that may include a think block, code fences or chatter around the JSON.
    public static func decode(modelText: String) throws -> StructuredThought {
        guard let json = JSONExtractor.extract(from: modelText) else { throw ThoughtProcessorError.invalidOutput }
        return try decode(Data(json.utf8))
    }
}

public enum JSONExtractor {
    public static func extract(from text: String) -> String? {
        var s = text
        // Drop a closed or unclosed think block (Qwen3.5 writes reasoning unless thinking is disabled).
        if let end = s.range(of: "</think>") { s = String(s[end.upperBound...]) }
        else if s.contains("<think>") { return nil }
        guard let start = s.firstIndex(of: "{") else { return nil }
        var depth = 0, inString = false, escaped = false
        var i = start
        while i < s.endIndex {
            let c = s[i]
            if inString {
                if escaped { escaped = false } else if c == "\\" { escaped = true } else if c == "\"" { inString = false }
            } else if c == "\"" { inString = true }
            else if c == "{" { depth += 1 }
            else if c == "}" { depth -= 1; if depth == 0 { return String(s[start...i]) } }
            i = s.index(after: i)
        }
        return nil
    }
}
