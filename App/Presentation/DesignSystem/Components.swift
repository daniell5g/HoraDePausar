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

/// A thin, dim scroll indicator drawn by the app. The system one is a near-white bar that widens
/// under the pointer, which looks coarse in this dark app. It shows while scrolling (and briefly
/// when the view appears, as macOS does) and then fades out.
private struct SubtleScrollIndicator: ViewModifier {
    @State private var geometry: ScrollGeometry?
    @State private var visible = false
    @State private var hide: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .scrollIndicators(.never)
            .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }) { old, new in
                geometry = new
                if old.contentOffset != new.contentOffset { reveal() }
            }
            .overlay(alignment: .topTrailing) {
                GeometryReader { proxy in bar(height: proxy.size.height) }
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .onAppear { reveal() }
    }

    @ViewBuilder private func bar(height: CGFloat) -> some View {
        if let geometry, geometry.contentSize.height > geometry.visibleRect.height + 1 {
            let inset: CGFloat = 4, width: CGFloat = 4
            let track = height - inset * 2
            let length = max(track * geometry.visibleRect.height / geometry.contentSize.height, 28)
            let travel = geometry.contentSize.height - geometry.visibleRect.height
            let progress = min(max(geometry.visibleRect.minY / travel, 0), 1)
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: width, height: length)
                .offset(x: -inset, y: inset + (track - length) * progress)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .opacity(visible ? 1 : 0)
                .animation(.easeOut(duration: 0.35), value: visible)
        }
    }

    private func reveal() {
        visible = true
        hide?.cancel()
        hide = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            if !Task.isCancelled { visible = false }
        }
    }
}

extension View {
    /// Replaces the system scroll indicator of this scroll view with a thin, dim one.
    func subtleScrollIndicator() -> some View { modifier(SubtleScrollIndicator()) }
}
