import SwiftUI
import DesignSystem
import Persistence

struct ThoughtCard: View {
    let thought: Thought
    let ns: Namespace.ID
    let matched: Bool

    private var title: String { thought.title ?? ThoughtExporter.firstLine(thought.rawTranscript) }
    private var processing: Bool { thought.status == .captured }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.isEmpty ? String(localized: "Empty thought") : title)
                    .font(DS.Font.title).lineLimit(2)
                    .shimmer(processing)
                Spacer(minLength: DS.Spacing.s)
                if thought.isPinned { Image(systemName: "pin.fill").foregroundStyle(DS.Color.accent).accessibilityLabel(Text("Pinned")) }
            }
            if let body = thought.summary ?? thought.cleanedText, !body.isEmpty {
                Text(body).font(DS.Font.body).foregroundStyle(DS.Color.secondaryText).lineLimit(2)
            } else if thought.status == .failed {
                Text(thought.rawTranscript).font(DS.Font.body).foregroundStyle(DS.Color.secondaryText).lineLimit(2)
            }
            HStack(spacing: DS.Spacing.s) {
                if let kind = thought.kind { Text(kind.rawValue.capitalized) }
                Text(thought.createdAt, format: .relative(presentation: .named))
                if thought.status == .failed { Label("Couldn't structure", systemImage: "exclamationmark.circle") }
                else if processing { Text("Structuring…") }
            }
            .font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
        }
        .dsCard()
        .modifier(MatchedCard(id: thought.id, ns: ns, enabled: matched))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("thoughtCard")
    }
}

/// Crystallize transition: the capture card flies into its Inbox slot. Reduce Motion swaps it for a cross-fade.
struct MatchedCard: ViewModifier {
    let id: UUID
    let ns: Namespace.ID
    let enabled: Bool
    func body(content: Content) -> some View {
        if enabled { content.matchedGeometryEffect(id: id, in: ns) } else { content }
    }
}
