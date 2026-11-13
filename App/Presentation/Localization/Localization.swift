import Foundation
import Observation
import SwiftUI
import HoraDePausarCore

/// The language the interface is drawn in. Views read it through `L(_:_:)`, so a change in
/// Ajustes redraws every open window at once.
@Observable
final class Localization {
    static let shared = Localization()
    var language: AppLanguage = .pt

    var locale: Locale { Locale(identifier: language == .pt ? "pt_BR" : "en_US") }
    var edition: BibleEdition { PassageLibrary.edition(for: language) }
}

/// The Portuguese or the English text, following the app language.
func L(_ pt: String, _ en: String) -> String {
    Localization.shared.language == .pt ? pt : en
}

extension PassageTheme {
    var title: String { title(in: Localization.shared.language) }
}

extension ReminderStyle {
    var title: String { title(in: Localization.shared.language) }
}

extension WeekDay {
    var letter: String { letter(in: Localization.shared.language) }
}

/// Hands the app language's locale to a window's views (date pickers, formatted dates), and
/// redraws them when the language changes.
struct LocalizedRoot<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content.environment(\.locale, Localization.shared.locale)
    }
}
