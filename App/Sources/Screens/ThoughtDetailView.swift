import SwiftUI
import DesignSystem
import Persistence

struct ThoughtDetailView: View {
    @Bindable var thought: Thought
    @Environment(AppEnvironment.self) private var env
    @State private var showRaw = false
    @State private var confirmReprocess = false

    private var structured: Bool { thought.status == .ready }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                rawChip
                if showRaw || !structured { rawBody } else { structuredBody }
                if thought.status != .ready { statusFooter }
            }
            .padding(DS.Spacing.m)
        }
        .background(DS.Color.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: ThoughtExporter.markdown(thought)) { Label("Share as Markdown", systemImage: "number") }
                    ShareLink(item: ThoughtExporter.plainText(thought)) { Label("Share as text", systemImage: "text.alignleft") }
                    Button { UIPasteboard.general.string = thought.cleanedText ?? thought.rawTranscript } label: { Label("Copy", systemImage: "doc.on.doc") }
                    if structured { Button { requestReprocess() } label: { Label("Structure again", systemImage: "sparkles") } }
                } label: { Image(systemName: "ellipsis.circle") }
                    .frame(minWidth: DS.Spacing.minTarget, minHeight: DS.Spacing.minTarget)
                    .accessibilityLabel(Text("More"))
            }
        }
        .confirmationDialog("Replace your edits?", isPresented: $confirmReprocess, titleVisibility: .visible) {
            Button("Replace with new result", role: .destructive) { Task { await env.queue.reprocess(thought, overwriteUserEdits: true) } }
            Button("Keep my edits", role: .cancel) { }
        } message: { Text("You edited this thought. Structuring it again will overwrite the title and text you changed.") }
    }

    private var rawChip: some View {
        Button { withAnimation(DS.Motion.snappy) { showRaw.toggle() } } label: {
            Label(showRaw ? "Structured" : "Raw", systemImage: showRaw ? "sparkles" : "text.quote")
                .font(DS.Font.caption.bold())
                .padding(.horizontal, DS.Spacing.m).frame(minHeight: DS.Spacing.minTarget)
                .background(DS.Color.card, in: Capsule())
        }
        .buttonStyle(.plain)
        .opacity(structured ? 1 : 0.4)
        .disabled(!structured)
        .accessibilityIdentifier("rawChip")
    }

    private var rawBody: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s) {
            Text("What you said").font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
            Text(thought.rawTranscript.isEmpty ? String(localized: "No words were recognised.") : thought.rawTranscript)
                .font(DS.Font.body).textSelection(.enabled)
        }
    }

    @ViewBuilder private var structuredBody: some View {
        TextField("Title", text: Binding(get: { thought.title ?? "" }, set: { try? env.store.edit(thought, title: $0) }), axis: .vertical)
            .font(DS.Font.largeTitle)
        if let s = thought.summary, !s.isEmpty { Text(s).font(DS.Font.body).foregroundStyle(DS.Color.secondaryText) }
        HStack {
            if let kind = thought.kind { chip(kind.rawValue.capitalized) }
            ForEach(thought.tags, id: \.self) { chip("#\($0)") }
        }
        TextEditor(text: Binding(get: { thought.cleanedText ?? "" }, set: { try? env.store.edit(thought, cleanedText: $0) }))
            .font(DS.Font.body).frame(minHeight: 160).scrollContentBackground(.hidden)
            .padding(DS.Spacing.s).background(DS.Color.card, in: RoundedRectangle(cornerRadius: DS.Radius.card))
        if !thought.actionItems.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Action items").font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
                ForEach(Array(thought.actionItems.enumerated()), id: \.offset) { index, item in
                    Button {
                        try? env.store.toggle(actionItemAt: index, of: thought)
                        Haptic.triage.play()
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: DS.Spacing.s) {
                            Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle").foregroundStyle(DS.Color.accent)
                            Text(item.text).strikethrough(item.isDone).foregroundStyle(item.isDone ? DS.Color.secondaryText : DS.Color.primaryText)
                            Spacer()
                        }
                        .frame(minHeight: DS.Spacing.minTarget)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(item.isDone ? .isSelected : [])
                }
            }
        }
    }

    @ViewBuilder private var statusFooter: some View {
        switch thought.status {
        case .captured:
            Text("Saved. It will be structured when an on-device model is available.").font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
        case .failed:
            VStack(alignment: .leading, spacing: DS.Spacing.s) {
                Text("Couldn't structure this thought. Your words are safe.").font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
                Button("Try again") { Task { await env.queue.reprocess(thought, overwriteUserEdits: false) } }
                    .frame(minHeight: DS.Spacing.minTarget)
            }
        case .ready: EmptyView()
        }
    }

    private func chip(_ text: String) -> some View {
        Text(text).font(DS.Font.caption).padding(.horizontal, DS.Spacing.s).padding(.vertical, DS.Spacing.xs)
            .background(DS.Color.card, in: Capsule())
    }

    /// Re-processing never overwrites the user's edits without confirmation.
    private func requestReprocess() {
        if thought.userEditedAt != nil { confirmReprocess = true }
        else { Task { await env.queue.reprocess(thought, overwriteUserEdits: false) } }
    }
}
