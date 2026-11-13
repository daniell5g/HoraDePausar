import SwiftUI
import HoraDePausarCore

/// Sidebar footer: this week at a glance, one line about the streak, and the company credit.
struct WeekStrip: View {
    @Environment(DevotionStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("ESTA SEMANA", "THIS WEEK"))
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.tertiary)
            HStack(spacing: 0) {
                ForEach(store.week) { day in
                    VStack(spacing: 5) {
                        Text(day.letter)
                            .font(.system(size: 9.5, weight: day.status == .today ? .bold : .medium))
                            .foregroundStyle(day.status == .today ? .primary : .secondary)
                        WeekDot(status: day.status)
                    }
                    .frame(maxWidth: .infinity)
                    .help(Self.help(day.status))
                }
            }
            Label(caption.text, systemImage: caption.symbol)
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
            // Quiet company credit, always visible under the week.
            Text("\(L("Feito por", "Made by")) \(Brand.company)")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    private var caption: (text: String, symbol: String) {
        let streak = store.streak
        if streak >= 2 { return (L("\(streak) dias seguidos", "\(streak) days in a row"), "flame") }
        if store.isReadToday { return (L("Pausa de hoje feita", "Today's pause done"), "checkmark") }
        return (L("A pausa de hoje te espera", "Today's pause is waiting"), "sun.horizon")
    }

    private static func help(_ status: WeekDay.Status) -> String {
        switch status {
        case .read: L("Lida", "Read")
        case .missed: L("Não lida", "Not read")
        case .rest: L("Sem lembrete", "No reminder")
        case .today: L("Hoje", "Today")
        case .upcoming: L("Ainda vem", "Coming up")
        }
    }
}

private struct WeekDot: View {
    var status: WeekDay.Status

    var body: some View {
        ZStack {
            switch status {
            case .read:
                Circle().fill(Brand.accent)
                Image(systemName: "checkmark")
                    .font(.system(size: 7.5, weight: .heavy))
                    .foregroundStyle(Brand.onAccent)
            case .today:
                Circle().strokeBorder(Brand.accent, lineWidth: 1.5)
            case .missed:
                Circle().strokeBorder(.secondary.opacity(0.5), lineWidth: 1)
            case .rest:
                Circle().fill(.quaternary).frame(width: 4, height: 4)
            case .upcoming:
                Circle().fill(.quaternary)
            }
        }
        .frame(width: 15, height: 15)
    }
}
