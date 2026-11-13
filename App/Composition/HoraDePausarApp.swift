import AppKit
import SwiftUI
import HoraDePausarCore

@main
struct HoraDePausarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate

    var body: some Scene {
        // Windows are managed by AppCoordinator; this keeps ⌘, wired to our settings window.
        Settings { EmptyView() }
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button(L("Ajustes…", "Settings…")) { delegate.coordinator?.openSettings() }
                        .keyboardShortcut(",")
                }
            }
    }
}

/// Composition root: the only place that picks concrete implementations and connects the layers.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let options = LaunchOptions.current
        let repository = JSONStateRepository(fileURL: options.stateFile ?? Self.stateFileURL)
        let service = DevotionService(repository: repository, passages: PassageLibrary.bundled(.pt))
        let store = DevotionStore(service: service, library: PassageLibrary.bundled, systemLanguages: Locale.preferredLanguages)
        let coordinator = AppCoordinator(store: store)
        self.coordinator = coordinator
        coordinator.start()
        // Tooling runs are throwaway copies; never let them claim the login item.
        if !options.isToolingRun { LoginItem.followAppLocation() }
        #if DEBUG
        DemoRunner(options: options, coordinator: coordinator).run()
        #endif
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        coordinator?.openMain()
        return true
    }

    /// ~/Library/Application Support/<bundle id>/state.json
    private static var stateFileURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "HoraDePausar", isDirectory: true)
            .appendingPathComponent("state.json")
    }
}
