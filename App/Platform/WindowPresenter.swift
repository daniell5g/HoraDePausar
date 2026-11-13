import AppKit
import SwiftUI

/// Opens the app's windows (one per id), brings them to the front, and switches the app between
/// menu-bar-only and a regular app (Dock icon, ⌘Tab) while a window is open.
final class WindowPresenter: NSObject {
    private var windows: [String: NSWindow] = [:]

    func close(id: String) {
        windows[id]?.close()
        windows[id] = nil
    }

    func show(id: String, title: String, size: NSSize, resizable: Bool, content: () -> some View) {
        if let window = windows[id] {
            bringToFront(window)
            return
        }
        let window = NSWindow(contentViewController: NSHostingController(rootView: content()))
        window.title = title
        window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        if resizable { window.styleMask.insert(.resizable) }
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.setContentSize(size)
        window.center()
        window.setFrameAutosaveName("HoraDePausar.\(id)")
        if !resizable, window.contentRect(forFrameRect: window.frame).size != size {
            // A fixed-size window only remembers where it was, never an older size.
            let top = window.frame.maxY
            window.setContentSize(size)
            window.setFrameTopLeftPoint(NSPoint(x: window.frame.minX, y: top))
        }
        windows[id] = window
        NotificationCenter.default.addObserver(self, selector: #selector(windowWillClose(_:)),
                                               name: NSWindow.willCloseNotification, object: window)
        bringToFront(window)
    }

    /// A menu-bar-only app is never "the app in use", and since macOS 14 `activate()` is only a request
    /// the system may turn down — so the window could open behind whatever had focus. While one of our
    /// windows is open the app becomes a regular app (Dock icon, ⌘Tab), which the system activates reliably.
    private func bringToFront(_ window: NSWindow) {
        if NSApp.activationPolicy() != .regular { NSApp.setActivationPolicy(.regular) }
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate()
        // Ask again once the status menu has finished closing (focus otherwise snaps back to the
        // previous app), and put the window on top even if activation is still refused.
        DispatchQueue.main.async {
            NSApp.activate()
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
        }
    }

    /// Back to a menu-bar-only app once the last window is gone.
    @objc private func windowWillClose(_ note: Notification) {
        let closing = note.object as? NSWindow
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let stillOpen = self.windows.values.contains { $0 !== closing && ($0.isVisible || $0.isMiniaturized) }
            if !stillOpen, NSApp.activationPolicy() != .accessory { NSApp.setActivationPolicy(.accessory) }
        }
    }
}
