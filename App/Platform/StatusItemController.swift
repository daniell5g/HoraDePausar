import AppKit
import Observation

/// The icon next to Wi‑Fi and battery. Clicking it opens a plain menu of actions;
/// the passage itself is read in the main window.
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let store: DevotionStore
    private weak var coordinator: AppCoordinator?

    init(store: DevotionStore, coordinator: AppCoordinator) {
        self.store = store
        self.coordinator = coordinator
        super.init()

        item.button?.setAccessibilityLabel(Brand.name)
        buildMenu()
        refreshIcon()
        observe()
    }

    /// Rebuilt whenever the app language changes.
    private func buildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false
        menu.addItem(entry(L("Ler a passagem de hoje", "Read today's passage"), action: #selector(readToday)))
        menu.addItem(entry(L("Compartilhar a passagem de hoje…", "Share today's passage…"), action: #selector(shareToday)))
        menu.addItem(.separator())
        menu.addItem(entry(L("Ajustes…", "Settings…"), action: #selector(openSettings), key: ","))
        menu.addItem(.separator())
        menu.addItem(entry("\(L("Encerrar", "Quit")) \(Brand.name)", action: #selector(quit), key: "q"))
        item.menu = menu
    }

    /// Opens the menu as if the icon was clicked (used by the screenshot demo).
    func showMenu() { item.button?.performClick(nil) }

    private func entry(_ title: String, action: Selector, key: String = "") -> NSMenuItem {
        let menuItem = NSMenuItem(title: title, action: action, keyEquivalent: key)
        menuItem.target = self
        return menuItem
    }

    @objc private func readToday() { coordinator?.openMain(section: .today) }
    @objc private func shareToday() { coordinator?.shareToday() }
    @objc private func openSettings() { coordinator?.openSettings() }
    @objc private func quit() { NSApp.terminate(nil) }

    /// Filled sun while today's passage is waiting to be read; outline once read.
    private func refreshIcon() {
        let pending = store.hasPendingToday
        let name = pending ? "sun.horizon.fill" : "sun.horizon"
        let config = NSImage.SymbolConfiguration(pointSize: 15, weight: .medium)
        let image = NSImage(systemSymbolName: name, accessibilityDescription: Brand.name)?.withSymbolConfiguration(config)
        image?.isTemplate = true
        item.button?.image = image
        item.button?.toolTip = pending ? "\(Brand.name) — \(L("sua passagem de hoje está esperando", "today's passage is waiting"))" : Brand.name
    }

    private func observe() {
        withObservationTracking {
            _ = store.hasPendingToday
            _ = Localization.shared.language
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.buildMenu()
                self?.refreshIcon()
                self?.observe()
            }
        }
    }
}
