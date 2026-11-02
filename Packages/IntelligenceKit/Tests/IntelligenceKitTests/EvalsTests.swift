import Foundation
import Testing
import Persistence
@testable import IntelligenceKit

private func output(clean: String, title: String = "T", kind: String = "idea") -> StructuredThought {
    StructuredThought(title: title, cleanedText: clean, summary: "", kind: kind, tags: [], actionItems: [], openQuestions: [], uncertain: false)
}

@Test func faithfulWhenNoInventedNamesOrNumbers() {
    let t = "um so I should email Alice about the 3pm meeting"
    #expect(EvalScorer.isFaithful(output(clean: "Email Alice about the 3pm meeting."), transcript: t))
    #expect(!EvalScorer.isFaithful(output(clean: "Email Bob about the 4pm meeting."), transcript: t))
}

@Test func gateCUsesSeparateLanguageRates() {
    let rs = (0..<20).map { EvalResult(id: "\($0)", language: "en", valid: true, faithful: $0 < 19, titleOK: true, kindCorrect: true) }
    let s = EvalScorer.summarize(rs)
    #expect(s.first?.passesGateC == true)
}

@Test func parsesJSONLCases() throws {
    let line = #"{"id":"en-01","language":"en","category":"short","transcript":"buy milk","expected_kind":"task"}"#
    #expect(try EvalScorer.loadCases(jsonl: line + "\n").first?.expectedKind == "task")
}
