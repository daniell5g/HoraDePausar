import CoreGraphics
import Foundation
import Testing
@testable import HoraDePausarCore

private let saoPaulo: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    c.locale = Locale(identifier: "pt_BR")
    return c
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 0, _ min: Int = 0, _ s: Int = 0) -> Date {
    saoPaulo.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min, second: s))!
}

@Suite("Agendamento diário")
struct ScheduleTests {
    let seven = ReminderSchedule(isEnabled: true, hour: 7, minute: 0, weekdays: Set(1...7))

    @Test func notDueBeforeTheChosenTime() {
        #expect(!seven.isDue(now: date(2026, 11, 12, 6, 59, 59), lastFired: nil, alreadyReadToday: false, calendar: saoPaulo))
    }

    @Test func dueAtExactlyTheChosenTime() {
        #expect(seven.isDue(now: date(2026, 11, 12, 7, 0, 0), lastFired: nil, alreadyReadToday: false, calendar: saoPaulo))
    }

    @Test func firesOnlyOncePerDay() {
        let fired = date(2026, 11, 12, 7, 0, 10)
        #expect(!seven.isDue(now: date(2026, 11, 12, 9, 30), lastFired: fired, alreadyReadToday: false, calendar: saoPaulo))
        #expect(!seven.isDue(now: date(2026, 11, 12, 23, 59), lastFired: fired, alreadyReadToday: false, calendar: saoPaulo))
    }

    @Test func firesAgainTheNextDay() {
        let firedYesterday = date(2026, 11, 11, 7, 0, 5)
        #expect(seven.isDue(now: date(2026, 11, 12, 7, 0, 30), lastFired: firedYesterday, alreadyReadToday: false, calendar: saoPaulo))
    }

    @Test func macAsleepAtReminderTimeFiresOnWake() {
        // Lid closed 06:30, opened 10:15: the 07:00 reminder must still show.
        #expect(seven.isDue(now: date(2026, 11, 12, 10, 15), lastFired: date(2026, 11, 11, 7, 0), alreadyReadToday: false, calendar: saoPaulo))
    }

    @Test func skipsWhenAlreadyReadToday() {
        #expect(!seven.isDue(now: date(2026, 11, 12, 8, 0), lastFired: nil, alreadyReadToday: true, calendar: saoPaulo))
    }

    @Test func respectsWeekdays() {
        // 2026-11-14 is a Saturday (weekday 7), 2026-11-16 is a Monday (weekday 2).
        let weekdaysOnly = ReminderSchedule(hour: 7, minute: 0, weekdays: [2, 3, 4, 5, 6])
        #expect(!weekdaysOnly.isDue(now: date(2026, 11, 14, 8, 0), lastFired: nil, alreadyReadToday: false, calendar: saoPaulo))
        #expect(weekdaysOnly.isDue(now: date(2026, 11, 16, 8, 0), lastFired: nil, alreadyReadToday: false, calendar: saoPaulo))
    }

    @Test func disabledNeverFires() {
        var off = seven
        off.isEnabled = false
        #expect(!off.isDue(now: date(2026, 11, 12, 12, 0), lastFired: nil, alreadyReadToday: false, calendar: saoPaulo))
        #expect(off.nextFire(after: date(2026, 11, 12, 12, 0), calendar: saoPaulo) == nil)
    }

    @Test func nextFireIsLaterTodayOrTomorrow() {
        let evening = ReminderSchedule(hour: 21, minute: 30, weekdays: Set(1...7))
        #expect(evening.nextFire(after: date(2026, 11, 12, 18, 0), calendar: saoPaulo) == date(2026, 11, 12, 21, 30))
        #expect(evening.nextFire(after: date(2026, 11, 12, 21, 30), calendar: saoPaulo) == date(2026, 11, 13, 21, 30))
    }

    @Test func nextFireSkipsUnscheduledDays() {
        // Thursday 2026-11-12 after 07:00, Sundays only → Sunday 2026-11-15 07:00.
        let sundays = ReminderSchedule(hour: 7, minute: 0, weekdays: [1])
        #expect(sundays.nextFire(after: date(2026, 11, 12, 8, 0), calendar: saoPaulo) == date(2026, 11, 15, 7, 0))
    }

