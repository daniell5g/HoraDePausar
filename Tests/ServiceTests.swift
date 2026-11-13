import Foundation
import Testing
@testable import HoraDePausarCore

private let saoPaulo: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    return c
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    saoPaulo.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

/// In-memory stand-in for the JSON file, counting saves.
private final class MemoryRepository: StateRepository {
    var stored: AppState
    var saves = 0
    init(_ state: AppState = AppState()) { stored = state }
    func load() -> AppState { stored }
    func save(_ state: AppState) throws { stored = state; saves += 1 }
}

private struct Counter: RandomNumberGenerator {
    var value: UInt64 = 7
    mutating func next() -> UInt64 { value &+= 0x9E37_79B9_7F4A_7C15; return value }
}

private let pool = [Passage(id: "P", reference: "P", text: "P.", theme: .paz),
                    Passage(id: "A1", reference: "A1", text: "A1.", theme: .amor),
                    Passage(id: "A2", reference: "A2", text: "A2.", theme: .amor)]

private func service(_ repo: MemoryRepository) -> DevotionService {
    DevotionService(repository: repo, passages: pool, calendar: saoPaulo, rng: Counter())
}

@Suite("Casos de uso")
struct ServiceTests {
    let now = date(2026, 11, 13, 9)

    @Test("Sorteio de hoje é salvo uma vez e não muda na segunda chamada")
    func ensureTodayPersistsOnce() {
        let repo = MemoryRepository()
        let s = service(repo)
        let first = s.ensureToday(now: now)
        let second = s.ensureToday(now: now)
        #expect(first != nil && first == second)
        #expect(repo.saves == 1)
        #expect(repo.stored.entries.count == 1)
    }

    @Test("Tema da semana troca a passagem de hoje se ainda não foi lida")
    func weekThemeRedrawsUnread() {
        var state = AppState()
        state.entries = [DayEntry(day: "2026-11-13", passageID: "P", drawnAt: now)]
        let s = service(MemoryRepository(state))
        s.setWeekTheme(.amor, now: now)
        #expect(s.passage(id: s.todayEntry(now: now)!.passageID)?.theme == .amor)
        #expect(s.weekTheme(now: now) == .amor)
    }

    @Test("Tema da semana não mexe em passagem lida ou anotada")
    func weekThemeKeepsReadOrNoted() {
        var read = AppState()
        read.entries = [DayEntry(day: "2026-11-13", passageID: "P", drawnAt: now, readAt: now)]
        let a = service(MemoryRepository(read))
        a.setWeekTheme(.amor, now: now)
        #expect(a.todayEntry(now: now)?.passageID == "P")

        var noted = AppState()
        noted.entries = [DayEntry(day: "2026-11-13", passageID: "P", drawnAt: now, note: "minha nota")]
        let b = service(MemoryRepository(noted))
        b.setWeekTheme(.amor, now: now)
        #expect(b.todayEntry(now: now)?.passageID == "P")
    }

    @Test("Nada muda, nada é gravado")
    func noChangeNoSave() {
        let repo = MemoryRepository()
        let s = service(repo)
        s.markReadToday(now: now) // no entry today: nothing to mark
        s.setWeekTheme(nil, now: now)
        #expect(repo.saves == 0)
    }

    @Test("Lembrete do dia, depois o da noite, cada um uma vez")
    func reminderPolicy() {
        var state = AppState()
        state.entries = [DayEntry(day: "2026-11-13", passageID: "P", drawnAt: date(2026, 11, 13, 7))]
        let s = service(MemoryRepository(state))
        #expect(s.dueReminder(now: date(2026, 11, 13, 6, 59)) == nil)
        #expect(s.dueReminder(now: date(2026, 11, 13, 7, 1)) == .daily)
        s.recordReminder(.daily, at: date(2026, 11, 13, 7, 1))
        #expect(s.dueReminder(now: date(2026, 11, 13, 12)) == nil)
        #expect(s.dueReminder(now: date(2026, 11, 13, 21, 0)) == .evening)
        s.recordReminder(.evening, at: date(2026, 11, 13, 21, 0))
        #expect(s.dueReminder(now: date(2026, 11, 13, 22)) == nil)
    }

