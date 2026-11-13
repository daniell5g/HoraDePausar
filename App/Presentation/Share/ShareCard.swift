import AppKit
import SwiftUI
import HoraDePausarCore

enum ShareFormat: String, CaseIterable, Identifiable {
    case stories, post, square

    var id: String { rawValue }
    var title: String {
        switch self {
        case .stories: "Stories"
        case .post: "Post"
        case .square: L("Quadrado", "Square")
        }
    }
    var caption: String {
        switch self {
        case .stories: L("1080 × 1920 · Stories do Instagram e Status do WhatsApp", "1080 × 1920 · Instagram Stories and WhatsApp Status")
        case .post: L("1080 × 1350 · post no feed", "1080 × 1350 · feed post")
        case .square: L("1080 × 1080 · post ou conversa", "1080 × 1080 · post or chat")
        }
    }
    var size: CGSize {
        switch self {
        case .stories: CGSize(width: 1080, height: 1920)
        case .post: CGSize(width: 1080, height: 1350)
        case .square: CGSize(width: 1080, height: 1080)
        }
    }
}

enum ShareTypeface: String, CaseIterable, Identifiable {
    case classic, modern
    var id: String { rawValue }
    var title: String { self == .classic ? L("Clássica", "Classic") : L("Moderna", "Modern") }
}

/// The image people post. Laid out in pixel units (1 pt = 1 px at scale 1).
struct ShareCardView: View {
    var passage: Passage
    var theme: CardTheme
    var format: ShareFormat
    var typeface: ShareTypeface = .classic
    /// Credit of the edition the passage was taken from; it travels with every image.
    var credit: String = Localization.shared.edition.shortAttribution

    private var size: CGSize { format.size }

    private var verseSize: CGFloat {
        let length = passage.text.count
        let base: CGFloat = switch length {
        case ..<80: 82
        case ..<140: 70
        case ..<200: 60
        case ..<260: 52
        case ..<330: 44
        default: 38
        }
        let heightFactor: CGFloat = switch format {
        case .stories: 1
        case .post: 0.9
        case .square: 0.8
        }
        return base * heightFactor
    }

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, starSeed: UInt64(abs(passage.id.hashValue % 997)))
            glow
            VStack(spacing: 0) {
                header
                Spacer(minLength: 40)
                verse
                Spacer(minLength: 40)
                footer
            }
            .padding(.horizontal, 110)
            .padding(.top, format == .stories ? 210 : 110)
            .padding(.bottom, format == .stories ? 230 : 100)
        }
        .frame(width: size.width, height: size.height)
        .environment(\.colorScheme, theme.isLight ? .light : .dark)
    }

    private var glow: some View {
        RadialGradient(colors: [theme.accent.opacity(theme.isLight ? 0.18 : 0.28), .clear],
                       center: .init(x: 0.5, y: 0.44), startRadius: 0, endRadius: size.width * 0.75)
            .blendMode(theme.isLight ? .multiply : .screen)
    }

    private var header: some View {
        VStack(spacing: 18) {
            Image(systemName: "sun.horizon.fill")
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(theme.accent)
            Text(Brand.name.uppercased())
                .font(.system(size: 24, weight: .semibold))
                .tracking(12)
                .foregroundStyle(theme.secondaryInk)
        }
    }

    private var verse: some View {
        VStack(spacing: 44) {
            Text(passage.text)
                .font(typeface == .classic
                      ? .system(size: verseSize, weight: .regular, design: .serif)
                      : .system(size: verseSize * 0.92, weight: .medium, design: .default))
                .lineSpacing(verseSize * 0.22)
                .multilineTextAlignment(.center)
                .foregroundStyle(theme.ink)
                .minimumScaleFactor(0.6)
                .shadow(color: .black.opacity(theme.isLight ? 0 : 0.18), radius: 18, y: 4)
            HStack(spacing: 22) {
                Rectangle().fill(theme.accent.opacity(0.8)).frame(width: 64, height: 2)
                Text(passage.reference.uppercased())
                    .font(.system(size: 30, weight: .semibold))
                    .tracking(7)
                    .foregroundStyle(theme.accent)
                    .fixedSize()
                Rectangle().fill(theme.accent.opacity(0.8)).frame(width: 64, height: 2)
            }
        }
    }

    private var footer: some View {
        Text(credit)
            .font(.system(size: 21, weight: .medium))
            .tracking(3)
            .foregroundStyle(theme.secondaryInk.opacity(0.75))
    }
}

@MainActor
enum ShareRenderer {
    static func image(passage: Passage, theme: CardTheme, format: ShareFormat, typeface: ShareTypeface) -> NSImage? {
        let renderer = ImageRenderer(content: ShareCardView(passage: passage, theme: theme, format: format, typeface: typeface))
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(format.size)
        return renderer.nsImage
    }

    static func pngData(_ image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    static func fileName(for passage: Passage) -> String {
        let slug = passage.reference
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        return "\(Brand.name.replacingOccurrences(of: " ", with: "-"))-\(slug).png"
    }

    /// Writes the PNG to the caches folder so share services can pick a real file.
    static func temporaryFile(image: NSImage, passage: Passage) -> URL? {
        guard let data = pngData(image) else { return nil }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("HoraDePausarShare", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(fileName(for: passage))
        do { try data.write(to: url, options: .atomic) } catch { return nil }
        return url
    }
}
