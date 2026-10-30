import AppIntents
import SwiftUI
import WidgetKit

struct CaptureControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "com.example.inspirationinbox.capture") {
            ControlWidgetButton(action: CaptureThoughtIntent()) {
                Label("Capture Thought", systemImage: "mic.circle.fill")
            }
        }
        .displayName("Capture Thought")
        .description("Record a thought in one press.")
    }
}

@main
struct InspirationInboxControls: WidgetBundle {
    var body: some Widget { CaptureControl() }
}