    @Test func noWeekdaysMeansNoNextFire() {
        let none = ReminderSchedule(hour: 7, minute: 0, weekdays: [])
        #expect(none.nextFire(after: date(2026, 11, 12, 8, 0), calendar: saoPaulo) == nil)
    }
}

@Suite("Sorteio da passagem")
struct PickerTests {
    let pool = (1...10).map { Passage(id: "P\($0)", reference: "Ref \($0)", text: "Texto \($0)", theme: .paz) }

    struct FixedSeed: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
    }

    @Test func neverRepeatsWithinRecentWindow() {
        var rng = FixedSeed(state: 1)
        let recent = (1...7).map { "P\($0)" }
        for _ in 0..<500 {
            let pick = PassagePicker.pick(from: pool, avoiding: recent, using: &rng)!
            #expect(!recent.contains(pick.id))
        }
    }

    @Test func alwaysFindsAPassageEvenIfEverythingWasRecent() {
        var rng = FixedSeed(state: 2)
        let recent = pool.map(\.id) + pool.map(\.id)
        for _ in 0..<100 {
            let pick = PassagePicker.pick(from: pool, avoiding: recent, using: &rng)
            #expect(pick != nil)
            // Everything was shown recently: the one seen longest ago comes back.
            #expect(pick?.id == "P1")
        }
    }

    @Test func emptyPoolGivesNothing() {
        var rng = FixedSeed(state: 3)
        #expect(PassagePicker.pick(from: [], avoiding: [], using: &rng) == nil)
    }

    @Test func drawIsSpreadAcrossThePool() {
        var rng = FixedSeed(state: 4)
        var seen = Set<String>()
        for _ in 0..<400 { seen.insert(PassagePicker.pick(from: pool, avoiding: [], using: &rng)!.id) }
        #expect(seen.count == pool.count)
    }

    @Test func dailyDrawIsStableWithinTheDayAndCyclesWithoutRepeats() {
        var rng = FixedSeed(state: 5)
        var state = AppState()
        let first = Devotion.ensureToday(&state, pool: pool, now: date(2026, 11, 12, 7, 0), calendar: saoPaulo, rng: &rng)
        let again = Devotion.ensureToday(&state, pool: pool, now: date(2026, 11, 12, 22, 0), calendar: saoPaulo, rng: &rng)
        #expect(first == again)
        #expect(state.entries.count == 1)

        // Ten consecutive days with a pool of ten: every passage exactly once.
        for day in 13...21 {
            Devotion.ensureToday(&state, pool: pool, now: date(2026, 11, day, 7, 0), calendar: saoPaulo, rng: &rng)
        }
        #expect(Set(state.entries.map(\.passageID)).count == 10)
    }

    @Test func redrawPicksSomethingElseAndResetsRead() {
        var rng = FixedSeed(state: 6)
        var state = AppState()
        let now = date(2026, 11, 12, 7, 0)
        let first = Devotion.ensureToday(&state, pool: pool, now: now, calendar: saoPaulo, rng: &rng)!
        let second = Devotion.redrawToday(&state, pool: pool, now: now, calendar: saoPaulo, rng: &rng)!
        #expect(first.passageID != second.passageID)
        #expect(state.entries.count == 1)
    }

    @Test func attributionCitesTheOfficialLicense() {
        // Official source: translators' site + LICENCA.md in github.com/blivre/BibliaLivre → CC BY 3.0 BR.
        #expect(PassageLibrary.portuguese.attribution.contains("Atribuição 3.0 Brasil"))
        #expect(PassageLibrary.portuguese.attribution.contains("fevereiro de 2018"))
        #expect(PassageLibrary.portuguese.shortAttribution.contains("CC BY 3.0 BR"))
        #expect(PassageLibrary.portuguese.licenseURL.absoluteString == "https://creativecommons.org/licenses/by/3.0/br/")
        #expect(!PassageLibrary.portuguese.attribution.contains("4.0"))
    }

    @Test func bundledLibraryLoadsAndIsWellFormed() {
        let passages = PassageLibrary.bundled()
        #expect(passages.count == 365)
        for theme in PassageTheme.allCases { #expect(passages.filter { $0.theme == theme }.count >= 40, "\(theme)") }
        #expect(Set(passages.map(\.id)).count == passages.count)
        for p in passages {
            #expect(!p.text.isEmpty)
            #expect(p.text.first?.isUppercase == true, "\(p.id) starts lowercase")
            #expect(".!?".contains(p.text.last!), "\(p.id) ends without punctuation")
            #expect(!p.text.contains("["), "\(p.id) has bracket markup")
        }
    }
}

