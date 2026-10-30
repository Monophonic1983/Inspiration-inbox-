import Foundation
import Testing
import Persistence
@testable import IntelligenceKit

private let good = #"{"title":"Call mom","cleaned_text":"Call mom tomorrow.","summary":"Call mom","kind":"reminder","tags":["family"],"action_items":["Call mom"],"open_questions":[],"uncertain":false}"#

@Test func acceptsValidOutput() throws {
    #expect(try SchemaValidator.decode(Data(good.utf8)).kind == "reminder")
}

@Test func rejectsBadKind() {
    let bad = good.replacingOccurrences(of: "reminder", with: "poem")
    #expect(throws: ThoughtProcessorError.self) { try SchemaValidator.decode(Data(bad.utf8)) }
}

@Test func truncatesTagsToThree() throws {
    let many = good.replacingOccurrences(of: #"["family"]"#, with: #"["a","b","c","d"]"#)
    #expect(try SchemaValidator.decode(Data(many.utf8)).tags.count == 3)
}

@Test func extractsJSONFromThinkBlockAndFences() throws {
    let text = "<think>\nlet me think {not json}\n</think>\n```json\n\(good)\n```"
    #expect(try SchemaValidator.decode(modelText: text).title == "Call mom")
}

@Test func extractorHandlesBracesInStrings() {
    let s = #"x {"a":"}{","b":{"c":1}} tail"#
    #expect(JSONExtractor.extract(from: s) == #"{"a":"}{","b":{"c":1}}"#)
}

@Test func unclosedThinkBlockIsInvalid() {
    #expect(throws: ThoughtProcessorError.self) { try SchemaValidator.decode(modelText: "<think>still going {\"title\":\"x\"}") }
}
