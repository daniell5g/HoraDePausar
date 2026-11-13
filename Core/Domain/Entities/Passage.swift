import Foundation

/// Devotional theme of a curated passage. Drives the chip label and the library filter.
public enum PassageTheme: String, Codable, CaseIterable, Sendable {
    case paz, forca, confianca, gratidao, esperanca, amor, sabedoria, oracao

    public func title(in language: AppLanguage) -> String {
        switch language {
        case .pt:
            switch self {
            case .paz: "Paz"
            case .forca: "Força"
            case .confianca: "Confiança"
            case .gratidao: "Gratidão"
            case .esperanca: "Esperança"
            case .amor: "Amor"
            case .sabedoria: "Sabedoria"
            case .oracao: "Oração"
            }
        case .en:
            switch self {
            case .paz: "Peace"
            case .forca: "Strength"
            case .confianca: "Trust"
            case .gratidao: "Gratitude"
            case .esperanca: "Hope"
            case .amor: "Love"
            case .sabedoria: "Wisdom"
            case .oracao: "Prayer"
            }
        }
    }
}

public struct Passage: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let reference: String
    public let text: String
    public let theme: PassageTheme

    public init(id: String, reference: String, text: String, theme: PassageTheme) {
        self.id = id
        self.reference = reference
        self.text = text
        self.theme = theme
    }
}
