import SwiftUI
import SwiftData
import CaptureKit
import DesignSystem
import Persistence

/// Three screens: Capture, Inbox, Thought. The Inbox is always underneath so the capture card can crystallize into its slot.
struct RootView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var ns
    @State private var capture: CaptureSession?
    @State private var crystalID: UUID?

    var body: some View {
        ZStack {
            NavigationStack { InboxView(ns: ns, crystalID: crystalID, startCapture: startCapture) }
            if let capture {
                CaptureView(session: capture, ns: ns, finish: finish(_:))
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .overlay(alignment: .bottom) { UndoBanner() }
        .onAppear {
            LaunchRouter.shared.onCaptureRequested = { startCapture() }
            if LaunchRouter.shared.consume() { startCapture() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active, LaunchRouter.shared.consume() { startCapture() }
        }
        .onChange(of: env.modelStore.states) { _, states in
            if states.values.contains(.installed) { env.queue.retryPending() }
        }
        .task {
            if AppConfig.isUITest, ProcessInfo.processInfo.arguments.contains("-startCapture") { startCapture() }
        }
    }

    private func startCapture() {
        guard capture == nil else { return }
        let session = env.makeCaptureSession()
        session.onHaptic = { event in
            switch event {
            case .start: Haptic.start.play()
            case .longPause: Haptic.pause.play()
            case .saved: Haptic.saved.play()
            }
        }
        crystalID = nil
        withAnimation(DS.Motion.snappy) { capture = session }
        Task { await session.start() }
    }

    /// Called after the raw thought is saved: start AI in the background, then crystallize into the Inbox.
    private func finish(_ thought: Thought?) {
        if let thought {
            env.queue.enqueue(thought)
            crystalID = thought.id
        }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.25) : DS.Motion.gentle) { capture = nil }
    }
}

struct UndoBanner: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if let action = env.undoAction {
            HStack {
                Text(action.message).font(DS.Font.body)
                Spacer()
                Button("Undo") { action.undo(); env.undoAction = nil }
                    .font(DS.Font.body.bold())
                    .frame(minWidth: DS.Spacing.minTarget, minHeight: DS.Spacing.minTarget)
                    .accessibilityIdentifier("undoButton")
            }
            .padding(.horizontal, DS.Spacing.m)
            .background(.regularMaterial, in: Capsule())
            .padding(DS.Spacing.m)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(DS.Motion.snappy, value: env.undoAction?.id)
        }
    }
}
