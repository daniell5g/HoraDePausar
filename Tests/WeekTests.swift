import Foundation
import Testing
@testable import HoraDePausarCore

private let saoPaulo: Calendar = {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
    c.locale = Locale(identifier: "pt_BR")
    return c
}()

private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 9) -> Date {
    saoPaulo.date(from: DateComponents(year: y, month: m, day: d, hour: h))!
}

private func state(read: [String], unread: [String] = [], weekdays: Set<Int>) -> AppState {
    var s = AppState()
    s.schedule.weekdays = weekdays
    s.entries = read.map { DayEntry(day: $0, passageID: "p", drawnAt: .now, readAt: .now) }
        + unread.map { DayEntry(day: $0, passageID: "p", drawnAt: .now) }
    return s
}

@Suite("Faixa da semana")
struct WeekTests {
    let weekdaysOnly: Set<Int> = Set(2...6) // segunda a sexta

    @Test func thursdayShowsMondayToSundayWithEachStatus() {
        let s = state(read: ["2026-11-09", "2026-11-11"], unread: ["2026-11-10"], weekdays: weekdaysOnly)
        let week = Devotion.week(s, now: date(2026, 11, 12), calendar: saoPaulo)
        #expect(week.map(\.day) == ["2026-11-09", "2026-11-10", "2026-11-11", "2026-11-12", "2026-11-13", "2026-11-14", "2026-11-15"])
        #expect(week.map { $0.letter(in: .pt) }.joined() == "STQQSSD")
        #expect(week.map(\.status) == [.read, .missed, .read, .today, .upcoming, .upcoming, .upcoming])
    }

    @Test func sundayStaysInTheSameWeekAndDaysOffAreRest() {
        let s = state(read: ["2026-11-06", "2026-11-13"], weekdays: weekdaysOnly) // usa o app desde a semana passada
        let week = Devotion.week(s, now: date(2026, 11, 15, 22), calendar: saoPaulo)
        #expect(week.first?.day == "2026-11-09")
        #expect(week[4].status == .read)    // sexta
        #expect(week[5].status == .rest)    // sábado sem lembrete
        #expect(week[6].status == .today)   // domingo
        #expect(week[0].status == .missed)  // segunda sem leitura
    }

    @Test func daysBeforeTheFirstUseAreNotMissed() {
        let s = state(read: ["2026-11-12"], weekdays: Set(1...7))
        let week = Devotion.week(s, now: date(2026, 11, 13), calendar: saoPaulo)
        #expect(week.prefix(3).map(\.status) == [.rest, .rest, .rest]) // seg–qua, antes do app
        #expect(week[3].status == .read)
        #expect(week[4].status == .today)
    }

    @Test func readingTodayMarksItRead() {
        let s = state(read: ["2026-11-12"], weekdays: Set(1...7))
        let week = Devotion.week(s, now: date(2026, 11, 12, 23), calendar: saoPaulo)
        #expect(week[3].status == .read)
    }
}
