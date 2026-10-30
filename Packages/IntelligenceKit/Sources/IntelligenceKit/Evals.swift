import Foundation
import Persistence

public struct EvalCase: Codable, Sendable, Equatable {
    public var id: String
    public var language: String        // "en" | "zh"
    public var category: String        // short | long | rambling | multi-topic | mixed
    public var transcript: String
    public var expectedKind: String
    enum CodingKeys: String, CodingKey { case id, language, category, transcript, expectedKind = "expected_kind" }
}

public struct EvalResult: Codable, Sendable, Equatable {
    public var id: String
    public var language: String
    public var valid: Bool
    public var faithful: Bool
    public var titleOK: Bool
    public var kindCorrect: Bool
}

public struct EvalSummary: Codable, Sendable, Equatable {
    public var language: String
    public var count: Int
    public var validRate: Double
    public var faithfulRate: Double
    /// Gate C bar: at least 95% valid and 90% faithful, scored separately per language.
    public var passesGateC: Bool { validRate >= 0.95 && faithfulRate >= 0.90 }
}

public enum EvalScorer {
    public static func loadCases(jsonl: String) throws -> [EvalCase] {
        try jsonl.split(whereSeparator: \.isNewline).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .map { try JSONDecoder().decode(EvalCase.self, from: Data($0.utf8)) }
    }

    /// Automatic faithfulness check: every number and every Latin word in the output must appear in the transcript
    /// (names, terms and figures must not be invented). A human spot-check of a sample remains part of Gate C.
    public static func isFaithful(_ output: StructuredThought, transcript: String) -> Bool {
        let source = transcript.lowercased()
        let produced = [output.cleanedText, output.summary, output.title] + output.actionItems + output.tags
        let tokens = produced.flatMap { latinAndNumberTokens($0) }
        let stopwords: Set<String> = ["a", "an", "the", "to", "of", "and", "or", "for", "in", "on", "with", "is", "it"]
        return tokens.allSatisfy { stopwords.contains($0) || source.contains($0) || source.contains(stem($0)) }
    }

    static func stem(_ w: String) -> String { w.count > 4 ? String(w.dropLast(1)) : w }

    static func latinAndNumberTokens(_ s: String) -> [String] {
        var out: [String] = [], cur = ""
        for ch in s.lowercased() {
            if ch.isASCII && (ch.isLetter || ch.isNumber) { cur.append(ch) } else { if !cur.isEmpty { out.append(cur); cur = "" } }
        }
        if !cur.isEmpty { out.append(cur) }
        return out
    }

    public static func score(_ c: EvalCase, output: Result<StructuredThought, Error>) -> EvalResult {
        switch output {
        case .failure:
            return EvalResult(id: c.id, language: c.language, valid: false, faithful: false, titleOK: false, kindCorrect: false)
        case .success(let o):
            let words = o.title.split(separator: " ").count
            let titleOK = !o.title.isEmpty && (words <= 8 || ScriptConverter.containsHan(o.title)) && o.title.count <= 40
            return EvalResult(id: c.id, language: c.language, valid: true, faithful: isFaithful(o, transcript: c.transcript),
                              titleOK: titleOK, kindCorrect: o.kind == c.expectedKind)
        }
    }

    public static func summarize(_ results: [EvalResult]) -> [EvalSummary] {
        Dictionary(grouping: results, by: \.language).map { lang, rs in
            EvalSummary(language: lang, count: rs.count,
                        validRate: Double(rs.filter(\.valid).count) / Double(rs.count),
                        faithfulRate: Double(rs.filter(\.faithful).count) / Double(rs.count))
        }.sorted { $0.language < $1.language }
    }
}

public struct EvalRunner: Sendable {
    private let processor: ThoughtProcessor
    public init(processor: ThoughtProcessor) { self.processor = processor }

    public func run(cases: [EvalCase], script: ChineseScript = .simplified) async -> [EvalResult] {
        var results: [EvalResult] = []
        for c in cases {
            let out: Result<StructuredThought, Error>
            do { out = .success(try await processor.structure(transcript: c.transcript, script: script)) }
            catch { out = .failure(error) }
            results.append(EvalScorer.score(c, output: out))
        }
        return results
    }
}