    @Test("Arquivo JSON guarda e lê o mesmo estado")
    func jsonRoundTrip() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("state.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let repo = JSONStateRepository(fileURL: url)
        var state = AppState()
        state.favorites = ["P"]
        state.entries = [DayEntry(day: "2026-11-13", passageID: "P", drawnAt: date(2026, 11, 13, 7), note: "nota")]
        try repo.save(state)
        #expect(repo.load() == state)
    }
}

@Suite("Idioma")
struct LanguageTests {
    let now = date(2026, 11, 13, 9)

    @Test func followsTheMacUntilPicked() {
        #expect(AppLanguage.preferred(["pt-BR", "en-US"]) == .pt)
        #expect(AppLanguage.preferred(["en-GB"]) == .en)
        #expect(AppLanguage.preferred(["es-ES", "pt-PT"]) == .pt)
        #expect(AppLanguage.preferred(["fr-FR"]) == .en)
        #expect(AppLanguage.preferred([]) == .en)
    }

    @Test func oldStateHasNoLanguageAndUnknownOnesAreIgnored() throws {
        let decode = { (json: String) in try JSONDecoder().decode(AppState.self, from: Data(json.utf8)) }
        #expect(try decode("{}").language == nil)
        #expect(try decode(#"{"language":"en"}"#).language == .en)
        #expect(try decode(#"{"language":"fr","favorites":["X"]}"#).language == nil)
        #expect(try decode(#"{"language":"fr","favorites":["X"]}"#).favorites == ["X"])
        var state = AppState()
        state.language = .en
        #expect(try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(state)) == state)
    }

    @Test func switchingKeepsHistoryAndShowsTheOtherText() {
        let repo = MemoryRepository()
        let s = service(repo)
        let today = s.ensureToday(now: now)!
        s.toggleFavorite(today)
        s.setLanguage(.en)
        s.replacePassages(pool.map { Passage(id: $0.id, reference: "\($0.reference) en", text: "\($0.text) en", theme: $0.theme) })
        #expect(repo.stored.language == .en)
        #expect(s.ensureToday(now: now)?.id == today.id)
        #expect(s.ensureToday(now: now)?.text == "\(today.text) en")
        #expect(s.favorites.map(\.reference) == ["\(today.reference) en"])
    }

    @Test func englishLibraryMatchesThePortugueseOne() {
        let pt = PassageLibrary.bundled(.pt)
        let en = PassageLibrary.bundled(.en)
        #expect(en.count == 365)
        #expect(en.map(\.id) == pt.map(\.id))
        #expect(en.map(\.theme) == pt.map(\.theme))
        for p in en {
            #expect(p.text.first { $0.isLetter }?.isUppercase == true, "\(p.id) starts lowercase")
            #expect(".!?”’".contains(p.text.last!), "\(p.id) ends without punctuation")
            #expect(!p.text.contains("\\") && !p.text.contains("|") && !p.text.contains("["), "\(p.id) has markup")
            #expect(p.text.filter { $0 == "“" }.count == p.text.filter { $0 == "”" }.count, "\(p.id) unbalanced quotes")
        }
    }

    @Test func eachLanguageCarriesItsOwnCredit() {
        #expect(PassageLibrary.edition(for: .pt).shortAttribution == "Bíblia Livre (BLIVRE) · CC BY 3.0 BR")
        #expect(PassageLibrary.edition(for: .en).shortAttribution.contains("World English Bible"))
        #expect(PassageLibrary.edition(for: .en).attribution.contains("Public domain"))
    }

    @Test func weekdayLetters() {
        #expect((1...7).map { WeekDay.letter(weekday: $0, in: .pt) }.joined() == "DSTQQSS")
        #expect((1...7).map { WeekDay.letter(weekday: $0, in: .en) }.joined() == "SMTWTFS")
    }
}
