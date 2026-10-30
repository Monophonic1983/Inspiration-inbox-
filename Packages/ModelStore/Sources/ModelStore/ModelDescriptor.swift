import Foundation

/// Model names live in a remote config so they can change without an app release (PRD).
public struct ModelDescriptor: Codable, Sendable, Equatable {
    public var id: String
    public var url: URL
    public var sha256: String
    public var sizeBytes: Int64
    public var minRAMGB: Int
    public init(id: String, url: URL, sha256: String, sizeBytes: Int64, minRAMGB: Int) {
        self.id = id; self.url = url; self.sha256 = sha256; self.sizeBytes = sizeBytes; self.minRAMGB = minRAMGB
    }
}

public enum ModelTier: Sendable {
    case foundationModelsOrRawOnly, small2B, large4B
    /// RAM tiers are approximate; confirmed in the Phase 0 bake-off.
    public static func forPhysicalRAMGB(_ gb: Int) -> ModelTier {
        gb >= 8 ? .large4B : gb >= 6 ? .small2B : .foundationModelsOrRawOnly
    }
}
