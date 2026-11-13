import Foundation

/// A second, gentle reminder in the evening when the day's passage is still unread.
public struct EveningReminder: Codable, Equatable, Sendable {
    public var isEnabled: Bool
    public var hour: Int
    public var minute: Int

    public init(isEnabled: Bool = true, hour: Int = 21, minute: Int = 0) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
    }

    /// True once per day, at or after the evening time, when the daily reminder already appeared
    /// earlier that day and the passage is still unread. Days without a daily reminder never nudge,
    /// and a daily reminder that only showed up after the evening time (Mac asleep) is not repeated.
    public func isDue(now: Date, schedule: ReminderSchedule, lastFired: Date?, lastNudged: Date?,
                      alreadyReadToday: Bool, calendar: Calendar) -> Bool {
        guard isEnabled, !alreadyReadToday,
              let daily = schedule.fireDate(on: now, calendar: calendar),
              let evening = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now),
              evening > daily, now >= evening,
              let lastFired, calendar.isDate(lastFired, inSameDayAs: now), lastFired < evening else { return false }
        if let lastNudged, calendar.isDate(lastNudged, inSameDayAs: now) { return false }
        return true
    }
}
