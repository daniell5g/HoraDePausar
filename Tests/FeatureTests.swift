import Foundation
import Testing
@testable import HoraDePausarCore

private let saoPaulo: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    c.locale = Locale(identifier: "pt_BR")
    return c
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0) -> Date {
    saoPaulo.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

@Suite("Anotação do dia")
struct NoteTests {
    @Test func noteIsSavedTrimmedAndClearedWhenBlank() {
        var s = AppState()
        s.entries = [DayEntry(day: "2026-11-13", passageID: "A", drawnAt: .now)]
        Devotion.setNote(&s, day: "2026-11-13", text: "  Pedir paciência.\n")
        #expect(s.entries[0].note == "Pedir paciência.")
        Devotion.setNote(&s, day: "2026-11-13", text: "   ")
        #expect(s.entries[0].note == nil)
    }

    @Test func oldStateWithoutNotesStillLoads() throws {
        let json = #"{"entries":[{"day":"2026-11-10","passageID":"A","drawnAt":0}],"favorites":[]}"#
        let s = try JSONDecoder().decode(AppState.self, from: Data(json.utf8))
        #expect(s.entries.first?.note == nil)
        #expect(s.weekTheme == nil)
        #expect(s.evening == EveningReminder())
    }

    @Test func noteSurvivesEncoding() throws {
        var s = AppState()
        s.entries = [DayEntry(day: "2026-11-13", passageID: "A", drawnAt: .now, note: "Obrigado.")]
        let back = try JSONDecoder().decode(AppState.self, from: JSONEncoder().encode(s))
        #expect(back.entries[0].note == "Obrigado.")
    }
}

@Suite("Tema da semana")
struct WeekThemeTests {
    let pool = [Passage(id: "A", reference: "A", text: "A.", theme: .paz),
                Passage(id: "B", reference: "B", text: "B.", theme: .amor),
                Passage(id: "C", reference: "C", text: "C.", theme: .amor)]

    @Test func weekKeyIsMonday() {
        #expect(Devotion.weekKey(now: date(2026, 11, 13, 10), calendar: saoPaulo) == "2026-11-09") // sexta
        #expect(Devotion.weekKey(now: date(2026, 11, 15, 23), calendar: saoPaulo) == "2026-11-09") // domingo
        #expect(Devotion.weekKey(now: date(2026, 11, 16, 0, 5), calendar: saoPaulo) == "2026-11-16") // segunda
    }

    @Test func themeLastsOnlyItsWeek() {
        var s = AppState()
        s.weekTheme = WeekTheme(theme: .amor, week: "2026-11-09")
        #expect(Devotion.activeTheme(s, now: date(2026, 11, 15, 22), calendar: saoPaulo) == .amor)
        #expect(Devotion.activeTheme(s, now: date(2026, 11, 16, 8), calendar: saoPaulo) == nil)
    }

    @Test func poolFollowsTheme() {
        #expect(Devotion.pool(pool, theme: .amor).map(\.id) == ["B", "C"])
        #expect(Devotion.pool(pool, theme: nil).count == 3)
        #expect(Devotion.pool(pool, theme: .sabedoria).count == 3) // no passage of that theme: everything
    }

    @Test func everyThemeHasAWeekOfPassages() {
        let all = PassageLibrary.bundled()
        for theme in PassageTheme.allCases { #expect(Devotion.pool(all, theme: theme).count >= 7) }
    }
}

@Suite("Sorteio sem repetir")
struct PickerFallbackTests {
    struct Seed: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 { state = state &* 6364136223846793005 &+ 1442695040888963407; return state }
    }

    @Test func whenAllWereSeenTheOldestReturns() {
        let pool = (1...3).map { Passage(id: "P\($0)", reference: "", text: ".", theme: .paz) }
        var rng = Seed(state: 9)
        #expect(PassagePicker.pick(from: pool, avoiding: ["P2", "P3", "P1", "P3"], using: &rng)?.id == "P2")
    }

    @Test func aYearOfDaysNeverRepeats() {
        let all = PassageLibrary.bundled()
        var rng = Seed(state: 11)
        var s = AppState()
        var day = date(2026, 1, 1, 8)
        for _ in 0..<365 {
            Devotion.ensureToday(&s, pool: all, now: day, calendar: saoPaulo, rng: &rng)
            day = saoPaulo.date(byAdding: .day, value: 1, to: day)!
        }
        #expect(Set(s.entries.map(\.passageID)).count == 365)
    }
}

@Suite("Lembrete da noite")
struct EveningTests {
    let schedule = ReminderSchedule() // padrão
    var dailyFire: Date { schedule.fireDate(on: date(2026, 11, 13), calendar: saoPaulo)! }

    func due(_ now: Date, fired: Date?, nudged: Date? = nil, read: Bool = false, evening: EveningReminder = .init()) -> Bool {
        evening.isDue(now: now, schedule: schedule, lastFired: fired, lastNudged: nudged, alreadyReadToday: read, calendar: saoPaulo)
    }

    @Test func nudgesOnceAtNightWhenUnread() {
        #expect(!due(date(2026, 11, 13, 20, 59), fired: dailyFire))
        #expect(due(date(2026, 11, 13, 21, 0), fired: dailyFire))
        #expect(due(date(2026, 11, 13, 23, 30), fired: dailyFire))
        #expect(!due(date(2026, 11, 13, 21, 5), fired: dailyFire, nudged: date(2026, 11, 13, 21, 0)))
    }

    @Test func silentWhenReadDisabledOrNoDailyReminder() {
        #expect(!due(date(2026, 11, 13, 21, 0), fired: dailyFire, read: true))
        #expect(!due(date(2026, 11, 13, 21, 0), fired: dailyFire, evening: .init(isEnabled: false)))
        #expect(!due(date(2026, 11, 13, 21, 0), fired: nil))
        #expect(!due(date(2026, 11, 13, 21, 0), fired: date(2026, 11, 12, 7))) // fired yesterday only
        #expect(!due(date(2026, 11, 13, 22, 0), fired: date(2026, 11, 13, 21, 40))) // daily came late (Mac asleep)
    }

    @Test func yesterdaysNudgeDoesNotBlockToday() {
        #expect(due(date(2026, 11, 13, 21, 0), fired: dailyFire, nudged: date(2026, 11, 12, 21, 0)))
    }
}

@Suite("Decorar")
struct MemorizeTests {
    @Test func wordsKeepPunctuationVisible() {
        let w = Memorize.words("“Aquietai-vos, e sabei que eu sou Deus.”")
        #expect(w.first == Memorize.Word(core: "Aquietai-vos", prefix: "“", suffix: ","))
        #expect(w.last == Memorize.Word(core: "Deus", prefix: "", suffix: ".”"))
        #expect(w.count == 7)
    }

    @Test func levelsGrowAndAreStable() {
        let seed = Memorize.seed(for: "PSA.46.10")
        #expect(seed == Memorize.seed(for: "PSA.46.10"))
        var previous: Set<Int> = []
        for level in 0...Memorize.levels {
            let hidden = Memorize.hidden(wordCount: 10, level: level, seed: seed)
            #expect(previous.isSubset(of: hidden))
            #expect(hidden == Memorize.hidden(wordCount: 10, level: level, seed: seed))
            previous = hidden
        }
        #expect(Memorize.hidden(wordCount: 10, level: 0, seed: seed).isEmpty)
        #expect(Memorize.hidden(wordCount: 10, level: Memorize.levels, seed: seed).count == 10)
    }
}
