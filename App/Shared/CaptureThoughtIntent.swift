import AppIntents

/// Shared by the app and the Control Center / Lock Screen control extension.
/// The Action Button is mapped to this intent. It opens the app straight into recording (FR-1).
/// Phase 0 Spike 1 measures press-to-recording and decides whether an audio-recording intent with a
/// Live Activity is needed instead (see docs/mac-setup.md).
struct CaptureThoughtIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture Thought"
    static let description = IntentDescription("Start recording a thought right away.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        LaunchRouter.shared.requestCapture()
        return .result()
    }
}

/// In-process hand-off from the intent to the UI. A flag in memory is enough because the intent runs in the app process
/// (openAppWhenRun), and it avoids any disk or IPC work on the critical path.
@MainActor
final class LaunchRouter {
    static let shared = LaunchRouter()
    private(set) var pendingCapture = false
    var onCaptureRequested: (() -> Void)?

    func requestCapture() {
        pendingCapture = true
        onCaptureRequested?()
    }

    func consume() -> Bool { defer { pendingCapture = false }; return pendingCapture }
}
