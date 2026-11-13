import Foundation

public enum ReminderStyle: String, Codable, CaseIterable, Sendable {
    case panel, notification, both

    public func title(in language: AppLanguage) -> String {
        switch (self, language) {
        case (.panel, .pt): "Cartão elegante no canto da tela"
        case (.notification, .pt): "Notificação do macOS"
        case (.both, .pt): "Os dois"
        case (.panel, .en): "Elegant card in the corner of the screen"
        case (.notification, .en): "macOS notification"
        case (.both, .en): "Both"
        }
    }
}

/// One day of devotion: which passage was drawn and when it was read.
public struct DayEntry: Codable, Equatable, Sendable, Identifiable {
    public var day: String
    public var passageID: String
    public var drawnAt: Date
    public var readAt: Date?
    /// The user's own note for that day (never generated text).
    public var note: String?
    public var id: String { day }

    public init(day: String, passageID: String, drawnAt: Date, readAt: Date? = nil, note: String? = nil) {
        self.day = day
        self.passageID = passageID
        self.drawnAt = drawnAt
        self.readAt = readAt
        self.note = note
    }
}

/// Everything the app persists.
public struct AppState: Codable, Equatable, Sendable {
    public var entries: [DayEntry] = []
    public var favorites: [String] = []
    public var schedule = ReminderSchedule()
    public var lastFired: Date?
    public var reminderStyle: ReminderStyle = .panel
    public var playSound = true
    public var cardTheme = "linho"
    /// Theme chosen for one week; only the week it was chosen in draws from it.
    public var weekTheme: WeekTheme?
    public var evening = EveningReminder()
    public var lastNudged: Date?
    /// Language picked in Ajustes; nil follows the Mac's language.
    public var language: AppLanguage?

    public init() {}

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        entries = try c.decodeIfPresent([DayEntry].self, forKey: .entries) ?? []
        favorites = try c.decodeIfPresent([String].self, forKey: .favorites) ?? []
        schedule = try c.decodeIfPresent(ReminderSchedule.self, forKey: .schedule) ?? ReminderSchedule()
        lastFired = try c.decodeIfPresent(Date.self, forKey: .lastFired)
        reminderStyle = try c.decodeIfPresent(ReminderStyle.self, forKey: .reminderStyle) ?? .panel
        playSound = try c.decodeIfPresent(Bool.self, forKey: .playSound) ?? true
        cardTheme = try c.decodeIfPresent(String.self, forKey: .cardTheme) ?? "linho"
        weekTheme = try c.decodeIfPresent(WeekTheme.self, forKey: .weekTheme)
        evening = try c.decodeIfPresent(EveningReminder.self, forKey: .evening) ?? EveningReminder()
        lastNudged = try c.decodeIfPresent(Date.self, forKey: .lastNudged)
        // An unknown value (from a newer version) falls back to following the Mac.
        language = try? c.decodeIfPresent(AppLanguage.self, forKey: .language)
    }
}

/// A theme the user picked for the current week ("Tema da semana").
public struct WeekTheme: Codable, Equatable, Sendable {
    public var theme: PassageTheme
    /// `DayKey` of the Monday that starts the chosen week.
    public var week: String

    public init(theme: PassageTheme, week: String) {
        self.theme = theme
        self.week = week
    }
}
