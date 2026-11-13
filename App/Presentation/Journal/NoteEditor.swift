import SwiftUI
import HoraDePausarCore

/// The user's own words about one day's passage, kept in the Diário.
struct NoteEditor: View {
    @Environment(DevotionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let entry: DayEntry
    let passage: Passage
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Anotação", "Note")).font(.system(size: 17, weight: .semibold))
                Text("\(JournalDay.title(entry.day)) · \(passage.reference)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Text(passage.text)
                .font(.serif(14))
                .foregroundStyle(.secondary)
                .lineLimit(3)
            TextEditor(text: $text)
                .font(.system(size: 14))
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.quaternary.opacity(0.6)))
                .focused($focused)
                .frame(minHeight: 140)
            HStack {
                if entry.note != nil {
                    Button(L("Apagar", "Delete"), role: .destructive) { save("") }
                }
                Spacer()
                Button(L("Cancelar", "Cancel")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(L("Salvar", "Save")) { save(text) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .tint(CardTheme.calmForSystem.accent)
            }
        }
        .padding(22)
        .frame(width: 480)
        .onAppear {
            text = entry.note ?? ""
            focused = true
        }
    }

    private func save(_ value: String) {
        store.setNote(value, day: entry.day)
        dismiss()
    }
}
