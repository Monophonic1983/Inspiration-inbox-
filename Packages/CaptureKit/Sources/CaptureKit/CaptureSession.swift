import Foundation
import Observation
import Persistence

public enum CaptureState: Equatable, Sendable {
    case idle, recording, saving, saved(UUID), permissionDenied, failed(String)
}

/// Orchestrates one capture: record, transcribe live, stop (tap / hold-release / silence), save raw immediately.
/// Saving never waits on AI, the network or a model download (FR-4).
@MainActor @Observable
public final class CaptureSession {
    public private(set) var state: CaptureState = .idle
    public private(set) var transcript: String = ""
    public private(set) var level: Float = 0

    public var onHaptic: (@MainActor (HapticEvent) -> Void)?
    public enum HapticEvent: Sendable { case start, longPause, saved }

    private let store: ThoughtStore
    private let audioStore: AudioFileStore
    private let drafts: DraftStore
    private let transcriber: LiveTranscriber
    private let recorder: AudioSource
    private let config: CaptureConfig
    private let locale: Locale
    private let keepAudio: Bool
    private let script: ChineseScript
    private var detector: SilenceDetector
    private var startedAt = Date()
    private var transcriptTask: Task<Void, Never>?
    private var finalized = ""        // finished segments
    private var volatile = ""         // current partial segment
    private var draftID = UUID()
    private var audioName: String?
    private var stopping = false

    public init(store: ThoughtStore, audioStore: AudioFileStore, drafts: DraftStore, transcriber: LiveTranscriber,
                config: CaptureConfig, locale: Locale, keepAudio: Bool, script: ChineseScript,
                audioSource: AudioSource = AudioRecorder()) {
        self.recorder = audioSource
        self.store = store; self.audioStore = audioStore; self.drafts = drafts; self.transcriber = transcriber
        self.config = config; self.locale = locale; self.keepAudio = keepAudio; self.script = script
        self.detector = SilenceDetector(config: config)
    }

    /// Requests microphone access in context (first capture), then starts recording.
    public func start() async {
        guard state == .idle else { return }
        if recorder.permissionDenied { state = .permissionDenied; return }
        guard await recorder.requestPermission() else { state = .permissionDenied; return }

        audioName = keepAudio ? audioStore.newFileName() : nil
        startedAt = Date()
        do {
            let stream = try recorder.start(fileURL: audioName.map(audioStore.url(for:))) { [weak self] lvl in
                Task { @MainActor in self?.ingest(level: lvl) }
            }
            state = .recording
            onHaptic?(.start)
            transcriptTask = Task { [weak self, transcriber, locale] in
                do {
                    for try await update in transcriber.transcribe(audio: stream, locale: locale) {
                        await self?.ingest(update)
                    }
                } catch { /* transcription failure must not lose the audio; the thought still saves */ }
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    private func ingest(_ update: TranscriptUpdate) {
        if update.isFinal {
            finalized += (finalized.isEmpty ? "" : " ") + update.text.trimmingCharacters(in: .whitespaces)
            volatile = ""
        } else { volatile = update.text }
        transcript = current
        drafts.write(.init(id: draftID, transcript: current, audioFileName: audioName, updatedAt: Date()))
    }

    private var current: String {
        [finalized, volatile].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private func ingest(level: Float) {
        self.level = level
        guard state == .recording else { return }
        switch detector.feed(level: level, at: Date().timeIntervalSince(startedAt)) {
        case .longPause?: onHaptic?(.longPause)
        case .autoStop?: Task { await stop(.silence) }
        case nil: break
        }
    }

    /// Stops and saves. Waits at most `grace` for the transcriber's final result, so stop-to-saved stays within 300 ms.
    @discardableResult
    public func stop(_ reason: StopReason, grace: Duration = .milliseconds(150)) async -> Thought? {
        guard state == .recording, !stopping else { return nil }
        stopping = true
        state = .saving
        recorder.stop()
        _ = try? await withTimeout(grace) { await self.transcriptTask?.value }
        transcriptTask?.cancel()

        // Typed fix-up: output follows the chosen Chinese script, other text is untouched.
        var text = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if ScriptConverter.containsHan(text) { text = ScriptConverter.convert(text, to: script) }
        do {
            let thought = try store.saveRaw(transcript: text, audioFileName: audioName)
            drafts.remove(draftID)
            onHaptic?(.saved)
            state = .saved(thought.id)
            return thought
        } catch {
            state = .failed(error.localizedDescription)   // draft file remains; recovered on next launch
            return nil
        }
    }

    public func cancelAndDiscard() {
        recorder.stop(); transcriptTask?.cancel()
        if let audioName { audioStore.delete(audioName) }
        drafts.remove(draftID)
        state = .idle
    }
}

private func withTimeout(_ d: Duration, _ op: @escaping @Sendable () async -> Void) async throws {
    await withTaskGroup(of: Void.self) { group in
        group.addTask { await op() }
        group.addTask { try? await Task.sleep(for: d) }
        await group.next()
        group.cancelAll()
    }
}
