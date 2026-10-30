import Foundation
import AVFoundation

public struct TranscriptUpdate: Sendable, Equatable {
    public var text: String
    public var isFinal: Bool
    public init(text: String, isFinal: Bool) { self.text = text; self.isFinal = isFinal }
}

/// Wraps a buffer so it can cross concurrency domains; buffers are never mutated after being handed over.
public struct AudioChunk: @unchecked Sendable {
    public let buffer: AVAudioPCMBuffer
    public init(_ buffer: AVAudioPCMBuffer) { self.buffer = buffer }
}

/// Streaming speech to text. Implementations must work offline (FR-2).
public protocol LiveTranscriber: Sendable {
    /// Consumes audio until `audio` finishes and yields partial then final text.
    func transcribe(audio: AsyncStream<AudioChunk>, locale: Locale) -> AsyncThrowingStream<TranscriptUpdate, Error>
}
