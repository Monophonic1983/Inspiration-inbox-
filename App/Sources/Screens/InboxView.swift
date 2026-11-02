import SwiftUI
import SwiftData
import DesignSystem
import ModelStore
import Persistence

struct InboxView: View {
    let ns: Namespace.ID
    let crystalID: UUID?
    let startCapture: () -> Void

    @Environment(AppEnvironment.self) private var env
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Thought.createdAt, order: .reverse) private var all: [Thought]
    @State private var search = ""
    @State private var showSettings = false
    @State private var pullArmed = false

    private var visible: [Thought] {
        let live = all.filter { $0.archivedAt == nil }
        let q = SearchNormalizer.normalize(search)
        let matched = q.isEmpty ? live : live.filter {
            SearchNormalizer.normalize($0.rawTranscript).contains(q)
                || SearchNormalizer.normalize($0.cleanedText ?? "").contains(q)
                || SearchNormalizer.normalize($0.title ?? "").contains(q)
        }
        // Newest first; pinned thoughts stay on top.
        return matched.filter(\.isPinned) + matched.filter { !$0.isPinned }
    }

    var body: some View {
        List {
            ModelPromptCard()
                .listRowSeparator(.hidden).listRowBackground(Color.clear)
            ForEach(visible) { thought in
                NavigationLink(value: thought) {
                    ThoughtCard(thought: thought, ns: ns, matched: !reduceMotion && crystalID == thought.id)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: DS.Spacing.xs, leading: DS.Spacing.m, bottom: DS.Spacing.xs, trailing: DS.Spacing.m))
                .swipeActions(edge: .leading) { pinButton(thought) }
                .swipeActions(edge: .trailing) { archiveButton(thought) }
                .contextMenu { quickActions(thought) }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Color.background)
        .overlay { if all.isEmpty { EmptyInbox() } }
        .navigationTitle("Inbox")
        .searchable(text: $search, prompt: Text("Search thoughts"))
        .navigationDestination(for: Thought.self) { ThoughtDetailView(thought: $0) }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showSettings = true } label: { Image(systemName: "gearshape") }
                    .frame(minWidth: DS.Spacing.minTarget, minHeight: DS.Spacing.minTarget)
                    .accessibilityLabel(Text("Settings"))
                    .accessibilityIdentifier("settingsButton")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: startCapture) { Orb(level: 0, isActive: false).frame(width: 28, height: 28) }
                    .frame(minWidth: DS.Spacing.minTarget, minHeight: DS.Spacing.minTarget)
                    .accessibilityLabel(Text("New thought"))
                    .accessibilityIdentifier("orbButton")
            }
        }
        .sheet(isPresented: $showSettings) { SettingsView() }
        // Pull down past the top to start a capture; the orb button is the alternative.
        .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, offset in
            pullArmed = offset < -90
        }
        .onScrollPhaseChange { _, new in
            if pullArmed, new != .interacting { pullArmed = false; Haptic.start.play(); startCapture() }
        }
    }

    private func pinButton(_ t: Thought) -> some View {
        Button {
            let was = t.isPinned
            env.perform(was ? "Unpinned" : "Pinned", { try env.store.setPinned(!was, t) }, undo: { try? env.store.setPinned(was, t) })
        } label: { Label(t.isPinned ? "Unpin" : "Pin", systemImage: t.isPinned ? "pin.slash" : "pin") }
            .tint(DS.Color.accent)
    }

    private func archiveButton(_ t: Thought) -> some View {
        Button {
            env.perform("Archived", { try env.store.setArchived(true, t) }, undo: { try? env.store.setArchived(false, t) })
        } label: { Label("Archive", systemImage: "archivebox") }
            .tint(.gray)
    }

    @ViewBuilder private func quickActions(_ t: Thought) -> some View {
        ShareLink(item: ThoughtExporter.markdown(t)) { Label("Share", systemImage: "square.and.arrow.up") }
        Button { UIPasteboard.general.string = t.cleanedText ?? t.rawTranscript } label: { Label("Copy", systemImage: "doc.on.doc") }
        Button(role: .destructive) {
            let snapshot = ThoughtSnapshot(t)
            env.perform("Deleted", { try env.store.delete(t, audio: env.audioStore) }, undo: { _ = try? env.store.restore(snapshot) })
        } label: { Label("Delete", systemImage: "trash") }
    }
}

struct EmptyInbox: View {
    var body: some View {
        VStack(spacing: DS.Spacing.l) {
            Orb(level: 0, isActive: false).frame(width: 120, height: 120)
            Text("Press the Action Button and say what's on your mind.")
                .font(DS.Font.body).foregroundStyle(DS.Color.secondaryText)
                .multilineTextAlignment(.center).padding(.horizontal, DS.Spacing.xl)
        }
        .accessibilityElement(children: .combine)
    }
}

/// First-launch prompt to download the on-device AI model (FR-14). Capture works while it downloads.
struct ModelPromptCard: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if let model = env.catalog.structuringModel(forRAMGB: DeviceCapabilities.physicalRAMGB) {
            switch env.modelStore.states[model.id] ?? .notInstalled {
            case .installed: EmptyView()
            case .downloading(let progress):
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Downloading on-device AI").font(DS.Font.title)
                    ProgressView(value: progress)
                    Text("You can keep capturing thoughts while this downloads.").font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
                }.dsCard()
            case .notInstalled, .failed:
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Turn on on-device AI").font(DS.Font.title)
                    Text("Download \(model.displayName) (\(ByteCountFormatter.string(fromByteCount: model.totalBytes, countStyle: .file))) to structure thoughts without the internet.")
                        .font(DS.Font.body).foregroundStyle(DS.Color.secondaryText)
                    Button("Download") { env.downloadAndRetry(model) }
                        .buttonStyle(.borderedProminent).tint(DS.Color.accent)
                        .frame(minHeight: DS.Spacing.minTarget)
                }.dsCard()
            }
        }
    }
}
