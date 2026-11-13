import Foundation

/// The user's daily reminder: a time of day and the weekdays it applies to.
/// At most one reminder per calendar day.
public struct ReminderSchedule: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var hour: Int
    public var minute: Int
    /// `Calendar` weekday numbers: 1 = domingo … 7 = sábado.
    public var weekdays: Set<Int>

    public init(isEnabled: Bool = true, hour: Int = 7, minute: Int = 0, weekdays: Set<Int> = Set(1...7)) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }

    /// The reminder moment on the given day, or nil when the day is not scheduled.
    public func fireDate(on day: Date, calendar: Calendar) -> Date? {
        guard isEnabled, weekdays.contains(calendar.component(.weekday, from: day)) else { return nil }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    /// First reminder moment strictly after `date`.
    public func nextFire(after date: Date, calendar: Calendar) -> Date? {
        guard isEnabled, !weekdays.isEmpty else { return nil }
        let start = calendar.startOfDay(for: date)
        for offset in 0...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: start),
                  let fire = fireDate(on: day, calendar: calendar) else { continue }
            if fire > date { return fire }
        }
        return nil
    }

    /// True when today's reminder time has passed, it has not fired today, and today's passage
    /// was not already read. Covers a Mac that was asleep at the exact minute: it fires on wake.
    public func isDue(now: Date, lastFired: Date?, alreadyReadToday: Bool, calendar: Calendar) -> Bool {
        guard !alreadyReadToday, let fire = fireDate(on: now, calendar: calendar), now >= fire else { return false }
        if let lastFired, calendar.isDate(lastFired, inSameDayAs: now) { return false }
        return true
    }
}
