import SwiftUI
import HoraDePausarCore

enum MainSection: String, CaseIterable, Identifiable, Hashable {
    case today, journal, favorites, library, settings
    /// The reading sections; Ajustes sits apart at the end of the sidebar.
    static let reading: [MainSection] = [.today, .journal, .favorites, .library]
    var id: String { rawValue }
    var title: String {
        switch self {
        case .today: L("Hoje", "Today")
        case .journal: L("Diário", "Journal")
        case .favorites: L("Favoritos", "Favorites")
        case .library: L("Passagens", "Passages")
        case .settings: L("Ajustes", "Settings")
        }
    }
    var symbol: String {
        switch self {
        case .today: "sun.horizon"
        case .journal: "calendar"
        case .favorites: "heart"
        case .library: "book.closed"
        case .settings: "gearshape"
        }
    }
}

struct MainWindowView: View {
    @Environment(DevotionStore.self) private var store
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        @Bindable var coordinator = coordinator
        NavigationSplitView {
            List(selection: $coordinator.mainSection) {
                ForEach(MainSection.reading) { item in
                    Label(item.title, systemImage: item.symbol).tag(item)
                }
                Section {
                    Label(MainSection.settings.title, systemImage: MainSection.settings.symbol).tag(MainSection.settings)
                }
            }
            .navigationSplitViewColumnWidth(min: 170, ideal: 190)
            .safeAreaInset(edge: .bottom) { WeekStrip() }
        } detail: {
            switch coordinator.mainSection ?? .today {
            case .today: TodayView()
            case .journal: JournalView()
            case .favorites: PassageGrid(passages: store.favorites, empty: L("Toque no coração de uma passagem para guardá-la aqui.", "Click the heart on a passage to keep it here."))
            case .library: LibraryView()
            case .settings: SettingsView()
            }
        }
        .frame(minWidth: 900, minHeight: 620)
        .onAppear { store.ensureToday() }
    }
}
