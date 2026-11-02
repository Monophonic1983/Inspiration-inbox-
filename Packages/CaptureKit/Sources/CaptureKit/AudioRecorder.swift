import Foundation
import AVFoundation

/// Microphone abstraction so UI tests can run without a real mic.
public protocol AudioSource: Sendable {
    func requestPermission() async -> Bool
    var permissionDenied: Bool { get }
    func start(fileURL: URL?, onLevel: @escaping @Sendable (Float) -> Void) throws -> AsyncStream<AudioChunk>
    func stop()
}

/// Captures microphone audio to a file and fans it out as a level meter plus a buffer stream for the transcriber.
public final class AudioRecorder: AudioSource, @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var file: AVAudioFile?
    private var continuation: AsyncStream<AudioChunk>.Continuation?
    private var levelHandler: (@Sendable (Float) -> Void)?

    public init() {}

    public func requestPermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    public var permissionDenied: Bool { AVAudioApplication.shared.recordPermission == .denied }

    /// Starts recording to `fileURL` (AAC). Returns the stream of buffers to transcribe.
    public func start(fileURL: URL?, onLevel: @escaping @Sendable (Float) -> Void) throws -> AsyncStream<AudioChunk> {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetoothHFP])
        try session.setActive(true)

        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        if let fileURL {
            file = try AVAudioFile(forWriting: fileURL, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount, AVEncoderBitRateKey: 64_000,
            ])
        }
        levelHandler = onLevel
        let (stream, continuation) = AsyncStream.makeStream(of: AudioChunk.self, bufferingPolicy: .unbounded)
        self.continuation = continuation

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            try? self.file?.write(from: buffer)
            self.levelHandler?(Self.normalisedLevel(buffer))
            // Copy: the engine reuses its buffer after the tap returns.
            if let copy = Self.copy(buffer) { self.continuation?.yield(AudioChunk(copy)) }
        }
        engine.prepare()
        try engine.start()
        return stream
    }

    public func stop() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        continuation?.finish()
        continuation = nil
        file = nil   // closes and flushes the file
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    static func normalisedLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let data = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }
        var sum: Float = 0
        for i in 0..<Int(buffer.frameLength) { sum += data[i] * data[i] }
        let rms = (sum / Float(buffer.frameLength)).squareRoot()
        let db = 20 * log10(max(rms, 0.000_01))           // -100 ... 0 dB
        return max(0, min(1, (db + 50) / 50))               // map -50 dB...0 dB to 0...1
    }

    static func copy(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let out = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameLength) else { return nil }
        out.frameLength = buffer.frameLength
        let channels = Int(buffer.format.channelCount)
        if let src = buffer.floatChannelData, let dst = out.floatChannelData {
            for c in 0..<channels { dst[c].update(from: src[c], count: Int(buffer.frameLength)) }
        } else if let src = buffer.int16ChannelData, let dst = out.int16ChannelData {
            for c in 0..<channels { dst[c].update(from: src[c], count: Int(buffer.frameLength)) }
        }
        return out
    }
}
