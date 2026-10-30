import Foundation

public enum StopReason: Sendable { case tap, holdRelease, silence }

public struct CaptureConfig: Sendable {
    /// FR-3: default 2.5 s, configurable.
    public var autoStopSilence: TimeInterval = 2.5
    public init() {}
}