@Suite("Leitura e sequência")
struct StreakTests {
    @Test func markReadAndStreak() {
        var rng = SystemRandomNumberGenerator()
        let pool = [Passage(id: "A", reference: "A", text: "A.", theme: .paz), Passage(id: "B", reference: "B", text: "B.", theme: .amor)]
        var state = AppState()
        for day in 10...12 {
            let now = date(2026, 11, day, 7, 30)
            Devotion.ensureToday(&state, pool: pool, now: now, calendar: saoPaulo, rng: &rng)
            Devotion.markRead(&state, now: now, calendar: saoPaulo)
        }
        #expect(Devotion.isReadToday(state, now: date(2026, 11, 12, 20, 0), calendar: saoPaulo))
        #expect(Devotion.streak(state, now: date(2026, 11, 12, 20, 0), calendar: saoPaulo) == 3)
        // Next morning, not read yet: streak still counts through yesterday.
        #expect(Devotion.streak(state, now: date(2026, 11, 13, 6, 0), calendar: saoPaulo) == 3)
        // Skipped a whole day: streak resets.
        #expect(Devotion.streak(state, now: date(2026, 11, 14, 6, 0), calendar: saoPaulo) == 0)
    }

    @Test func markReadKeepsFirstReadTime() {
        var rng = SystemRandomNumberGenerator()
        var state = AppState()
        let pool = [Passage(id: "A", reference: "A", text: "A.", theme: .paz)]
        Devotion.ensureToday(&state, pool: pool, now: date(2026, 11, 12, 7, 0), calendar: saoPaulo, rng: &rng)
        Devotion.markRead(&state, now: date(2026, 11, 12, 7, 5), calendar: saoPaulo)
        Devotion.markRead(&state, now: date(2026, 11, 12, 9, 0), calendar: saoPaulo)
        #expect(state.entries[0].readAt == date(2026, 11, 12, 7, 5))
    }

    @Test func stateRoundTripsThroughJSON() throws {
        var state = AppState()
        state.schedule = ReminderSchedule(hour: 21, minute: 15, weekdays: [1, 7])
        state.favorites = ["PSA.23.1-3"]
        state.entries = [DayEntry(day: "2026-11-12", passageID: "PSA.23.1-3", drawnAt: date(2026, 11, 12, 7, 0), readAt: date(2026, 11, 12, 7, 3))]
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AppState.self, from: encoder.encode(state))
        #expect(decoded == state)
        // Older files missing new keys still decode with defaults.
        let legacy = try decoder.decode(AppState.self, from: Data(#"{"favorites":["X"]}"#.utf8))
        #expect(legacy.favorites == ["X"])
        #expect(legacy.schedule == ReminderSchedule())
    }
}

@Suite("Cartão do lembrete na tela")
struct FloatingPlacementTests {
    // Window of the reminder card measured on Daniel's Mac: 380×192 card + 24 pt shadow room.
    let window = CGSize(width: 428, height: 240)

    @Test(arguments: [
        CGRect(x: 0, y: 86, width: 1470, height: 837),        // built-in Retina, menu bar + Dock
        CGRect(x: -1920, y: -124, width: 1920, height: 1080),  // external 1080p to the left, below
        CGRect(x: 1470, y: 300, width: 1280, height: 777),     // a display to the right
    ])
    func cardStaysFullyOnScreen(visible: CGRect) {
        let origin = FloatingPlacement.topRight(window: window, inset: 24, margin: 12, in: visible)
        let card = FloatingPlacement.cardFrame(window: window, inset: 24, origin: origin)
        #expect(visible.insetBy(dx: 12, dy: 12).contains(card))
        #expect(card.maxX == visible.maxX - 12)
        #expect(card.maxY == visible.maxY - 12)
    }

    @Test func tinyScreenKeepsTheCardsTopLeftVisible() {
        let visible = CGRect(x: 0, y: 0, width: 300, height: 150)
        let origin = FloatingPlacement.topRight(window: window, inset: 24, margin: 12, in: visible)
        let card = FloatingPlacement.cardFrame(window: window, inset: 24, origin: origin)
        #expect(card.minX == 12)
        #expect(card.minY == 12)
    }
}
