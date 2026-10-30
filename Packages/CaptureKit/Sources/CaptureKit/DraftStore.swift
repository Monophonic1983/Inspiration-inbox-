import Foundation
import Persistence

/// Writes the in-progress transcript to disk as the user speaks, so a force-quit or crash mid-capture
/// never loses a thought (FR-4). Drafts are recovered into real thoughts on next launch.
public struct DraftStore: Sendable {
    public struct Draft: Codable, Sendable, Equatable {
        public var id: UUID
        public var transcript: String
        public var audioFileName: String?
        public var updatedAt: Date
    }

    public let directory: URL

    public init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Drafts", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    private func url(_ id: UUID) -> URL { directory.appendingPathComponent("\(id.uuidString).json") }

    public func write(_ draft: Draft) {
        guard let data = try? JSONEncoder().encode(draft) else { return }
        try? data.write(to: url(draft.id), options: .atomic)
    }

    public func remove(_ id: UUID) { try? FileManager.default.removeItem(at: url(id)) }

    public func pending() -> [Draft] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "json" }
            .compactMap { try? Data(contentsOf: $0) }
            .compactMap { try? JSONDecoder().decode(Draft.self, from: $0) }
            .sorted { $0.updatedAt < $1.updatedAt }
    }

    /// Turns leftover drafts into saved thoughts. A draft with audio but no words still becomes a thought
    /// (empty transcript) so the audio can be re-transcribed by the accuracy pass.
    @MainActor
    @discardableResult
    public func recover(into store: ThoughtStore) -> [Thought] {
        var recovered: [Thought] = []
        for d in pending() {
            guard !d.transcript.isEmpty || d.audioFileName != nil else { remove(d.id); continue }
            if let t = try? store.saveRaw(transcript: d.transcript, audioFileName: d.audioFileName) {
                recovered.append(t); remove(d.id)
            }
        }
        return recovered
    }
}
