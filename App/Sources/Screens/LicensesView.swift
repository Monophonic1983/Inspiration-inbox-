import SwiftUI
import DesignSystem

/// FR-16: open-source notices. Full license texts live in Resources/Licenses/ (see docs/app-store-checklist.md).
struct LicensesView: View {
    private struct Notice: Identifiable { let id = UUID(); let name: String; let license: String; let url: String }
    private let notices = [
        Notice(name: "Qwen3.5 models (Alibaba Cloud)", license: "Apache License 2.0", url: "https://www.apache.org/licenses/LICENSE-2.0"),
        Notice(name: "MLX Swift and MLX Swift Examples (Apple)", license: "MIT License", url: "https://opensource.org/license/mit"),
        Notice(name: "WhisperKit (Argmax)", license: "MIT License", url: "https://opensource.org/license/mit"),
        Notice(name: "Whisper large-v3-turbo (OpenAI)", license: "MIT License", url: "https://opensource.org/license/mit"),
    ]

    var body: some View {
        List(notices) { n in
            VStack(alignment: .leading, spacing: 2) {
                Text(n.name).font(DS.Font.body.bold())
                Text(n.license).font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
                if let url = URL(string: n.url) { Link(n.url, destination: url).font(DS.Font.caption) }
            }
            .padding(.vertical, DS.Spacing.xs)
        }
        .navigationTitle("Open-source licenses")
    }
}
