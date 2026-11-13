import Foundation

/// One day in the "Esta semana" strip of the main window.
public struct WeekDay: Equatable, Sendable, Identifiable {
    public enum Status: Equatable, Sendable {
        /// Passage read that day.
        case read
        /// A reminder day that passed without reading.
        case missed
        /// A past day without a reminder, or before the app was first used (not counted as missed).
        case rest
        /// Today, still waiting.
        case today
        /// Later this week.
        case upcoming
    }

    public let day: String
    /// Calendar weekday: 1 = domingo … 7 = sábado.
    public let weekday: Int
    public let status: Status
    public var id: String { day }

    public func letter(in language: AppLanguage) -> String { Self.letter(weekday: weekday, in: language) }

    /// One-letter name of a `Calendar` weekday (1 = Sunday): D S T Q Q S S or S M T W T F S.
    public static func letter(weekday: Int, in language: AppLanguage) -> String {
        let letters = language == .pt ? ["D", "S", "T", "Q", "Q", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
        return letters[(weekday - 1) % 7]
    }
}
