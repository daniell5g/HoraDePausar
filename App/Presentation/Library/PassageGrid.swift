import SwiftUI
import HoraDePausarCore

struct PassageGrid: View {
    @Environment(DevotionStore.self) private var store
    @Environment(AppCoordinator.self) private var coordinator
    var passages: [Passage]
    var empty: String

    var body: some View {
        if passages.isEmpty {
            ContentUnavailableView(L("Nada por aqui ainda", "Nothing here yet"), systemImage: "heart", description: Text(empty))
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
                    ForEach(passages) { passage in
                        VStack(alignment: .leading, spacing: 10) {
                            Eyebrow(text: passage.theme.title, size: 9.5)
                            Text(passage.text).font(.serif(15)).lineSpacing(3)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            HStack {
                                Text(passage.reference).font(.system(size: 11.5, weight: .semibold)).foregroundStyle(.secondary)
                                Spacer()
                                Button { store.toggleFavorite(passage) } label: {
                                    Image(systemName: store.isFavorite(passage) ? "heart.fill" : "heart")
                                }
                                .buttonStyle(.borderless)
                                .help(store.isFavorite(passage) ? L("Remover dos favoritos", "Remove from favorites") : L("Favoritar", "Add to favorites"))
                                Button { coordinator.openShare(passage) } label: { Image(systemName: "square.and.arrow.up") }
                                    .buttonStyle(.borderless)
                                    .help(L("Criar imagem", "Create image"))
                            }
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.quaternary.opacity(0.5)))
                    }
                }
                .padding(20)
            }
        }
    }
}
