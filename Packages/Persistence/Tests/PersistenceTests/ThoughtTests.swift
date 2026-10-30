import Testing
@testable import Persistence

@Test func newThoughtIsCapturedWithRawOnly() {
    let t = Thought(rawTranscript: "call mom tomorrow")
    #expect(t.status == .captured)
    #expect(t.title == nil && t.cleanedText == nil)
    #expect(t.tags.isEmpty && !t.isPinned && t.archivedAt == nil)
}
