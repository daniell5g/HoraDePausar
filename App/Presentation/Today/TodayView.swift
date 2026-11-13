import SwiftUI
import HoraDePausarCore

/// "Hoje": today's passage, the Amém button and the actions on it.
struct TodayView: View {
    @Environment(DevotionStore.self) private var store
    @Environment(AppCoordinator.self) private var coordinator
    @Environment(\.colorScheme) private var colorScheme
    @State private var sheet: TodaySheet?
    private var theme: CardTheme { .calm(colorScheme) }

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, animated: true)
                .ignoresSafeArea()
            if let passage = store.todayPassage {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Eyebrow(text: Date().formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Localization.shared.locale)),
                                color: theme.secondaryInk, size: 11)
                        if let weekTheme = store.weekTheme {
                            Eyebrow(text: "\(L("Tema da semana", "Theme of the week")) · \(weekTheme.title)", color: theme.accent, size: 9.5)
                        }
                    }
                    Text(passage.text)
                        .font(.serif(passage.text.count > 320 ? 24 : passage.text.count > 200 ? 28 : 34))
                        .lineSpacing(8)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(theme.ink)
                        .minimumScaleFactor(0.7) // long passages shrink instead of being cut off
                        .layoutPriority(1)
                        .frame(maxWidth: 620)
                        .id(passage.id)
                        .transition(.blurReplace)
                    HStack(spacing: 12) {
                        Rectangle().fill(theme.accent).frame(width: 28, height: 1)
                        Eyebrow(text: passage.reference, color: theme.accent, size: 12)
                        Rectangle().fill(theme.accent).frame(width: 28, height: 1)
                    }
                    // No invented prayer: only an invitation that fits every passage.
                    Text(L("Medite sobre a palavra de hoje.", "Meditate on today's word."))
                        .font(.serif(16))
                        .italic()
                        .foregroundStyle(theme.secondaryInk)
                    if let note = store.todayEntry?.note {
                        Button { sheet = .note } label: {
                            Label(note, systemImage: "square.and.pencil")
                                .font(.system(size: 13))
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                                .foregroundStyle(theme.secondaryInk)
                                .frame(maxWidth: 520)
                        }
                        .buttonStyle(.plain)
                        .help(L("Editar anotação", "Edit note"))
                    }
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring) { store.markReadToday() }
                        } label: {
                            Label(store.isReadToday ? L("Lida hoje", "Read today") : L("Amém · li e orei", "Amen · read and prayed"),
                                  systemImage: store.isReadToday ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 14, weight: .semibold))
                                .padding(.horizontal, 10)
                        }
                        .buttonStyle(AmenButtonStyle(theme: theme, done: store.isReadToday))
                        .disabled(store.isReadToday)
                        IconGlassButton(symbol: "square.and.arrow.up", help: L("Criar imagem", "Create image")) { coordinator.openShare(passage) }
                        IconGlassButton(symbol: store.isFavorite(passage) ? "heart.fill" : "heart", help: store.isFavorite(passage) ? L("Remover dos favoritos", "Remove from favorites") : L("Favoritar", "Add to favorites")) { store.toggleFavorite(passage) }
                        IconGlassButton(symbol: "square.and.pencil", help: L("Anotar", "Add a note")) { sheet = .note }
                        IconGlassButton(symbol: "eye.slash", help: L("Decorar", "Memorize")) { sheet = .memorize() }
                    }
                    .padding(.top, 6)
                }
                .padding(48)
            }
        }
        .environment(\.colorScheme, theme.isLight ? .light : .dark)
        .navigationTitle(L("Hoje", "Today"))
        .onAppear {
            // A sheet asked for before "Hoje" opened (see `AppCoordinator.requestedTodaySheet`).
            guard let request = coordinator.requestedTodaySheet else { return }
            coordinator.requestedTodaySheet = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { sheet = request }
        }
        .sheet(item: $sheet) { which in
            if let entry = store.todayEntry, let passage = store.todayPassage {
                switch which {
                case .note: NoteEditor(entry: entry, passage: passage)
                case .memorize(let startLevel): MemorizeView(passage: passage, startLevel: startLevel)
                }
            }
        }
    }
}

/// Sheets opened over "Hoje".
enum TodaySheet: Identifiable, Hashable {
    case note
    /// "Decorar", starting `startLevel` steps in (0 = full text).
    case memorize(startLevel: Int = 0)

    var id: String {
        switch self {
        case .note: "note"
        case .memorize: "memorize"
        }
    }
}
