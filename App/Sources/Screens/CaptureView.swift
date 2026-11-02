import SwiftUI
import CaptureKit
import DesignSystem
import Persistence

struct CaptureView: View {
    let session: CaptureSession
    let ns: Namespace.ID
    let finish: (Thought?) -> Void
    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressStart: Date?
    @State private var typing = false
    @State private var finished = false

    var body: some View {
        ZStack {
            DS.Color.background.ignoresSafeArea()
            VStack(spacing: DS.Spacing.l) {
                Spacer(minLength: DS.Spacing.xl)
                TranscriptView(text: session.transcript)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .bottom)
                    .padding(.horizontal, DS.Spacing.l)
                orb
                controls
                Spacer(minLength: DS.Spacing.l)
            }
        }
        .accessibilityIdentifier("captureScreen")
        .sheet(isPresented: $typing) {
            TextCaptureSheet { text in
                if let t = env.saveTyped(text) { session.cancelAndDiscard(); finish(t) }
            }
        }
        .onChange(of: session.state) { _, state in
            if case .saved = state, !finished { finished = true }
        }
    }

    @ViewBuilder private var orb: some View {
        switch session.state {
        case .permissionDenied:
            VStack(spacing: DS.Spacing.m) {
                Text("Microphone or speech access is off. You can still type a thought, or turn access on in Settings.")
                    .multilineTextAlignment(.center).font(DS.Font.body).foregroundStyle(DS.Color.secondaryText)
                Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) } }
                    .frame(minHeight: DS.Spacing.minTarget)
            }.padding(.horizontal, DS.Spacing.l)
        case .failed(let message):
            Text(message).font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText).padding()
        default:
            Orb(level: session.level, isActive: session.state == .recording)
                .frame(width: 200, height: 200)
                .contentShape(Circle())
                // Quick tap stops; press-and-hold then release stops too (FR-3).
                .gesture(DragGesture(minimumDistance: 0)
                    .onChanged { _ in if pressStart == nil { pressStart = Date() } }
                    .onEnded { _ in
                        let held = pressStart.map { Date().timeIntervalSince($0) } ?? 0
                        pressStart = nil
                        stop(held > 0.5 ? .holdRelease : .tap)
                    })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Recording"))
                .accessibilityHint(Text("Double tap to stop and save"))
                .accessibilityAddTraits(.isButton)
                .accessibilityIdentifier("orbStop")
                .accessibilityAction { stop(.tap) }
        }
    }

    private var controls: some View {
        HStack(spacing: DS.Spacing.xl) {
            Button { typing = true } label: { Label("Type instead", systemImage: "keyboard") }
                .frame(minHeight: DS.Spacing.minTarget)
                .accessibilityIdentifier("typeInstead")
            Button { stop(.tap) } label: { Label("Stop", systemImage: "stop.circle.fill") }
                .frame(minHeight: DS.Spacing.minTarget)
                .accessibilityIdentifier("stopCapture")
        }
        .font(DS.Font.body)
        .labelStyle(.titleAndIcon)
        .foregroundStyle(DS.Color.primaryText)
    }

    private func stop(_ reason: StopReason) {
        guard session.state == .recording else { return }
        Task {
            let thought = await session.stop(reason)
            finish(thought)
        }
    }
}

/// Words fade in as they arrive; the newest are brightest.
struct TranscriptView: View {
    let text: String

    var body: some View {
        let words = text.split(separator: " ", omittingEmptySubsequences: true).map(String.init)
        let tail = Array(words.suffix(40))
        // Chinese has no spaces: fall back to showing the text whole.
        let flow = tail.enumerated().reduce(Text("")) { acc, item in
            let age = tail.count - 1 - item.offset
            return acc + Text(item.element + " ").foregroundStyle(.primary.opacity(max(0.35, 1 - Double(age) * 0.08)))
        }
        Group {
            if words.count <= 1 { Text(text).foregroundStyle(.primary) } else { flow }
        }
        .font(.system(.title2, design: .default, weight: .medium))
        .multilineTextAlignment(.center)
        .animation(DS.Motion.snappy, value: text)
        .accessibilityIdentifier("liveTranscript")
        .accessibilityLabel(Text("Live transcript"))
        .accessibilityValue(Text(text))
    }
}

struct TextCaptureSheet: View {
    var onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .font(DS.Font.body)
                .focused($focused)
                .padding(DS.Spacing.m)
                .navigationTitle("Type a thought")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { onSave(text); dismiss() }
                            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("saveTyped")
                    }
                }
                .onAppear { focused = true }
        }
        .presentationDetents([.medium, .large])
    }
}
