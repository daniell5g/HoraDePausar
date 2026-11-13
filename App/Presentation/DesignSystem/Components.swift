import SwiftUI
import HoraDePausarCore

/// "hoje às 07:00", "amanhã às 07:00", "segunda-feira às 07:00"
/// ("today at 7:00 AM", "tomorrow at 7:00 AM", "Monday at 7:00 AM").
enum ReminderText {
    static func relative(_ date: Date, calendar: Calendar = .current) -> String {
        let locale = Localization.shared.locale
        let time = date.formatted(.dateTime.hour().minute().locale(locale))
        if calendar.isDateInToday(date) { return L("hoje às \(time)", "today at \(time)") }
        if calendar.isDateInTomorrow(date) { return L("amanhã às \(time)", "tomorrow at \(time)") }
        let weekday = date.formatted(.dateTime.weekday(.wide).locale(locale))
        return L("\(weekday) às \(time)", "\(weekday) at \(time)")
    }
}

/// The main call to action: "Amém · li e orei".
struct AmenButtonStyle: ButtonStyle {
    var theme: CardTheme
    var done: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 11)
            .padding(.horizontal, 14)
            .foregroundStyle(done ? theme.ink : theme.onAccent)
            .background {
                Capsule()
                    .fill(done
                          ? AnyShapeStyle(theme.ink.opacity(0.12))
                          : AnyShapeStyle(LinearGradient(colors: [theme.accent, theme.accent.opacity(0.82)], startPoint: .top, endPoint: .bottom)))
            }
            .overlay { Capsule().strokeBorder(.white.opacity(done ? 0.15 : 0.35), lineWidth: 0.5) }
            .shadow(color: .black.opacity(done ? 0 : 0.14), radius: 8, y: 3)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

struct IconGlassButton: View {
    var symbol: String
    var help: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .help(help)
    }
}
