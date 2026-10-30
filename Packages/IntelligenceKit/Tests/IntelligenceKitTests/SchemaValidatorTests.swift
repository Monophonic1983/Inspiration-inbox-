import Foundation
import Testing
@testable import IntelligenceKit

@Test func acceptsValidOutput() throws {
    let json = #"{"title":"Call mom","cleaned_text":"Call mom tomorrow.","summary":"Call mom","kind":"reminder","tags":["family"],"action_items":["Call mom"],"open_questions":[],"uncertain":false}"#
    #expect(try SchemaValidator.decode(Data(json.utf8)).kind == "reminder")
}

@Test func rejectsBadKindAndTooManyTags() {
    let bad = #"{"title":"x","cleaned_text":"x","summary":"x","kind":"poem","tags":["a","b","c","d"],"action_items":[],"open_questions":[],"uncertain":false}"#
    #expect(throws: ThoughtProcessorError.self) { try SchemaValidator.decode(Data(bad.utf8)) }
}
