import Foundation
import Observation

public enum ModelState: Equatable, Sendable {
    case notInstalled
    case downloading(progress: Double)
    case installed
    case failed(String)
}

public enum ModelStoreError: Error, Equatable { case checksumMismatch(String), noFiles }

/// Downloads models after install (never bundled), verifies checksums, resumes interrupted downloads and deletes on request.
/// Capture never waits on this type.
@MainActor @Observable
public final class ModelStore {
    public private(set) var states: [String: ModelState] = [:]
    public var wifiOnly: Bool = true
    public let root: URL
    private var tasks: [String: Task<Void, Never>] = [:]

    public init(root: URL? = nil) {
        self.root = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: self.root, withIntermediateDirectories: true)
    }

    public func directory(for id: String) -> URL { root.appendingPathComponent(id, isDirectory: true) }
    private func marker(for id: String) -> URL { directory(for: id).appendingPathComponent(".installed") }

    public func refresh(_ catalog: ModelCatalog) {
        for m in catalog.models where states[m.id] == nil || states[m.id] == .notInstalled {
            states[m.id] = FileManager.default.fileExists(atPath: marker(for: m.id).path) ? .installed : .notInstalled
        }
    }

    public func installedDirectory(for id: String) -> URL? {
        FileManager.default.fileExists(atPath: marker(for: id).path) ? directory(for: id) : nil
    }

    public func download(_ model: ModelDescriptor) {
        guard tasks[model.id] == nil, !model.files.isEmpty else {
            if model.files.isEmpty { states[model.id] = .failed("Model files are not configured yet.") }
            return
        }
        states[model.id] = .downloading(progress: 0)
        let wifi = wifiOnly
        tasks[model.id] = Task { [weak self] in
            do {
                try await self?.run(model, wifiOnly: wifi)
                self?.states[model.id] = .installed
            } catch is CancellationError {
                self?.states[model.id] = .notInstalled
            } catch {
                self?.states[model.id] = .failed(String(describing: error))
            }
            self?.tasks[model.id] = nil
        }
    }

    public func cancel(_ id: String) { tasks[id]?.cancel() }

    public func delete(_ id: String) {
        cancel(id)
        try? FileManager.default.removeItem(at: directory(for: id))
        states[id] = .notInstalled
    }

    private func run(_ model: ModelDescriptor, wifiOnly: Bool) async throws {
        let dir = directory(for: model.id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let total = max(model.totalBytes, 1)
        var done: Int64 = 0
        for file in model.files {
            let dest = dir.appendingPathComponent(file.path)
            if let existing = try? Checksum.sha256Hex(of: dest), existing == file.sha256 {   // already verified: skip
                done += file.sizeBytes; continue
            }
            try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
            let resume = dir.appendingPathComponent(file.path + ".resume")
            let downloader = FileDownloader(resumeDataURL: resume, wifiOnly: wifiOnly)
            let base = done
            let tmp = try await downloader.download(from: file.url) { [weak self] written in
                Task { @MainActor in self?.states[model.id] = .downloading(progress: min(Double(base + written) / Double(total), 1)) }
            }
            let hash = try Checksum.sha256Hex(of: tmp)
            guard hash == file.sha256 else {
                try? FileManager.default.removeItem(at: tmp)
                throw ModelStoreError.checksumMismatch(file.path)
            }
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: tmp, to: dest)
            done += file.sizeBytes
        }
        FileManager.default.createFile(atPath: marker(for: model.id).path, contents: Data())
    }
}
