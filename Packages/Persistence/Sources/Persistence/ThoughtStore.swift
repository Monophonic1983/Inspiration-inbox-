import Foundation
import SwiftData

/// Fields produced by a processor, already validated. Kept in Persistence so processors stay decoupled from storage.
public struct ProcessedFields: Sendable, Equatable {
    public var title: String
    public var cleanedText: String
    public var summary: String
    public var kind: ThoughtKind?
    public var tags: [String]
    public var actionItems: [String]
    public init(title: String, cleanedText: String, summary: String, kind: ThoughtKind?, tags: [String], actionItems: [String]) {
        self.title = title; self.cleanedText = cleanedText; self.summary = summary
        self.kind = kind; self.tags = tags; self.actionItems = actionItems
    }
}

@MainActor
public final class ThoughtStore {
    public let container: ModelContainer
    public var context: ModelContext { container.mainContext }

    public init(container: ModelContainer) { self.container = container }

    /// `cloudKitContainer` nil keeps the store local. CloudKit needs optional/defaulted properties and no unique constraints (see Thought).
    public static func makeContainer(inMemory: Bool = false, cloudKitContainer: String? = nil) throws -> ModelContainer {
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else if let id = cloudKitContainer {
            config = ModelConfiguration(cloudKitDatabase: .private(id))
        } else {
            config = ModelConfiguration(cloudKitDatabase: .none)
        }
        return try ModelContainer(for: Thought.self, configurations: config)
    }

    // MARK: Capture (FR-4, FR-5)

    /// Saves the raw thought before any AI step runs. Synchronous so it lands within the 300 ms budget.
    @discardableResult
    public func saveRaw(transcript: String, audioFileName: String?) throws -> Thought {
        let thought = Thought(rawTranscript: transcript, audioFileName: audioFileName)
        context.insert(thought)
        try context.save()
        return thought
    }

    // MARK: Processing results (FR-8)

    /// Applies processor output. User-edited text is kept unless `overwriteUserEdits` is true.
    public func apply(_ fields: ProcessedFields, processorVersion: String, to thought: Thought, overwriteUserEdits: Bool = false) throws {
        let keepEdits = thought.userEditedAt != nil && !overwriteUserEdits
        if !keepEdits {
            thought.title = fields.title
            thought.cleanedText = fields.cleanedText
            thought.userEditedAt = nil
        }
        thought.summary = fields.summary
        thought.kind = fields.kind
        thought.tags = Array(fields.tags.prefix(3))
        thought.actionItems = fields.actionItems.map { ActionItem(text: $0) }
        thought.processorVersion = processorVersion
        thought.status = .ready
        thought.failureCount = 0
        thought.updatedAt = Date()
        try context.save()
    }

    public func markFailed(_ thought: Thought) throws {
        thought.status = .failed
        thought.failureCount += 1
        thought.updatedAt = Date()
        try context.save()
    }

    // MARK: Edits (FR-7)

    public func edit(_ thought: Thought, title: String? = nil, cleanedText: String? = nil) throws {
        if let title { thought.title = title }
        if let cleanedText { thought.cleanedText = cleanedText }
        thought.userEditedAt = Date()
        thought.updatedAt = Date()
        try context.save()
    }

    public func toggle(actionItemAt index: Int, of thought: Thought) throws {
        guard thought.actionItems.indices.contains(index) else { return }
        var items = thought.actionItems
        items[index].isDone.toggle()
        thought.actionItems = items
        thought.updatedAt = Date()
        try context.save()
    }

    // MARK: Triage (FR-9)

    public func setPinned(_ pinned: Bool, _ thought: Thought) throws {
        thought.isPinned = pinned; thought.updatedAt = Date(); try context.save()
    }

    public func setArchived(_ archived: Bool, _ thought: Thought) throws {
        thought.archivedAt = archived ? Date() : nil; thought.updatedAt = Date(); try context.save()
    }

    /// Hard delete: only on an explicit user delete.
    public func delete(_ thought: Thought, audio: AudioFileStore? = nil) throws {
        if let name = thought.audioFileName { audio?.delete(name) }
        context.delete(thought)
        try context.save()
    }

    /// Re-inserts a deleted thought's content (undo).
    @discardableResult
    public func restore(_ snapshot: ThoughtSnapshot) throws -> Thought {
        let t = snapshot.makeThought()
        context.insert(t)
        try context.save()
        return t
    }

    // MARK: Queries

    public func all(includeArchived: Bool = false) throws -> [Thought] {
        let all = try context.fetch(FetchDescriptor<Thought>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))
        return includeArchived ? all : all.filter { $0.archivedAt == nil }
    }

    public func pendingProcessing() throws -> [Thought] {
        try all(includeArchived: true).filter { $0.status == .captured }
    }

    /// FR-10: substring match over raw and cleaned text. Substring (not token) matching finds Chinese written without spaces;
    /// both sides fold case/width and map to Simplified so a Traditional query finds Simplified text and vice versa.
    public func search(_ query: String) throws -> [Thought] {
        let q = SearchNormalizer.normalize(query)
        guard !q.isEmpty else { return try all() }
        return try all().filter { t in
            SearchNormalizer.normalize(t.rawTranscript).contains(q)
                || SearchNormalizer.normalize(t.cleanedText ?? "").contains(q)
                || SearchNormalizer.normalize(t.title ?? "").contains(q)
        }
    }
}

public enum SearchNormalizer {
    public static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
        return ScriptConverter.convert(folded, to: .simplified)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Value copy of a thought, used for undoing a delete.
public struct ThoughtSnapshot: Sendable {
    let id: UUID, createdAt: Date, raw: String, audio: String?, status: ThoughtStatus, title: String?, cleaned: String?
    let summary: String?, kind: ThoughtKind?, tags: [String], items: [ActionItem], pinned: Bool, archivedAt: Date?, version: String?, edited: Date?

    @MainActor public init(_ t: Thought) {
        id = t.id; createdAt = t.createdAt; raw = t.rawTranscript; audio = t.audioFileName; status = t.status
        title = t.title; cleaned = t.cleanedText; summary = t.summary; kind = t.kind; tags = t.tags
        items = t.actionItems; pinned = t.isPinned; archivedAt = t.archivedAt; version = t.processorVersion; edited = t.userEditedAt
    }

    @MainActor func makeThought() -> Thought {
        let t = Thought(rawTranscript: raw, audioFileName: audio)
        t.id = id; t.createdAt = createdAt; t.status = status; t.title = title; t.cleanedText = cleaned
        t.summary = summary; t.kind = kind; t.tags = tags; t.actionItems = items; t.isPinned = pinned
        t.archivedAt = archivedAt; t.processorVersion = version; t.userEditedAt = edited
        return t
    }
}
