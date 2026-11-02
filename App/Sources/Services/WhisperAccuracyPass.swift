import Foundation

#if canImport(WhisperKit)
import WhisperKit

/// Optional re-transcription of the saved audio after stop. The better text feeds the structuring model;
/// the stored raw transcript is never changed. The Whisper model comes from ModelStore, not WhisperKit's own downloader.
actor WhisperAccuracyPass {
    private var pipeline: WhisperKit?
    private let modelFolder: URL

    init(modelFolder: URL) { self.modelFolder = modelFolder }

    func transcribe(audioURL: URL, languageCode: String?) async throws -> String {
        if pipeline == nil {
            pipeline = try await WhisperKit(WhisperKitConfig(modelFolder: modelFolder.path, download: false))
        }
        let options = DecodingOptions(task: .transcribe, language: languageCode, temperature: 0)
        let results = try await pipeline!.transcribe(audioPath: audioURL.path, decodeOptions: options)
        return results.map(\.text).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
#endif
