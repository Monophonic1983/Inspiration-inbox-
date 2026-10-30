import Foundation
import Persistence

/// Runs a local language model. Implemented in the app target (MLX Swift first, llama.cpp as fallback) so this package has no heavy dependencies.
/// Implementations must disable thinking mode and use greedy decoding.
public protocol LanguageModelRunner: Sendable {
    var modelID: String { get }
    func generate(system: String, user: String, maxTokens: Int) async throws -> String
}

/// FR-8: on-device structuring. Needs no network.
public struct OnDeviceProcessor: ThoughtProcessor {
    private let runner: LanguageModelRunner
    public var version: String { "\(Prompt.version)+\(runner.modelID)" }

    public init(runner: LanguageModelRunner) { self.runner = runner }

    public func structure(transcript: String, script: ChineseScript) async throws -> StructuredThought {
        let text = try await runner.generate(system: Prompt.system(script: script),
                                             user: Prompt.user(transcript: transcript), maxTokens: 1024)
        return try SchemaValidator.decode(modelText: text)
    }
}

#if canImport(FoundationModels)
import FoundationModels

/// Baseline and low-RAM fallback. Availability depends on device and language settings.
@available(iOS 26.0, *)
public struct FoundationModelsProcessor: ThoughtProcessor {
    public var version: String { "\(Prompt.version)+apple-foundation-models" }
    public init() {}

    public static var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    public func structure(transcript: String, script: ChineseScript) async throws -> StructuredThought {
        guard Self.isAvailable else { throw ThoughtProcessorError.modelUnavailable }
        let session = LanguageModelSession(instructions: Prompt.system(script: script))
        let response = try await session.respond(to: Prompt.user(transcript: transcript))
        return try SchemaValidator.decode(modelText: response.content)
    }
}
#endif
