import SwiftUI
import DesignSystem

/// Enhanced mode consent (FR-15, App Store guideline 5.1.2(i)): names the provider and the data sent.
/// No network call happens before the user taps Agree.
struct ConsentView: View {
    var decide: (Bool) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {
            Text("Turn on Enhanced mode?").font(DS.Font.largeTitle)
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                row("paperplane", "What is sent", "The text of each thought you capture (the transcript). Audio is never sent.")
                row("building.2", "Who receives it", "\(AppConfig.cloudProviderName), through our server, which only forwards the text and keeps no copy.")
                row("sparkles", "Why", "A larger model can structure your thought more accurately than the on-device one.")
                row("hand.raised", "You stay in control", "Turn it off any time in Settings. Nothing is sent until you agree.")
            }
            Spacer()
            Button { decide(true) } label: { Text("Agree and turn on").frame(maxWidth: .infinity).frame(minHeight: DS.Spacing.minTarget) }
                .buttonStyle(.borderedProminent).tint(DS.Color.accent)
                .accessibilityIdentifier("consentAgree")
            Button { decide(false) } label: { Text("Not now").frame(maxWidth: .infinity).frame(minHeight: DS.Spacing.minTarget) }
        }
        .padding(DS.Spacing.l)
        .presentationDetents([.large])
        .interactiveDismissDisabled()
    }

    private func row(_ symbol: String, _ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            Image(systemName: symbol).frame(width: 28).foregroundStyle(DS.Color.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(DS.Font.body.bold())
                Text(detail).font(DS.Font.body).foregroundStyle(DS.Color.secondaryText)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
