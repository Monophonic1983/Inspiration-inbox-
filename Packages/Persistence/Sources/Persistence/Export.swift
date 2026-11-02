import Foundation

/// FR-12: Markdown and plain-text export.
public enum ThoughtExporter {
    @MainActor
    public static func markdown(_ t: Thought) -> String {
        var out = "# \(t.title ?? firstLine(t.rawTranscript))\n\n"
        var meta: [String] = []
        if let kind = t.kind { meta.append("*\(kind.rawValue)*") }
        if !t.tags.isEmpty { meta.append(t.tags.map { "#\($0)" }.joined(separator: " ")) }
        meta.append(ISO8601DateFormatter().string(from: t.createdAt))
        out += meta.joined(separator: " · ") + "\n\n"
        if let s = t.summary, !s.isEmpty { out += "> \(s)\n\n" }
        out += (t.cleanedText ?? t.rawTranscript) + "\n"
        if !t.actionItems.isEmpty {
            out += "\n## Action items\n\n"
            out += t.actionItems.map { "- [\($0.isDone ? "x" : " ")] \($0.text)" }.joined(separator: "\n") + "\n"
        }
        return out
    }

    @MainActor
    public static func plainText(_ t: Thought) -> String {
        var out = (t.title ?? firstLine(t.rawTranscript)) + "\n\n" + (t.cleanedText ?? t.rawTranscript)
        if !t.actionItems.isEmpty {
            out += "\n\n" + t.actionItems.map { "\($0.isDone ? "[x]" : "[ ]") \($0.text)" }.joined(separator: "\n")
        }
        return out + "\n"
    }

    public static func firstLine(_ s: String) -> String {
        s.split(whereSeparator: \.isNewline).first.map(String.init) ?? s
    }
}
