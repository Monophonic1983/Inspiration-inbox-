import Foundation
import AVFoundation
import CaptureKit

/// Used only with the `-uitest` launch argument so the capture-flow XCUITest needs no microphone or speech assets.
struct FakeAudioSource: AudioSource {
    var permissionDenied: Bool { false }
    func requestPermission() async -> Bool { true }
    func start(fileURL: URL?, onLevel: @escaping @Sendable (Float) -> Void) throws -> AsyncStream<AudioChunk> {
        Task { for i in 0..<400 { onLevel(i < 20 ? 0.6 : 0.5); try? await Task.sleep(for: .milliseconds(50)) } }
        return AsyncStream { $0.finish() }
    }
    func stop() {}
}

struct FakeTranscriber: LiveTranscriber {
    func transcribe(audio: AsyncStream<AudioChunk>, locale: Locale) -> AsyncThrowingStream<TranscriptUpdate, Error> {
        AsyncThrowingStream { c in
            Task {
                let words = ["Remember", "to", "email", "Alice", "about", "the", "launch"]
                var said: [String] = []
                for w in words {
                    said.append(w)
                    c.yield(TranscriptUpdate(text: said.joined(separator: " "), isFinal: false))
                    try? await Task.sleep(for: .milliseconds(80))
                }
                c.yield(TranscriptUpdate(text: said.joined(separator: " "), isFinal: true))
                c.finish()
            }
        }
    }
}
