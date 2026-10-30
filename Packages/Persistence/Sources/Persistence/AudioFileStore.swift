import Foundation

/// Local-only audio storage. Audio never leaves the device and is not synced.
public struct AudioFileStore: Sendable {
    public let directory: URL

    public init(directory: URL? = nil) {
        self.directory = directory ?? FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func url(for fileName: String) -> URL { directory.appendingPathComponent(fileName) }

    public func newFileName() -> String { "\(UUID().uuidString).m4a" }

    public func delete(_ fileName: String) {
        try? FileManager.default.removeItem(at: url(for: fileName))
    }

    /// Deletes audio older than `days` (0 deletes everything). Returns the number of files removed.
    @discardableResult
    public func purge(olderThanDays days: Int, now: Date = Date()) -> Int {
        let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
        let files = (try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
        var removed = 0
        for file in files where file.pathExtension == "m4a" {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if days == 0 || modified < cutoff {
                try? FileManager.default.removeItem(at: file)
                removed += 1
            }
        }
        return removed
    }
}
