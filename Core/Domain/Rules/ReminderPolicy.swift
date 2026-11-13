import Foundation

/// Which reminder, if any, is due right now.
public enum ReminderEvent: Equatable, Sendable {
    /// The daily "Hora de pausar" at the scheduled time.
    case daily
    /// The evening nudge, when the day's passage is still unread.
    case evening
}

public enum ReminderPolicy {
    /// The daily reminder wins; the evening one is only considered when the daily one is not due.
    public static func due(_ state: AppState, now: Date, alreadyReadToday: Bool, calendar: Calendar) -> ReminderEvent? {
        if state.schedule.isDue(now: now, lastFired: state.lastFired, alreadyReadToday: alreadyReadToday, calendar: calendar) {
            return .daily
        }
        if state.evening.isDue(now: now, schedule: state.schedule, lastFired: state.lastFired, lastNudged: state.lastNudged,
                               alreadyReadToday: alreadyReadToday, calendar: calendar) {
            return .evening
        }
        return nil
    }

    /// Records that `event` was shown, so it does not repeat the same day.
    public static func record(_ event: ReminderEvent, at date: Date, in state: inout AppState) {
        switch event {
        case .daily: state.lastFired = date
        case .evening: state.lastNudged = date
        }
    }
}
