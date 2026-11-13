#if DEBUG
import AppKit
import HoraDePausarCore

/// Developer tooling behind `LaunchOptions`: opens a surface, saves window snapshots, exports share
/// images. Compiled into Debug builds only, so none of it ships in the app.
struct DemoRunner {
    let options: LaunchOptions
    let coordinator: AppCoordinator

    func run() {
        if let demo = options.demo { open(demo) }
        if let dir = options.exportDir { export(to: dir) }
        if let dir = options.snapshotDir { snapshot(to: dir) }
    }

    private func open(_ demo: String) {
        let coordinator = coordinator
        let cycleDir = options.cycleDir
        let level = options.memorizeLevel
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            switch demo {
            case "menu": coordinator.showMenu()
            case "toast": coordinator.presentReminder(force: true)
            case "settings": coordinator.openSettings()
            case "main": coordinator.openMain()
            case "note": openTodayThenSheet(.note)
            case "memorize": openTodayThenSheet(.memorize(startLevel: level))
            case "journal": coordinator.openMain(section: .journal)
            case "favorites": coordinator.openMain(section: .favorites)
            case "library": coordinator.openMain(section: .library)
            case "main-close":
                // Closes the window again, to check the app drops back to menu-bar only.
                coordinator.openMain()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    NSApp.windows.filter { $0.isVisible && $0.styleMask.contains(.titled) }.forEach { $0.performClose(nil) }
                }
            case "share": coordinator.shareToday()
            case "cycle":
                // Walks the sidebar sections, to watch how the window changes between them.
                coordinator.openMain()
                let order: [MainSection] = [.journal, .favorites, .library, .settings, .today, .settings, .journal]
                for (step, section) in order.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 * Double(step + 1)) { coordinator.mainSection = section }
                    if let dir = cycleDir {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 * Double(step + 1) + 1.0) {
                            recordWindow(to: dir, name: "\(step + 1)-\(section.rawValue)")
                        }
                    }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5 * Double(order.count + 1)) { if cycleDir != nil { exit(0) } }
            default: break
            }
        }
    }

    /// Opens "Hoje" with a sheet over it, the way a person taps Anotar / Decorar.
    private func openTodayThenSheet(_ sheet: TodaySheet) {
        coordinator.requestedTodaySheet = sheet
        coordinator.openMain(section: .today)
    }

    /// Saves every open window as PNG and quits — taken from inside the app, so they never include
    /// anything else on the screen.
    private func snapshot(to dir: URL) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            for (index, window) in NSApp.windows.enumerated() where window.isVisible && window.frame.width > 200 {
                guard let view = window.contentView?.superview ?? window.contentView,
                      let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { continue }
                view.cacheDisplay(in: view.bounds, to: rep)
                try? rep.representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("window-\(index).png"))
            }
            exit(0) // an open sheet would hold up NSApp.terminate
        }
    }

    /// Saves the main window and where its title-bar buttons sit, for the `cycle` demo.
    private func recordWindow(to dir: URL, name: String) {
        guard let window = NSApp.windows.first(where: { $0.isVisible && $0.frame.width > 600 }) else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let close = window.standardWindowButton(.closeButton)
        let origin = close.flatMap { $0.superview?.convert($0.frame, to: nil) } ?? .zero
        func scrollViews(in view: NSView) -> [NSScrollView] {
            (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap(scrollViews(in:))
        }
        let scrollers = window.contentView.map(scrollViews(in:))?
            .filter { ($0.verticalScroller?.isHidden == false) && $0.frame.width > 300 }
            .map { "\($0.scrollerStyle == .overlay ? "overlay" : "legacy")/\($0.scrollerKnobStyle.rawValue)" } ?? []
        let line = "\(name) scrollers=\(scrollers) close=(\(Int(origin.minX)),\(Int(window.frame.height - origin.maxY))) toolbar=\(window.toolbar != nil) style=\(window.toolbarStyle.rawValue) items=\(window.toolbar?.items.count ?? -1) frame=\(Int(window.frame.width))x\(Int(window.frame.height))\n"
        if let handle = try? FileHandle(forWritingTo: dir.appendingPathComponent("metrics.txt")) {
            handle.seekToEndOfFile(); handle.write(Data(line.utf8)); try? handle.close()
        } else {
            try? line.write(to: dir.appendingPathComponent("metrics.txt"), atomically: true, encoding: .utf8)
        }
        guard let view = window.contentView?.superview ?? window.contentView,
              let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        try? rep.representation(using: .png, properties: [:])?.write(to: dir.appendingPathComponent("\(name).png"))
    }

    /// Writes today's share image in every theme and format, then quits.
    private func export(to dir: URL) {
        guard let passage = coordinator.store.ensureToday() else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        for theme in CardTheme.allCases {
            for format in ShareFormat.allCases {
                guard let image = ShareRenderer.image(passage: passage, theme: theme, format: format, typeface: .classic),
                      let data = ShareRenderer.pngData(image) else { continue }
                try? data.write(to: dir.appendingPathComponent("\(theme.rawValue)-\(format.rawValue).png"))
            }
        }
        NSApp.terminate(nil)
    }
}
#endif
