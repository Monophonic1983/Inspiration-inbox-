import SwiftUI

/// Haptic presets from the capture spec: soft tick on start, light tap on long pause, success on save.
public enum Haptic {
    case start, pause, saved, triage

    @MainActor public func play() {
        #if canImport(UIKit)
        switch self {
        case .start: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .pause, .triage: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .saved: UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        #endif
    }
}
