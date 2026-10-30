import Foundation
import Persistence

public enum ProcessorChoice: Sendable { case cloud, onDevice, appleFoundation }

/// Chooses a processor. Returns nil when none can run; the thought then stays `captured` and is retried later.
@MainActor
public protocol ProcessorProvider {
    func currentProcessor() async -> ThoughtProcessor?
}

/// Runs processors after the raw thought has been saved. Capture never depends on this.
@MainActor
public final class ProcessingQueue {
    public static let backoff: [TimeInterval] = [2, 8]   // two retries, exponential

    private let store: ThoughtStore
    private let provider: ProcessorProvider
    private let sleep: @Sendable (TimeInterval) async -> Void
    private let script: @MainActor () -> ChineseScript
    private let inputText: @MainActor (Thought) async -> String
    private var inFlight: Set<UUID> = []

    public init(store: ThoughtStore, provider: ProcessorProvider,
                script: @escaping @MainActor () -> ChineseScript,
                inputText: @escaping @MainActor (Thought) async -> String = { $0.rawTranscript },
                sleep: @escaping @Sendable (TimeInterval) async -> Void = { try? await Task.sleep(for: .seconds($0)) }) {
        self.store = store; self.provider = provider; self.script = script; self.inputText = inputText; self.sleep = sleep
    }

    /// Fire-and-forget entry point used right after a capture is saved.
    public func enqueue(_ thought: Thought) { Task { await process(thought) } }

    /// Retries every thought still `captured` (call on launch and after a model download finishes).
    public func retryPending() {
        for t in (try? store.pendingProcessing()) ?? [] { enqueue(t) }
    }

    /// Re-run on demand. `overwriteUserEdits` must come from a user confirmation.
    public func reprocess(_ thought: Thought, overwriteUserEdits: Bool) async {
        await process(thought, overwriteUserEdits: overwriteUserEdits)
    }

    public func process(_ thought: Thought, overwriteUserEdits: Bool = false) async {
        guard inFlight.insert(thought.id).inserted else { return }
        defer { inFlight.remove(thought.id) }
        guard let processor = await provider.currentProcessor() else { return }   // stays captured

        // The accuracy pass may supply a better transcript than the live one; the stored raw text is never changed.
        let input = await inputText(thought)
        var attempt = 0
        while true {
            do {
                let result = try await processor.structure(transcript: input, script: script())
                try? store.apply(result.fields, processorVersion: processor.version, to: thought, overwriteUserEdits: overwriteUserEdits)
                return
            } catch ThoughtProcessorError.consentRequired, ThoughtProcessorError.modelUnavailable {
                return   // not a failure: leave as captured
            } catch {
                guard attempt < Self.backoff.count else {
                    try? store.markFailed(thought)   // card shows the raw text
                    return
                }
                await sleep(Self.backoff[attempt])
                attempt += 1
            }
        }
    }
}
