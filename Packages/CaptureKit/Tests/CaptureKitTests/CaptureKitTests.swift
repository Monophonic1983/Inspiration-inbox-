import Foundation
import Testing
import Persistence
@testable import CaptureKit

@Test func defaultAutoStopIs2_5Seconds() {
    #expect(CaptureConfig().autoStopSilence == 2.5)
}

@Test func autoStopFiresAfterSilenceFollowingSpeech() {
    var d = SilenceDetector(config: CaptureConfig())
    #expect(d.feed(level: 0.5, at: 0) == nil)
    #expect(d.feed(level: 0.0, at: 0.5) == nil)
    #expect(d.feed(level: 0.0, at: 1.6) == .longPause)
    #expect(d.feed(level: 0.0, at: 1.8) == nil)            // pause tap fires once
    #expect(d.feed(level: 0.0, at: 3.1) == .autoStop)
}

@Test func slowStartNeverAutoStops() {
    var d = SilenceDetector(config: CaptureConfig())
    for t in stride(from: 0.0, through: 10.0, by: 0.5) { #expect(d.feed(level: 0, at: t) == nil) }
}

@Test func speechResetsTheSilenceTimer() {
    var d = SilenceDetector(config: CaptureConfig(autoStopSilence: 2))
    _ = d.feed(level: 0.5, at: 0)
    _ = d.feed(level: 0, at: 1)
    _ = d.feed(level: 0.5, at: 2.5)
    #expect(d.feed(level: 0, at: 3) == nil)
}

@Test func localeFollowsDeviceAndOverrides() {
    #expect(LocaleResolver.resolve(setting: .auto, preferredLanguages: ["zh-Hans-CN"]).identifier.hasPrefix("zh"))
    #expect(LocaleResolver.resolve(setting: .auto, preferredLanguages: ["zh-Hant-TW"]).identifier == "zh-TW")
    #expect(LocaleResolver.resolve(setting: .auto, preferredLanguages: ["fr-FR"]).identifier == "en-US")
    #expect(LocaleResolver.resolve(setting: .chinese, preferredLanguages: ["en-US"]).identifier == "zh-CN")
}

@MainActor @Test func forceQuitDraftIsRecoveredAsThought() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let drafts = DraftStore(directory: dir)
    drafts.write(.init(id: UUID(), transcript: "half a thought", audioFileName: nil, updatedAt: Date()))   // app killed here
    let store = ThoughtStore(container: try ThoughtStore.makeContainer(inMemory: true))
    let recovered = DraftStore(directory: dir).recover(into: store)
    #expect(recovered.count == 1 && recovered[0].rawTranscript == "half a thought")
    #expect(DraftStore(directory: dir).pending().isEmpty)
}

@MainActor @Test func emptyDraftWithoutAudioIsDiscarded() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let drafts = DraftStore(directory: dir)
    drafts.write(.init(id: UUID(), transcript: "", audioFileName: nil, updatedAt: Date()))
    let store = ThoughtStore(container: try ThoughtStore.makeContainer(inMemory: true))
    #expect(drafts.recover(into: store).isEmpty)
    #expect(drafts.pending().isEmpty)
}
