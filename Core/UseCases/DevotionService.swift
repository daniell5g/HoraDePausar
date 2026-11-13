import Foundation

/// The app's use cases. Every read and change of the user's devotion goes through here:
/// it applies the pure rules in `Devotion` and saves through the `StateRepository` port.
/// It knows nothing about SwiftUI, AppKit or where the state is stored.
public final class DevotionService {
    public private(set) var state: AppState
    public private(set) var passages: [Passage]
    public var calendar: Calendar
    /// Set when the last save failed (the change stays in memory).
    public private(set) var lastSaveError: Error?

    private let repository: StateRepository
    private var byID: [String: Passage]
    private var rng: any RandomNumberGenerator

    public init(repository: StateRepository, passages: [Passage], calendar: Calendar = .autoupdatingCurrent,
                rng: any RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.repository = repository
        self.passages = passages
        self.calendar = calendar
        self.rng = rng
        byID = Dictionary(passages.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        state = repository.load()
    }

    // MARK: - Queries

    public func passage(id: String) -> Passage? { byID[id] }
    public func entry(day: String) -> DayEntry? { state.entries.first { $0.day == day } }
    public func todayEntry(now: Date = Date()) -> DayEntry? { entry(day: DayKey.key(for: now, calendar: calendar)) }
    public func isReadToday(now: Date = Date()) -> Bool { todayEntry(now: now)?.readAt != nil }
    public func isFavorite(_ passage: Passage) -> Bool { state.favorites.contains(passage.id) }
    public var favorites: [Passage] { state.favorites.compactMap(passage(id:)) }
    public func streak(now: Date = Date()) -> Int { Devotion.streak(state, now: now, calendar: calendar) }
    public func week(now: Date = Date()) -> [WeekDay] { Devotion.week(state, now: now, calendar: calendar) }
    public func nextReminder(after now: Date = Date()) -> Date? { state.schedule.nextFire(after: now, calendar: calendar) }
    public func weekTheme(now: Date = Date()) -> PassageTheme? { Devotion.activeTheme(state, now: now, calendar: calendar) }
    public func dueReminder(now: Date = Date()) -> ReminderEvent? {
        ReminderPolicy.due(state, now: now, alreadyReadToday: isReadToday(now: now), calendar: calendar)
    }

    // MARK: - Commands

    /// Swaps in the same passages in another language. Ids stay the same, so history, favorites and
    /// today's draw carry over unchanged.
    public func replacePassages(_ passages: [Passage]) {
        self.passages = passages
        byID = Dictionary(passages.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Picks the app language; nil follows the Mac.
    public func setLanguage(_ language: AppLanguage?) { mutate { $0.language = language } }

    /// Today's passage, drawing one (from the week's theme, if any) when today has none yet.
    @discardableResult
    public func ensureToday(now: Date = Date()) -> Passage? {
        let pool = drawPool(now: now)
        let entry = mutate { Devotion.ensureToday(&$0, pool: pool, now: now, calendar: calendar, rng: &rng) }
        return entry.flatMap { byID[$0.passageID] }
    }

    /// Swaps today's passage for another random one (unread again).
    public func redrawToday(now: Date = Date()) {
        let pool = drawPool(now: now)
        mutate { Devotion.redrawToday(&$0, pool: pool, now: now, calendar: calendar, rng: &rng) }
    }

    /// Picks (or clears) this week's theme. An unread, unannotated passage of today that is off-theme
    /// is swapped for one of the theme right away; a passage already read or annotated stays.
    public func setWeekTheme(_ theme: PassageTheme?, now: Date = Date()) {
        let week = Devotion.weekKey(now: now, calendar: calendar)
        mutate { $0.weekTheme = theme.map { WeekTheme(theme: $0, week: week) } }
        guard let theme, let today = todayEntry(now: now), today.readAt == nil, today.note == nil,
              let passage = passage(id: today.passageID), passage.theme != theme else { return }
        redrawToday(now: now)
    }

    public func setNote(_ text: String, day: String) { mutate { Devotion.setNote(&$0, day: day, text: text) } }
    public func markReadToday(now: Date = Date()) { mutate { Devotion.markRead(&$0, now: now, calendar: calendar) } }

    public func toggleFavorite(_ passage: Passage) {
        mutate {
            if let i = $0.favorites.firstIndex(of: passage.id) { $0.favorites.remove(at: i) } else { $0.favorites.append(passage.id) }
        }
    }

    public func recordReminder(_ event: ReminderEvent, at date: Date) { mutate { ReminderPolicy.record(event, at: date, in: &$0) } }

    /// Preferences edited from Ajustes (schedule, style, sound, card theme…).
    public func updatePreferences(_ change: (inout AppState) -> Void) { mutate(change) }

    // MARK: - Private

    private func drawPool(now: Date) -> [Passage] { Devotion.pool(passages, theme: weekTheme(now: now)) }

    /// Applies `change`, and saves only when something actually changed.
    @discardableResult
    private func mutate<T>(_ change: (inout AppState) -> T) -> T {
        var copy = state
        let result = change(&copy)
        guard copy != state else { return result }
        state = copy
        do {
            try repository.save(state)
            lastSaveError = nil
        } catch {
            lastSaveError = error
        }
        return result
    }
}
