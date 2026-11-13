import Foundation

enum JournalDay {
    /// "Hoje", "Ontem" or "12 de nov. de 2026" (Today, Yesterday or Nov 12, 2026).
    static func title(_ key: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: key) else { return key }
        if Calendar.current.isDateInToday(date) { return L("Hoje", "Today") }
        if Calendar.current.isDateInYesterday(date) { return L("Ontem", "Yesterday") }
        return date.formatted(.dateTime.day().month(.abbreviated).year().locale(Localization.shared.locale))
    }
}
