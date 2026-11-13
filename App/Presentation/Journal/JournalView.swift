import SwiftUI
import HoraDePausarCore

struct JournalView: View {
    @Environment(DevotionStore.self) private var store
    @Environment(AppCoordinator.self) private var coordinator
    @State private var editing: DayEntry?

    var body: some View {
        let entries = Array(store.state.entries.reversed())
        Group {
            if entries.isEmpty {
                ContentUnavailableView(L("Seu diário começa hoje", "Your journal starts today"), systemImage: "calendar",
                                       description: Text(L("Cada pausa fica registrada aqui.", "Every pause is kept here.")))
            } else {
                List(entries) { entry in
                    if let passage = store.passage(id: entry.passageID) {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: entry.readAt != nil ? "checkmark.circle.fill" : "circle.dashed")
                                .foregroundStyle(entry.readAt != nil ? Brand.accent : .secondary)
                                .font(.system(size: 16))
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(JournalDay.title(entry.day)).font(.system(size: 12, weight: .semibold))
                                    Text("·").foregroundStyle(.secondary)
                                    Text(passage.reference).font(.system(size: 12)).foregroundStyle(.secondary)
                                }
                                Text(passage.text).font(.serif(14)).lineLimit(2)
                                if let note = entry.note {
                                    Label(note, systemImage: "square.and.pencil")
                                        .font(.system(size: 12.5))
                                        .foregroundStyle(.secondary)
                                        .lineLimit(4)
                                        .padding(.top, 2)
                                }
                            }
                            Spacer()
                            Button { editing = entry } label: { Image(systemName: "square.and.pencil") }
                                .buttonStyle(.borderless)
                                .help(entry.note == nil ? L("Anotar", "Add a note") : L("Editar anotação", "Edit note"))
                            Button { coordinator.openShare(passage) } label: { Image(systemName: "square.and.arrow.up") }
                                .buttonStyle(.borderless)
                                .help(L("Criar imagem", "Create image"))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle(L("Diário", "Journal"))
        .sheet(item: $editing) { entry in
            if let passage = store.passage(id: entry.passageID) {
                NoteEditor(entry: entry, passage: passage)
            }
        }
    }
}
