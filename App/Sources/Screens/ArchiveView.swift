import SwiftUI
import SwiftData
import DesignSystem
import Persistence

struct ArchiveView: View {
    @Environment(AppEnvironment.self) private var env
    @Query(sort: \Thought.archivedAt, order: .reverse) private var all: [Thought]
    private var archived: [Thought] { all.filter { $0.archivedAt != nil } }

    var body: some View {
        List(archived) { t in
            VStack(alignment: .leading) {
                Text(t.title ?? ThoughtExporter.firstLine(t.rawTranscript)).font(DS.Font.body.bold()).lineLimit(2)
                Text(t.createdAt, format: .relative(presentation: .named)).font(DS.Font.caption).foregroundStyle(DS.Color.secondaryText)
            }
            .frame(minHeight: DS.Spacing.minTarget)
            .swipeActions(edge: .leading) {
                Button("Restore") { try? env.store.setArchived(false, t) }.tint(DS.Color.accent)
            }
            .swipeActions(edge: .trailing) {
                Button("Delete", role: .destructive) {
                    let snap = ThoughtSnapshot(t)
                    env.perform("Deleted", { try env.store.delete(t, audio: env.audioStore) }, undo: { _ = try? env.store.restore(snap) })
                }
            }
        }
        .overlay { if archived.isEmpty { Text("Nothing archived").foregroundStyle(DS.Color.secondaryText) } }
        .navigationTitle("Archived")
    }
}
