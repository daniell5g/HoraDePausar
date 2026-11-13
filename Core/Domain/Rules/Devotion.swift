import Foundation

/// Pure state transitions, kept free of UI so they can be unit tested.
public enum Devotion {
    /// How many past days to avoid repeating: a full year, one passage per day.
    public static let noRepeatWindow = 365

    /// `DayKey` of the Monday of the week containing `now`.
    public static func weekKey(now: Date, calendar: Calendar) -> String {
        DayKey.key(for: monday(of: now, calendar: calendar) ?? calendar.startOfDay(for: now), calendar: calendar)
    }

    /// Start of the Monday of the week containing `date`.
    static func monday(of date: Date, calendar: Calendar) -> Date? {
        let day = calendar.startOfDay(for: date)
        let sinceMonday = (calendar.component(.weekday, from: day) + 5) % 7
        return calendar.date(byAdding: .day, value: -sinceMonday, to: day)
    }

    /// The theme of the week, if one was chosen this week (it lapses on Monday).
    public static func activeTheme(_ state: AppState, now: Date, calendar: Calendar) -> PassageTheme? {
        guard let chosen = state.weekTheme, chosen.week == weekKey(now: now, calendar: calendar) else { return nil }
        return chosen.theme
    }

    /// The passages today's draw comes from: the week's theme when one is active, else everything.
    public static func pool(_ all: [Passage], theme: PassageTheme?) -> [Passage] {
        guard let theme else { return all }
        let themed = all.filter { $0.theme == theme }
        return themed.isEmpty ? all : themed
    }

    /// Saves the user's note for a day; blank text removes it.
    public static func setNote(_ state: inout AppState, day: String, text: String) {
        guard let index = state.entries.firstIndex(where: { $0.day == day }) else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        state.entries[index].note = trimmed.isEmpty ? nil : trimmed
    }

    /// Today's entry, drawing a new random passage if today has none yet.
    @discardableResult
    public static func ensureToday<G: RandomNumberGenerator>(_ state: inout AppState, pool: [Passage], now: Date,
                                                             calendar: Calendar, rng: inout G) -> DayEntry? {
        let key = DayKey.key(for: now, calendar: calendar)
        if let existing = state.entries.first(where: { $0.day == key }) { return existing }
        return draw(&state, day: key, pool: pool, now: now, rng: &rng)
    }

    /// Swap today's passage for another random one (keeps it unread).
    @discardableResult
    public static func redrawToday<G: RandomNumberGenerator>(_ state: inout AppState, pool: [Passage], now: Date,
                                                             calendar: Calendar, rng: inout G) -> DayEntry? {
        draw(&state, day: DayKey.key(for: now, calendar: calendar), pool: pool, now: now, rng: &rng)
    }

    /// Draws a fresh, unread passage for `day`, replacing that day's entry if there is one.
    private static func draw<G: RandomNumberGenerator>(_ state: inout AppState, day: String, pool: [Passage],
                                                       now: Date, rng: inout G) -> DayEntry? {
        let recent = state.entries.suffix(noRepeatWindow).map(\.passageID)
        guard let passage = PassagePicker.pick(from: pool, avoiding: recent, using: &rng) else { return nil }
        let entry = DayEntry(day: day, passageID: passage.id, drawnAt: now)
        if let index = state.entries.firstIndex(where: { $0.day == day }) {
            state.entries[index] = entry
        } else {
            state.entries.append(entry)
        }
        return entry
    }

    public static func markRead(_ state: inout AppState, now: Date, calendar: Calendar) {
        let key = DayKey.key(for: now, calendar: calendar)
        guard let index = state.entries.firstIndex(where: { $0.day == key }) else { return }
        if state.entries[index].readAt == nil { state.entries[index].readAt = now }
    }

    public static func isReadToday(_ state: AppState, now: Date, calendar: Calendar) -> Bool {
        let key = DayKey.key(for: now, calendar: calendar)
        return state.entries.first(where: { $0.day == key })?.readAt != nil
    }

    public static func streak(_ state: AppState, now: Date, calendar: Calendar) -> Int {
        Streak.count(readDays: Set(state.entries.filter { $0.readAt != nil }.map(\.day)), today: now, calendar: calendar)
    }
}

extension Devotion {
    /// Monday → Sunday of the current week, the same order as the day chips in Ajustes.
    public static func week(_ state: AppState, now: Date, calendar: Calendar) -> [WeekDay] {
        let today = calendar.startOfDay(for: now)
        guard let monday = monday(of: now, calendar: calendar) else { return [] }
        let readDays = Set(state.entries.filter { $0.readAt != nil }.map(\.day))
        let firstDay = state.entries.map(\.day).min() // "yyyy-MM-dd" sorts like dates
        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: monday) else { return nil }
            let key = DayKey.key(for: date, calendar: calendar)
            let weekday = calendar.component(.weekday, from: date)
            let status: WeekDay.Status
            if readDays.contains(key) {
                status = .read
            } else if date == today {
                status = .today
            } else if date > today {
                status = .upcoming
            } else if let firstDay, key >= firstDay, state.schedule.weekdays.contains(weekday) {
                status = .missed
            } else {
                status = .rest
            }
            return WeekDay(day: key, weekday: weekday, status: status)
        }
    }
}
