import Foundation
import Testing
import Persistence
@testable import IntelligenceKit

private actor Counter { var n = 0; func bump() { n += 1 }; var value: Int { n } }

private struct StubProcessor: ThoughtProcessor {
    let version = "stub"
    let failuresBeforeSuccess: Int
    let counter: Counter
    func structure(transcript: String, script: ChineseScript) async throws -> StructuredThought {
        await counter.bump()
        if await counter.value <= failuresBeforeSuccess { throw ThoughtProcessorError.invalidOutput }
        return try SchemaValidator.decode(modelText: #"{"title":"T","cleaned_text":"C","summary":"S","kind":"idea","tags":[],"action_items":[],"open_questions":[],"uncertain":false}"#)
    }
}

@MainActor private struct Provider: ProcessorProvider {
    let processor: ThoughtProcessor?
    func currentProcessor() async -> ThoughtProcessor? { processor }
}

@MainActor private func queue(_ p: ThoughtProcessor?, store: ThoughtStore) -> ProcessingQueue {
    ProcessingQueue(store: store, provider: Provider(processor: p), script: { .simplified }, sleep: { _ in })
}

@MainActor @Test func retriesTwiceThenSucceeds() async throws {
    let store = ThoughtStore(container: try ThoughtStore.makeContainer(inMemory: true))
    let t = try store.saveRaw(transcript: "hi", audioFileName: nil)
    let counter = Counter()
    await queue(StubProcessor(failuresBeforeSuccess: 2, counter: counter), store: store).process(t)
    #expect(t.status == .ready)
    #expect(await counter.value == 3)
}

@MainActor @Test func failsAfterThreeAttemptsAndKeepsRaw() async throws {
    let store = ThoughtStore(container: try ThoughtStore.makeContainer(inMemory: true))
    let t = try store.saveRaw(transcript: "hi", audioFileName: nil)
    let counter = Counter()
    await queue(StubProcessor(failuresBeforeSuccess: 99, counter: counter), store: store).process(t)
    #expect(t.status == .failed && t.rawTranscript == "hi")
    #expect(await counter.value == 3)
}

@MainActor @Test func noProcessorLeavesThoughtCaptured() async throws {
    let store = ThoughtStore(container: try ThoughtStore.makeContainer(inMemory: true))
    let t = try store.saveRaw(transcript: "hi", audioFileName: nil)
    await queue(nil, store: store).process(t)
    #expect(t.status == .captured)
}

// MARK: Consent (FR-15): no network call before consent

private final class CountingTransport: HTTPTransport, @unchecked Sendable {
    var calls = 0
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        calls += 1
        throw URLError(.notConnectedToInternet)
    }
}
private final class CountingAttestation: AttestationProvider, @unchecked Sendable {
    var calls = 0
    func assertion(for body: Data) async throws -> (keyID: String, assertion: Data) { calls += 1; return ("k", Data()) }
}

@Test func cloudMakesNoNetworkOrAttestationCallBeforeConsent() async {
    let transport = CountingTransport(), attest = CountingAttestation()
    let cloud = CloudProcessor(endpoint: URL(string: "https://example.com")!, consent: StaticConsent(false), attestation: attest, transport: transport)
    await #expect(throws: ThoughtProcessorError.consentRequired) {
        try await cloud.structure(transcript: "secret", script: .simplified)
    }
    #expect(transport.calls == 0 && attest.calls == 0)
}

@Test func cloudCallsTransportAfterConsent() async {
    let transport = CountingTransport()
    let cloud = CloudProcessor(endpoint: URL(string: "https://example.com")!, consent: StaticConsent(true), attestation: CountingAttestation(), transport: transport)
    _ = try? await cloud.structure(transcript: "x", script: .simplified)
    #expect(transport.calls == 1)
}
