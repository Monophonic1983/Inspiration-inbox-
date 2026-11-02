import Foundation

public enum StopReason: Sendable { case tap, holdRelease, silence }

public struct CaptureConfig: Sendable {
    /// FR-3: default 2.5 s, configurable.
    public var autoStopSilence: TimeInterval = 2.5
    /// A pause this long (but shorter than auto-stop) earns a light haptic tap.
    public var longPause: TimeInterval = 1.0
    /// Normalised level (0...1) below which input counts as silence.
    public var silenceThreshold: Float = 0.04
    public init(autoStopSilence: TimeInterval = 2.5) { self.autoStopSilence = autoStopSilence }
    public init(autoStopSeconds: Double) { self.autoStopSilence = autoStopSeconds }
}

public enum SilenceEvent: Equatable, Sendable { case longPause, autoStop }

/// Pure logic, fed one level reading at a time. Auto-stop only arms after the user has spoken, so a
/// slow start never ends the capture before it begins.
public struct SilenceDetector: Sendable {
    private let config: CaptureConfig
    private var silenceStart: TimeInterval?
    private var hasSpoken = false
    private var firedPause = false

    public init(config: CaptureConfig) { self.config = config }

    public mutating func feed(level: Float, at time: TimeInterval) -> SilenceEvent? {
        if level >= config.silenceThreshold {
            hasSpoken = true; silenceStart = nil; firedPause = false
            return nil
        }
        guard hasSpoken else { return nil }
        let start = silenceStart ?? time
        silenceStart = start
        let quiet = time - start
        if quiet >= config.autoStopSilence { return .autoStop }
        if quiet >= config.longPause, !firedPause { firedPause = true; return .longPause }
        return nil
    }
}
