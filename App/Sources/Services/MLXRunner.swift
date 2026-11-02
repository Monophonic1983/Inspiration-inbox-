import Foundation
import IntelligenceKit

#if canImport(MLXLLM)
import MLXLLM
import MLXLMCommon

/// On-device structuring through MLX Swift. Thinking is switched off and decoding is greedy (temperature 0).
/// The MLX Swift API moves between releases: confirm these calls against the pinned version in Spike 2.
actor MLXRunner: LanguageModelRunner {
    nonisolated let modelID: String
    private let directory: URL
    private var container: ModelContainer?

    init(modelID: String, directory: URL) { self.modelID = modelID; self.directory = directory }

    func generate(system: String, user: String, maxTokens: Int) async throws -> String {
        let container = try await load()
        let input = UserInput(chat: [.system(system), .user(user)], additionalContext: ["enable_thinking": false])
        return try await container.perform { context in
            let prepared = try await context.processor.prepare(input: input)
            let result = try MLXLMCommon.generate(input: prepared,
                                                  parameters: GenerateParameters(maxTokens: maxTokens, temperature: 0),
                                                  context: context) { _ in .more }
            return result.output
        }
    }

    private func load() async throws -> ModelContainer {
        if let container { return container }
        let loaded = try await LLMModelFactory.shared.loadContainer(configuration: ModelConfiguration(directory: directory))
        container = loaded
        return loaded
    }
}
#endif
