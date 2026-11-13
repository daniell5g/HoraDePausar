import Foundation

public enum Streak {
    /// Consecutive read days ending today (or yesterday, if today is not read yet).
    public static func count(readDays: Set<String>, today: Date, calendar: Calendar) -> Int {
        var day = today
        if !readDays.contains(DayKey.key(for: day, calendar: calendar)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        var total = 0
        while readDays.contains(DayKey.key(for: day, calendar: calendar)) {
            total += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return total
    }
}
