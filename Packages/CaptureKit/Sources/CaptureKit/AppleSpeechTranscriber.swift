import Foundation
import AVFoundation
#if canImport(Speech)
import Speech

/// Apple SpeechAnalyzer (iOS 26): streaming, free, no model download by us.
/// The exact API surface must be confirmed against the iOS 26 SDK in the Phase 0 spike; this follows the documented
/// SpeechAnalyzer / SpeechTranscriber / AnalyzerInput shape.
@available(iOS 26.0, *)
public struct AppleSpeechTranscriber: LiveTranscriber {
    public init() {}

    public func transcribe(audio: AsyncStream<AudioChunk>, locale: Locale) -> AsyncThrowingStream<TranscriptUpdate, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let transcriber = SpeechTranscriber(locale: locale, transcriptionOptions: [],
                                                        reportingOptions: [.volatileResults], attributeOptions: [])
                    // Make sure the on-device assets for this locale exist (a one-time system download, not ours).
                    if let installRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                        try await installRequest.downloadAndInstall()
                    }
                    let analyzer = SpeechAnalyzer(modules: [transcriber])
                    let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
                    let (inputs, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)
                    try await analyzer.start(inputSequence: inputs)

                    let feeder = Task {
                        var converter: AVAudioConverter?
                        for await chunk in audio {
                            let buffer = chunk.buffer
                            guard let format else { inputBuilder.yield(AnalyzerInput(buffer: buffer)); continue }
                            if buffer.format == format { inputBuilder.yield(AnalyzerInput(buffer: buffer)); continue }
                            if converter == nil { converter = AVAudioConverter(from: buffer.format, to: format) }
                            guard let converter,
                                  let out = AVAudioPCMBuffer(pcmFormat: format,
                                                             frameCapacity: AVAudioFrameCount(Double(buffer.frameLength) * format.sampleRate / buffer.format.sampleRate) + 1)
                            else { continue }
                            var consumed = false
                            var error: NSError?
                            converter.convert(to: out, error: &error) { _, status in
                                if consumed { status.pointee = .noDataNow; return nil }
                                consumed = true; status.pointee = .haveData; return buffer
                            }
                            if error == nil { inputBuilder.yield(AnalyzerInput(buffer: out)) }
                        }
                        inputBuilder.finish()
                        try? await analyzer.finalizeAndFinishThroughEndOfInput()
                    }

                    for try await result in transcriber.results {
                        continuation.yield(TranscriptUpdate(text: String(result.text.characters), isFinal: result.isFinal))
                    }
                    feeder.cancel()
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
#endif
