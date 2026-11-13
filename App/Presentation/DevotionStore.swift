import Foundation
import Observation
import HoraDePausarCore

/// The views' model: exposes the `DevotionService` use cases to SwiftUI as observable state.
/// It holds no rules of its own — every change is a call into the service.
@Observable
final class DevotionStore {
    /// Mirror of the service's state; views observe this.
    private(set) var state: AppState
    /// Bumped on day rollover so views recompute "today".
    private(set) var clockTick = Date()
    @ObservationIgnored private let service: DevotionService
    @ObservationIgnored private let library: (AppLanguage) -> [Passage]
    @ObservationIgnored private let systemLanguages: [String]
    /// Language whose passages the service currently holds.
    @ObservationIgnored private var loadedLanguage: AppLanguage

    /// - Parameters:
    ///   - library: the passages of one language (same ids in every language).
    ///   - systemLanguages: the Mac's preferred languages, used while the user has not picked one.
    init(service: DevotionService, library: @escaping (AppLanguage) -> [Passage], systemLanguages: [String],
         loadedLanguage: AppLanguage = .pt) {
        self.service = service
        self.library = library
        self.systemLanguages = systemLanguages
        self.loadedLanguage = loadedLanguage
        state = service.state
        applyLanguage()
    }

    var calendar: Calendar { service.calendar }
    var passages: [Passage] { _ = state; return service.passages }

    /// The language picked in Ajustes, or the Mac's language until one is picked.
    var language: AppLanguage { state.language ?? AppLanguage.preferred(systemLanguages) }

    // MARK: - Reading

    func passage(id: String) -> Passage? { _ = state; return service.passage(id: id) }
    func entry(day: String) -> DayEntry? { _ = state; return service.entry(day: day) }
    var todayEntry: DayEntry? { observeToday(); return service.todayEntry() }
    var todayPassage: Passage? { todayEntry.flatMap { service.passage(id: $0.passageID) } }
    var isReadToday: Bool { todayEntry?.readAt != nil }
    var hasPendingToday: Bool { todayEntry != nil && !isReadToday }
    var favorites: [Passage] { _ = state; return service.favorites }
    var streak: Int { observeToday(); return service.streak() }
    var week: [WeekDay] { observeToday(); return service.week() }
    var nextReminder: Date? { observeToday(); return service.nextReminder() }
    var weekTheme: PassageTheme? { observeToday(); return service.weekTheme() }
    func isFavorite(_ passage: Passage) -> Bool { _ = state; return service.isFavorite(passage) }

    var cardTheme: CardTheme {
        get { CardTheme(rawValue: state.cardTheme) ?? .linho }
        set { run { $0.updatePreferences { $0.cardTheme = newValue.rawValue } } }
    }

    // MARK: - Actions

    @discardableResult
    func ensureToday() -> Passage? { run { $0.ensureToday() } }
    func redrawToday() { run { $0.redrawToday() } }
    func setWeekTheme(_ theme: PassageTheme?) { run { $0.setWeekTheme(theme) } }
    func setNote(_ text: String, day: String) { run { $0.setNote(text, day: day) } }
    func markReadToday() { run { $0.markReadToday() } }
    func toggleFavorite(_ passage: Passage) { run { $0.toggleFavorite(passage) } }
    func updatePreferences(_ change: (inout AppState) -> Void) { run { $0.updatePreferences(change) } }

    func setLanguage(_ language: AppLanguage) {
        run { $0.setLanguage(language) }
        applyLanguage()
    }

    /// Checks the schedule and records the reminder that is due, if any.
    func takeDueReminder(now: Date = Date()) -> ReminderEvent? {
        run { service in
            guard let event = service.dueReminder(now: now) else { return nil }
            service.recordReminder(event, at: now)
            return event
        }
    }

    func dayChanged() { clockTick = Date() }

    // MARK: - Private

    /// Loads the passages and sets the interface language that the state asks for.
    private func applyLanguage() {
        let wanted = language
        if wanted != loadedLanguage {
            service.replacePassages(library(wanted))
            loadedLanguage = wanted
        }
        Localization.shared.language = wanted
    }

    /// Reads that depend on the date also refresh on day rollover.
    private func observeToday() { _ = state; _ = clockTick }

    /// Runs a use case, then republishes the state when it changed.
    private func run<T>(_ action: (DevotionService) -> T) -> T {
        let result = action(service)
        if service.state != state { state = service.state }
        if let error = service.lastSaveError { NSLog("Hora de Pausar: failed to save state: \(error)") }
        return result
    }
}
