import Foundation

/// Language of the app's text and of the Bible passages it shows.
public enum AppLanguage: String, Codable, CaseIterable, Sendable {
    case pt, en

    /// First supported language in the Mac's preferred list; English when none matches.
    public static func preferred(_ languages: [String]) -> AppLanguage {
        for code in languages {
            if code.hasPrefix("pt") { return .pt }
            if code.hasPrefix("en") { return .en }
        }
        return .en
    }

    /// Name of the language in itself, for the picker.
    public var nativeName: String {
        switch self {
        case .pt: "Português"
        case .en: "English"
        }
    }
}
