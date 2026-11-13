import SwiftUI
import HoraDePausarCore

struct LibraryView: View {
    @Environment(DevotionStore.self) private var store
    @State private var filter: PassageTheme?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(L("Todas", "All"), selected: filter == nil) { filter = nil }
                    ForEach(PassageTheme.allCases, id: \.self) { theme in
                        chip(theme.title, selected: filter == theme) { filter = theme }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            PassageGrid(passages: store.passages.filter { filter == nil || $0.theme == filter }, empty: "")
        }
        .navigationTitle(L("Passagens", "Passages"))
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: selected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
        .tint(selected ? Brand.accent : nil)
    }
}
