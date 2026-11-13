import AppKit
import HoraDePausarCore

/// Checks the schedule every 20 s and on wake / clock / day changes.
/// Which reminder is due is decided by `ReminderPolicy` (at most one daily reminder, plus at most
/// one evening reminder while the passage is unread); this class only supplies the moments to check.
final class ReminderEngine {
    private let store: DevotionStore
    private let onFire: () -> Void
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []
    private var lastDayKey: String

    init(store: DevotionStore, onFire: @escaping () -> Void) {
        self.store = store
        self.onFire = onFire
        lastDayKey = DayKey.key(for: Date(), calendar: store.calendar)
    }

    func start() {
        let timer = Timer(timeInterval: 20, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        timer.tolerance = 5
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer

        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        })
        observers.append(workspace.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        })
        for name in [Notification.Name.NSCalendarDayChanged, .NSSystemClockDidChange, .NSSystemTimeZoneDidChange] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            })
        }
        // Give the menu bar a moment to settle before a launch-time reminder.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.tick() }
    }

    func tick(now: Date = Date()) {
        let key = DayKey.key(for: now, calendar: store.calendar)
        if key != lastDayKey {
            lastDayKey = key
            store.dayChanged()
        }
        if store.takeDueReminder(now: now) != nil { onFire() }
    }
}
