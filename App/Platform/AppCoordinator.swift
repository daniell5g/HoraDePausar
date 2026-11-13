import AppKit
import SwiftUI
import HoraDePausarCore

/// Wires the macOS surfaces together: the menu-bar item, the reminder card or notification,
/// the scheduler and the windows. Navigation state the views share lives here too.
@Observable
final class AppCoordinator {
    @ObservationIgnored let store: DevotionStore
    @ObservationIgnored private var statusItem: StatusItemController?
    @ObservationIgnored private var engine: ReminderEngine?
    @ObservationIgnored private var notifications: NotificationPoster?
    @ObservationIgnored private let toast = ReminderToastController()
    @ObservationIgnored private let windows = WindowPresenter()
    @ObservationIgnored private var snoozeTimer: Timer?
    /// Section shown in the main window; the menu's "Ler a passagem de hoje" jumps back to Hoje.
    var mainSection: MainSection? = .today
    /// A sheet "Hoje" should open as it appears (Anotar / Decorar); it is cleared once taken.
    @ObservationIgnored var requestedTodaySheet: TodaySheet?

    init(store: DevotionStore) {
        self.store = store
    }

    func start() {
        statusItem = StatusItemController(store: store, coordinator: self)
        notifications = NotificationPoster { [weak self] in self?.openMain(section: .today) }
        engine = ReminderEngine(store: store) { [weak self] in self?.presentReminder(force: false) }
        engine?.start()
    }

    // MARK: - Reminder

    func presentReminder(force: Bool) {
        guard let passage = store.ensureToday() else { return }
        if store.state.playSound { NSSound(named: "Glass")?.play() }
        let style = store.state.reminderStyle
        if force || style != .notification {
            toast.show(passage: passage,
                       theme: CardTheme.calmForSystem,
                       onRead: { [weak self] in self?.openMain(section: .today) },
                       onLater: { [weak self] in self?.snooze() })
        }
        if !force && style != .panel {
            notifications?.post(passage)
        }
    }

    private func snooze() {
        snoozeTimer?.invalidate()
        snoozeTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.store.isReadToday else { return }
                self.presentReminder(force: true)
            }
        }
    }

    // MARK: - Navigation

    func showMenu() { statusItem?.showMenu() }

    func openMain(section: MainSection = .today) {
        store.ensureToday()
        mainSection = section
        show(id: "main", title: Brand.name, size: NSSize(width: 980, height: 660)) { MainWindowView() }
    }

    /// Ajustes live inside the main window, so there is only ever one app window to find.
    func openSettings() { openMain(section: .settings) }

    func shareToday() {
        guard let passage = store.ensureToday() else { return }
        openShare(passage)
    }

    func openShare(_ passage: Passage) {
        windows.close(id: "share")
        show(id: "share", title: L("Compartilhar", "Share"), size: NSSize(width: 900, height: 680)) { ShareComposerView(passage: passage) }
    }

    private func show(id: String, title: String, size: NSSize, @ViewBuilder content: () -> some View) {
        windows.show(id: id, title: title, size: size, resizable: true) {
            LocalizedRoot { content() }
                .tint(Brand.accent)
                .environment(store)
                .environment(self)
        }
    }
}
