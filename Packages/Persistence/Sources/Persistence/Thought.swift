import Foundation
import SwiftData

public enum ThoughtStatus: String, Codable, Sendable { case captured, ready, failed }
public enum ThoughtKind: String, Codable, Sendable { case idea, task, question, reminder, quote, journal }

public struct ActionItem: Codable, Hashable, Sendable {
    public var text: String
    public var isDone: Bool
    public init(text: String, isDone: Bool = false) { self.text = text; self.isDone = isDone }
}

/// One entity holds everything. CloudKit-compatible: every property defaulted or optional, no unique constraints.
@Model
public final class Thought {
    public var id: UUID = UUID()
    public var createdAt: Date = Date()
    public var updatedAt: Date = Date()
    /// Immutable after save (FR-4).
    public var rawTranscript: String = ""
    /// Local only; deleted after 30 days by default.
    public var audioFileName: String?
    public var status: ThoughtStatus = ThoughtStatus.captured
    public var title: String?
    /// User edits land here.
    public var cleanedText: String?
    public var summary: String?
    public var kind: ThoughtKind?
    /// Up to 3.
    public var tags: [String] = []
    public var actionItems: [ActionItem] = []
    public var isPinned: Bool = false
    /// Archive, never hard-delete, until the user deletes.
    public var archivedAt: Date?
    /// Prompt and model that produced the result, so results can be re-run.
    public var processorVersion: String?
    /// Set when the user edits title or cleaned text; re-processing then asks before overwriting.
    public var userEditedAt: Date?
    /// Consecutive failed processing attempts (diagnostics only).
    public var failureCount: Int = 0

    public init(rawTranscript: String, audioFileName: String? = nil) {
        self.rawTranscript = rawTranscript
        self.audioFileName = audioFileName
    }
}
