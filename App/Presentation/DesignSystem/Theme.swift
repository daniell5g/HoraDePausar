import AppKit
import SwiftUI

enum Brand {
    static let name = "Hora de Pausar"
    /// The company that builds the app, credited quietly under the sidebar's week strip and in the About panel.
    static let company = "TechDaniel's"
    static var tagline: String { L("Uma pausa com Deus, todos os dias.", "A pause with God, every day.") }
    /// Muted sage used for controls; deep in light mode, soft in dark mode (matches AccentColor).
    static let accent = Color.dynamic(light: 0x4F766B, dark: 0xA9C5BA)
    /// Text drawn on top of `accent`.
    static let onAccent = Color.dynamic(light: 0xFFFFFF, dark: 0x14201C)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }

    /// A color that follows the system light/dark appearance.
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let hex = appearance.isDark ? dark : light
            return NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
}

extension NSAppearance {
    var isDark: Bool { bestMatch(from: [.darkAqua, .aqua]) == .darkAqua }
}

/// Background palettes. `linho` and `sereno` are the app's own calm look (light and dark);
/// every case is also offered as a background for the share image.
enum CardTheme: String, CaseIterable, Identifiable {
    case linho, sereno, oliveira, oceano, noite, aurora

    var id: String { rawValue }

    var title: String {
        switch self {
        case .linho: L("Linho", "Linen")
        case .sereno: L("Sereno", "Serene")
        case .aurora: "Aurora"
        case .oliveira: L("Oliveira", "Olive")
        case .noite: L("Noite", "Night")
        case .oceano: L("Mar da Galileia", "Sea of Galilee")
        }
    }

    /// 3×3 mesh colors, row by row (top → bottom).
    var mesh: [Color] {
        switch self {
        case .linho:
            [Color(hex: 0xF7F6F2), Color(hex: 0xF4F3EE), Color(hex: 0xF0EFEA),
             Color(hex: 0xEEEEE8), Color(hex: 0xF6F5F1), Color(hex: 0xE9ECE7),
             Color(hex: 0xE6EAE6), Color(hex: 0xEDEDE7), Color(hex: 0xE1E7E4)]
        case .sereno:
            [Color(hex: 0x101418), Color(hex: 0x12171C), Color(hex: 0x14191F),
             Color(hex: 0x171D23), Color(hex: 0x1B2229), Color(hex: 0x172026),
             Color(hex: 0x1A2429), Color(hex: 0x1E292D), Color(hex: 0x19242A)]
        case .aurora:
            [Color(hex: 0x1A1440), Color(hex: 0x2B1D55), Color(hex: 0x3A2160),
             Color(hex: 0x6B3A78), Color(hex: 0xC9667E), Color(hex: 0x8E4A7A),
             Color(hex: 0xF2A07B), Color(hex: 0xF8C99A), Color(hex: 0xF6B48F)]
        case .oliveira:
            [Color(hex: 0x141C14), Color(hex: 0x1E2B1E), Color(hex: 0x223222),
             Color(hex: 0x3E5A3A), Color(hex: 0x5D7A52), Color(hex: 0x40593A),
             Color(hex: 0x9DAE8E), Color(hex: 0xC5D0BA), Color(hex: 0xB0BEA2)]
        case .noite:
            [Color(hex: 0x04060D), Color(hex: 0x070B19), Color(hex: 0x0A1024),
             Color(hex: 0x101A3C), Color(hex: 0x1E2A5C), Color(hex: 0x16204A),
             Color(hex: 0x2B2A5E), Color(hex: 0x3D3470), Color(hex: 0x24305E)]
        case .oceano:
            [Color(hex: 0x021219), Color(hex: 0x031B26), Color(hex: 0x05222F),
             Color(hex: 0x0B4F6C), Color(hex: 0x1B7A8C), Color(hex: 0x0D5D78),
             Color(hex: 0x58B7AE), Color(hex: 0xCDEBE3), Color(hex: 0x3FA7A3)]
        }
    }

