import SwiftUI
import CaptureKit
import DesignSystem
import ModelStore
import Persistence

/// The one small settings sheet: capture, language, privacy, models, Enhanced mode, licenses.
struct SettingsView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var showConsent = false

    var body: some View {
        @Bindable var settings = env.settings
        NavigationStack {
            Form {
                Section("Capture") {
                    Stepper(value: $settings.autoStopSeconds, in: 1...6, step: 0.5) {
                        Text("Auto-stop after \(settings.autoStopSeconds, format: .number.precision(.fractionLength(1))) s of silence")
                    }
                    Picker("Speech language", selection: $settings.speechLanguage) {
                        Text("Follow device").tag(SpeechLanguage.auto)
                        Text("English").tag(SpeechLanguage.english)
                        Text("中文").tag(SpeechLanguage.chinese)
                    }
                    Picker("Chinese script", selection: $settings.chineseScript) {
                        Text("简体").tag(ChineseScript.simplified)
                        Text("繁體").tag(ChineseScript.traditional)
                    }
                }
                Section {
                    Toggle("Private mode", isOn: $settings.privateMode)
                    Picker("Keep audio", selection: $settings.audioRetentionDays) {
                        Text("Don't keep").tag(0)
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                        Text("90 days").tag(90)
                    }.disabled(settings.privateMode)
                } header: { Text("Privacy") } footer: {
                    Text("Private mode never keeps audio and never uses Enhanced mode. Audio stays on this device.")
                }
                Section {
                    ForEach(env.catalog.models.filter { !$0.files.isEmpty }) { model in ModelRow(model: model) }
                    Toggle("Download on Wi-Fi only", isOn: $settings.wifiOnly)
                    Toggle("Accuracy pass after recording", isOn: $settings.accuracyPass)
                } header: { Text("On-device AI") } footer: {
                    Text("Models are downloaded after install and can be deleted here. Capture works while they download.")
                }
                Section {
                    Toggle("Enhanced mode", isOn: Binding(
                        get: { settings.enhancedEnabled },
                        set: { on in if on { showConsent = true } else { settings.recordConsent(false) } }))
                        .disabled(settings.privateMode)
                } header: { Text("Cloud") } footer: {
                    Text("Off by default. When on, the text of each thought is sent to \(AppConfig.cloudProviderName) to structure it. Audio is never sent.")
                }
                Section {
                    NavigationLink("Archived thoughts") { ArchiveView() }
                    NavigationLink("Open-source licenses") { LicensesView() }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showConsent) {
                ConsentView { granted in settings.recordConsent(granted); showConsent = false }
            }
        }
    }
}

private struct ModelRow: View {
    let model: ModelDescriptor
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let state = env.modelStore.states[model.id] ?? .notInstalled
        HStack {
            VStack(alignment: .leading) {
                Text(model.displayName)
                Text(ByteCountFormatter.string(fromByteCount: model.totalBytes, countStyle: .file) + " · " + model.license)
                    .font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
            }
            Spacer()
            switch state {
            case .installed:
                Button("Delete", role: .destructive) { env.modelStore.delete(model.id) }
            case .downloading(let p):
                ProgressView(value: p).frame(width: 80)
                Button("Cancel") { env.modelStore.cancel(model.id) }
            case .notInstalled:
                Button("Download") { env.downloadAndRetry(model) }
            case .failed:
                Button("Retry") { env.downloadAndRetry(model) }
            }
        }
        .buttonStyle(.borderless)
    }
}
