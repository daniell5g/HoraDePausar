import SwiftUI
import HoraDePausarCore

/// "Tema da semana": the week's draw comes only from the chosen theme until Monday.
struct WeekThemeMenu: View {
    @Environment(DevotionStore.self) private var store

    var body: some View {
        Menu {
            Picker(L("Tema da semana", "Theme of the week"), selection: Binding(get: { store.weekTheme }, set: { store.setWeekTheme($0) })) {
                Text(L("Todos os temas", "All themes")).tag(PassageTheme?.none)
                Divider()
                ForEach(PassageTheme.allCases, id: \.self) { Text($0.title).tag(PassageTheme?.some($0)) }
            }
            .pickerStyle(.inline)
        } label: {
            Label("\(L("Tema da semana", "Theme of the week")): \(store.weekTheme?.title ?? L("todos", "all"))", systemImage: "tag")
                .labelStyle(.titleAndIcon)
        }
        .help(L("Escolha um tema para as passagens desta semana", "Pick a theme for this week's passages"))
    }
}
