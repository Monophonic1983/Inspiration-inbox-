import Foundation
import SwiftData
import Testing
@testable import Persistence

@MainActor
private func makeStore() throws -> ThoughtStore {
    ThoughtStore(container: try ThoughtStore.makeContainer(inMemory: true))
}

@Test func newThoughtIsCapturedWithRawOnly() {
    let t = Thought(rawTranscript: "call mom tomorrow")
    #expect(t.status == .captured)
    #expect(t.title == nil && t.cleanedText == nil)
    #expect(t.tags.isEmpty && !t.isPinned && t.archivedAt == nil)
}

@MainActor @Test func saveRawPersistsCapturedThought() throws {
    let store = try makeStore()
    let t = try store.saveRaw(transcript: "hello", audioFileName: nil)
    #expect(try store.all().count == 1)
    #expect(t.status == .captured)
}

@MainActor @Test func applyKeepsUserEditsUnlessOverwritten() throws {
    let store = try makeStore()
    let t = try store.saveRaw(transcript: "raw words", audioFileName: nil)
    try store.edit(t, title: "Mine", cleanedText: "My text")
    let fields = ProcessedFields(title: "AI", cleanedText: "AI text", summary: "s", kind: .idea, tags: ["a", "b", "c", "d"], actionItems: ["do it"])
    try store.apply(fields, processorVersion: "v1", to: t)
    #expect(t.title == "Mine" && t.cleanedText == "My text")
    #expect(t.tags.count == 3 && t.status == .ready && t.actionItems.count == 1)
    try store.apply(fields, processorVersion: "v2", to: t, overwriteUserEdits: true)
    #expect(t.title == "AI" && t.userEditedAt == nil)
}

@MainActor @Test func archiveDoesNotDeleteAndUndoRestoresDelete() throws {
    let store = try makeStore()
    let t = try store.saveRaw(transcript: "keep me", audioFileName: nil)
    try store.setArchived(true, t)
    #expect(try store.all().isEmpty)
    #expect(try store.all(includeArchived: true).count == 1)
    let snap = ThoughtSnapshot(t)
    try store.delete(t)
    #expect(try store.all(includeArchived: true).isEmpty)
    try store.restore(snap)
    #expect(try store.all(includeArchived: true).first?.rawTranscript == "keep me")
}

@MainActor @Test func searchFindsChineseWithoutSpacesAndAcrossScripts() throws {
    let store = try makeStore()
    _ = try store.saveRaw(transcript: "明天下午三点开会讨论产品路线图", audioFileName: nil)
    _ = try store.saveRaw(transcript: "buy milk and eggs", audioFileName: nil)
    #expect(try store.search("产品路线").count == 1)
    #expect(try store.search("產品路線").count == 1)
    #expect(try store.search("MILK").count == 1)
    #expect(try store.search("zzz").isEmpty)
}

@Test func scriptConversionRoundTrips() {
    #expect(ScriptConverter.convert("開會討論", to: .simplified) == "开会讨论")
    #expect(ScriptConverter.convert("开会讨论 with Alice 3pm", to: .traditional).contains("Alice 3pm"))
}

@Test func audioPurgeRemovesOldFiles() throws {
    let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let store = AudioFileStore(directory: dir)
    try Data([1]).write(to: store.url(for: "a.m4a"))
    #expect(store.purge(olderThanDays: 30) == 0)
    #expect(store.purge(olderThanDays: 0) == 1)
}

@MainActor @Test func exportMarkdownIncludesActionItems() throws {
    let store = try makeStore()
    let t = try store.saveRaw(transcript: "raw", audioFileName: nil)
    try store.apply(.init(title: "T", cleanedText: "Body", summary: "S", kind: .task, tags: ["x"], actionItems: ["Ship"]), processorVersion: "v", to: t)
    let md = ThoughtExporter.markdown(t)
    #expect(md.hasPrefix("# T") && md.contains("- [ ] Ship") && md.contains("#x"))
    #expect(ThoughtExporter.plainText(t).contains("[ ] Ship"))
}
