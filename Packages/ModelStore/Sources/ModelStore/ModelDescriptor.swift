import Foundation

public struct ModelFile: Codable, Sendable, Equatable {
    public var path: String        // relative path inside the model folder
    public var url: URL
    public var sha256: String
    public var sizeBytes: Int64
    public init(path: String, url: URL, sha256: String, sizeBytes: Int64) {
        self.path = path; self.url = url; self.sha256 = sha256; self.sizeBytes = sizeBytes
    }
}

public enum ModelRole: String, Codable, Sendable { case structuring, accuracyPass }

/// Model names and files live in a remote config so they can change without an app release (PRD).
public struct ModelDescriptor: Codable, Sendable, Equatable, Identifiable {
    public var id: String
    public var displayName: String
    public var role: ModelRole
    public var license: String
    public var minRAMGB: Int
    public var files: [ModelFile]
    public var totalBytes: Int64 { files.reduce(0) { $0 + $1.sizeBytes } }
    public init(id: String, displayName: String, role: ModelRole, license: String, minRAMGB: Int, files: [ModelFile]) {
        self.id = id; self.displayName = displayName; self.role = role; self.license = license; self.minRAMGB = minRAMGB; self.files = files
    }
}

public struct ModelCatalog: Codable, Sendable, Equatable {
    public var version: Int
    public var models: [ModelDescriptor]
    public init(version: Int, models: [ModelDescriptor]) { self.version = version; self.models = models }

    /// Largest structuring model that fits the device. Nil means: use Apple Foundation Models or save raw only.
    public func structuringModel(forRAMGB gb: Int) -> ModelDescriptor? {
        models.filter { $0.role == .structuring && $0.minRAMGB <= gb && !$0.files.isEmpty }
            .max { $0.minRAMGB < $1.minRAMGB }
    }
}

public enum ModelTier: Sendable {
    case foundationModelsOrRawOnly, small2B, large4B
    /// RAM tiers are approximate; confirm in the Phase 0 bake-off.
    public static func forPhysicalRAMGB(_ gb: Int) -> ModelTier {
        gb >= 8 ? .large4B : gb >= 6 ? .small2B : .foundationModelsOrRawOnly
    }
}

public enum DeviceCapabilities {
    public static var physicalRAMGB: Int {
        Int((Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824).rounded())
    }
}
