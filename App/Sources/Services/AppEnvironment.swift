import Foundation
import Observation
import SwiftData
import CaptureKit
import DesignSystem
import IntelligenceKit
import ModelStore
import Persistence

/// Picks the processor for the current settings and device. Nil means "save raw only for now".
@MainActor
final class ProcessorResolver: ProcessorProvider {
    var catalog: ModelCatalog
    private let settings: AppSettings
    private let models: ModelStore
    private let attestation = AttestationService()
    private var onDevice: [String: ThoughtProcessor] = [:]

    init(settings: AppSettings, models: ModelStore, catalog: ModelCatalog) {
        self.settings = settings; self.models = models; self.catalog = catalog
    }

    func currentProcessor() async -> ThoughtProcessor? {
        // Cloud only after explicit opt-in (consent is re-checked inside CloudProcessor too).
        if settings.enhancedEnabled, !settings.privateMode, UserDefaultsConsent().hasConsented {
            return CloudProcessor(endpoint: AppConfig.cloudEndpoint, consent: UserDefaultsConsent(), attestation: attestation)
        }
        #if canImport(MLXLLM)
        if let model = catalog.structuringModel(forRAMGB: DeviceCapabilities.physicalRAMGB),
           let dir = models.installedDirectory(for: model.id) {
            if let cached = onDevice[model.id] { return cached }
            let processor = OnDeviceProcessor(runner: MLXRunner(modelID: model.id, directory: dir))
            onDevice[model.id] = processor
            return processor
        }
        #endif
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *), FoundationModelsProcessor.isAvailable { return FoundationModelsProcessor() }
        #endif
        return nil
    }
}

struct UndoAction: Identifiable {
    let id = UUID()
    let message: String
    let undo: @MainActor () -> Void
}

@MainActor @Observable
final class AppEnvironment {
    let settings = AppSettings()
    let store: ThoughtStore
    let audioStore = AudioFileStore()
    let drafts = DraftStore()
    let modelStore = ModelStore()
    private(set) var catalog: ModelCatalog
    let resolver: ProcessorResolver
    let queue: ProcessingQueue
    var undoAction: UndoAction?

    init() {
        let container: ModelContainer
        if AppConfig.isUITest {
            container = try! ThoughtStore.makeContainer(inMemory: true)
        } else if let synced = try? ThoughtStore.makeContainer(cloudKitContainer: AppConfig.cloudKitContainer) {
            container = synced
        } else {
            container = try! ThoughtStore.makeContainer()   // no iCloud account or entitlement: stay local
        }
        store = ThoughtStore(container: container)
        let bundled = CatalogLoader.bundled()
        catalog = bundled
        modelStore.wifiOnly = settings.wifiOnly
        let resolver = ProcessorResolver(settings: settings, models: modelStore, catalog: bundled)
        self.resolver = resolver
        let settings = self.settings
        let models = self.modelStore
        let audio = self.audioStore
        queue = ProcessingQueue(store: store, provider: resolver, script: { settings.chineseScript },
                                inputText: { thought in
            await Self.accuracyText(for: thought, settings: settings, models: models, audio: audio) ?? thought.rawTranscript
        })
    }

    /// Runs once at launch: recover interrupted captures, apply audio retention, refresh the catalog, retry unprocessed thoughts.
    func onLaunch() async {
        let recovered = drafts.recover(into: store)
        recovered.forEach(queue.enqueue)
        audioStore.purge(olderThanDays: settings.keepAudio ? settings.audioRetentionDays : 0)
        catalog = await CatalogLoader.load(remoteURL: AppConfig.catalogURL)
        resolver.catalog = catalog
        modelStore.refresh(catalog)
        queue.retryPending()
    }

    func makeCaptureSession() -> CaptureSession {
        let locale = LocaleResolver.resolve(setting: settings.speechLanguage)
        let config = CaptureConfig(autoStopSeconds: settings.autoStopSeconds)
        if AppConfig.isUITest {
            return CaptureSession(store: store, audioStore: audioStore, drafts: drafts, transcriber: FakeTranscriber(),
                                  config: config, locale: locale, keepAudio: false, script: settings.chineseScript,
                                  audioSource: FakeAudioSource())
        }
        return CaptureSession(store: store, audioStore: audioStore, drafts: drafts, transcriber: AppleSpeechTranscriber(),
                              config: config, locale: locale, keepAudio: settings.keepAudio, script: settings.chineseScript)
    }

    /// FR-5: typed thoughts enter the same pipeline as voice.
    @discardableResult
    func saveTyped(_ text: String) -> Thought? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let t = try? store.saveRaw(transcript: trimmed, audioFileName: nil) else { return nil }
        Haptic.saved.play()
        queue.enqueue(t)
        return t
    }

    /// Every triage action has a haptic and an undo.
    func perform(_ message: String, _ action: () throws -> Void, undo: @escaping @MainActor () -> Void) {
        guard (try? action()) != nil else { return }
        Haptic.triage.play()
        let item = UndoAction(message: message, undo: undo)
        undoAction = item
        Task {
            try? await Task.sleep(for: .seconds(5))
            if undoAction?.id == item.id { undoAction = nil }
        }
    }

    func downloadAndRetry(_ model: ModelDescriptor) {
        modelStore.wifiOnly = settings.wifiOnly
        modelStore.download(model)
    }

    private static func accuracyText(for thought: Thought, settings: AppSettings, models: ModelStore, audio: AudioFileStore) async -> String? {
        #if canImport(WhisperKit)
        guard settings.accuracyPass, let name = thought.audioFileName,
              let dir = models.installedDirectory(for: "whisper-large-v3-turbo") else { return nil }
        let code = LocaleResolver.resolve(setting: settings.speechLanguage).language.languageCode?.identifier
        let text = try? await WhisperAccuracyPass(modelFolder: dir).transcribe(audioURL: audio.url(for: name), languageCode: code)
        guard let text, !text.isEmpty else { return nil }
        return ScriptConverter.containsHan(text) ? ScriptConverter.convert(text, to: settings.chineseScript) : text
        #else
        return nil
        #endif
    }
}