    var isLight: Bool { self == .linho }
    var ink: Color {
        switch self {
        case .linho: Color(hex: 0x1E2629)
        case .sereno: Color(hex: 0xEDF1EF)
        default: .white
        }
    }
    var secondaryInk: Color {
        switch self {
        case .linho: Color(hex: 0x1E2629, opacity: 0.6)
        case .sereno: Color(hex: 0xEDF1EF, opacity: 0.62)
        default: .white.opacity(0.72)
        }
    }

    var accent: Color {
        switch self {
        case .linho: Color(hex: 0x4F766B)
        case .sereno: Color(hex: 0xA9C5BA)
        case .aurora: Color(hex: 0xF6DDE4)
        case .oliveira: Color(hex: 0xD6E2CB)
        case .noite: Color(hex: 0xCDD3E8)
        case .oceano: Color(hex: 0xBDEDE2)
        }
    }

    /// Text drawn on top of `accent` (the "Amém" button).
    var onAccent: Color { self == .linho ? .white : Color(hex: 0x14201C) }

    var showsStars: Bool { self == .noite || self == .aurora }

    /// The app's own surfaces (main window, reminder card) follow the system appearance.
    static func calm(_ scheme: ColorScheme) -> CardTheme { scheme == .dark ? .sereno : .linho }
    static var calmForSystem: CardTheme { NSApp.effectiveAppearance.isDark ? .sereno : .linho }
}

/// Soft mesh gradient, optionally breathing over time.
struct ThemeBackground: View {
    var theme: CardTheme
    var animated: Bool = false
    var starSeed: UInt64 = 7

    var body: some View {
        ZStack {
            if animated {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    mesh(t: context.date.timeIntervalSinceReferenceDate)
                }
            } else {
                mesh(t: 0)
            }
            if theme.showsStars {
                StarField(seed: starSeed, density: theme == .noite ? 1.0 : 0.35)
                    .blendMode(.screen)
            }
            GrainOverlay(opacity: theme == .linho || theme == .sereno ? 0.035 : 0.07)
        }
    }

    private func mesh(t: Double) -> some View {
        let a = Float(sin(t * 0.35)) * 0.06
        let b = Float(cos(t * 0.27)) * 0.06
        return MeshGradient(
            width: 3, height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.55 + b], [0.5 + a, 0.5 + b], [1, 0.45 - a],
                [0, 1], [0.5 - b, 1], [1, 1],
            ],
            colors: theme.mesh,
            smoothsColors: true
        )
    }
}

/// Deterministic sprinkle of tiny stars (renders in ImageRenderer too).
struct StarField: View {
    var seed: UInt64
    var density: Double

    var body: some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: seed)
            let count = Int(Double(size.width * size.height) / 2600 * density)
            for _ in 0..<count {
                let x = Double.random(in: 0...size.width, using: &rng)
                let y = Double.random(in: 0...(size.height * 0.62), using: &rng)
                let r = Double.random(in: 0.35...1.25, using: &rng) * max(1, size.width / 420)
                let alpha = Double.random(in: 0.15...0.75, using: &rng) * (1 - y / (size.height * 0.62))
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(.white.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Fine film grain so flat gradients feel like paper / light, not plastic.
struct GrainOverlay: View {
    var opacity: Double

    var body: some View {
        Image(decorative: GrainOverlay.noise, scale: 1)
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .allowsHitTesting(false)
    }

    static let noise: CGImage = {
        let side = 192
        var rng = SeededRandom(seed: 42)
        var pixels = [UInt8](repeating: 0, count: side * side)
        for i in pixels.indices { pixels[i] = UInt8.random(in: 0...255, using: &rng) }
        let provider = CGDataProvider(data: Data(pixels) as CFData)!
        return CGImage(width: side, height: side, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: side,
                       space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)!
    }()
}

struct SeededRandom: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension Font {
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

/// Small-caps style label used for dates, references and section titles.
struct Eyebrow: View {
    var text: String
    var color: Color = .secondary
    var size: CGFloat = 10.5

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: size, weight: .semibold))
            .tracking(size * 0.16)
            .foregroundStyle(color)
    }
}
