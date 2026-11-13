import Foundation

/// Where one language's passages come from, and the credit they must carry.
public struct BibleEdition: Sendable {
    /// Full credit shown in Ajustes.
    public let attribution: String
    /// Printed on every share image: work name plus license.
    public let shortAttribution: String
    public let licenseTitle: String
    public let licenseURL: URL
    public let sourceTitle: String
    public let sourceURL: URL
    public let changesNote: String
}

public enum PassageLibrary {
    private final class BundleToken {}

    /// Bíblia Livre. The translators' site and the LICENCA.md of the official repository
    /// (github.com/blivre/BibliaLivre) license it under CC BY 3.0 BR, which requires credit to the
    /// authors, the version date, and the license URI with every copy.
    /// (eBible's porbr2018 file says "4.0 Brasil", but CC 4.0 has no national ports.)
    public static let portuguese = BibleEdition(
        attribution: "Bíblia Livre (BLIVRE), versão de fevereiro de 2018 · © Diego Santos, Mario Sérgio e Marco Teles · Licença Creative Commons Atribuição 3.0 Brasil (CC BY 3.0 BR)",
        shortAttribution: "Bíblia Livre (BLIVRE) · CC BY 3.0 BR",
        licenseTitle: "Licença CC BY 3.0 BR",
        licenseURL: URL(string: "https://creativecommons.org/licenses/by/3.0/br/")!,
        sourceTitle: "Site da Bíblia Livre",
        sourceURL: URL(string: "https://sites.google.com/site/biblialivre/")!,
        changesNote: "Adaptações de formatação: títulos dos Salmos e colchetes removidos, pontuação final e alguns erros de digitação corrigidos.")

    /// World English Bible (updated edition, eBible.org "engwebp"). Public domain; the name is an
    /// eBible.org trademark that may be used as long as the words of the text are not changed.
    /// The passages are quoted verbatim; only their boundaries and punctuation marks are adjusted.
    public static let english = BibleEdition(
        attribution: "World English Bible (WEB), 2020 stable text edition · Public domain · \"World English Bible\" is a trademark of eBible.org",
        shortAttribution: "World English Bible (WEB) · Public Domain",
        licenseTitle: "Public domain notice",
        licenseURL: URL(string: "https://ebible.org/engwebp/copyright.htm")!,
        sourceTitle: "WorldEnglish.Bible",
        sourceURL: URL(string: "https://worldenglish.bible/")!,
        changesNote: "Quoted as short excerpts: footnotes and headings removed, a closing quotation mark or final period added where an excerpt ends mid-sentence.")

    public static func edition(for language: AppLanguage) -> BibleEdition {
        language == .pt ? portuguese : english
    }

    public static func load(from url: URL) throws -> [Passage] {
        try JSONDecoder().decode([Passage].self, from: Data(contentsOf: url))
    }

    /// The curated passages shipped inside the HoraDePausarCore framework. Both languages hold
    /// the same 365 passage ids and themes, so history and favorites survive a language change.
    public static func bundled(_ language: AppLanguage = .pt) -> [Passage] {
        let name = language == .pt ? "passages" : "passages.en"
        guard let url = Bundle(for: BundleToken.self).url(forResource: name, withExtension: "json"),
              let passages = try? load(from: url) else { return [] }
        return passages
    }
}
