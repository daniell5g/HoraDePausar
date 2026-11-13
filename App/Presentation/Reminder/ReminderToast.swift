import AppKit
import SwiftUI
import HoraDePausarCore

/// The card that slides into the top-right corner at the user's chosen time.
struct ReminderToastView: View {
    var passage: Passage
    var theme: CardTheme
    var onRead: () -> Void
    var onLater: () -> Void
    var onClose: () -> Void

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, animated: true)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 7) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent)
                    Eyebrow(text: L("Hora de pausar", "Time to pause"), color: theme.accent, size: 9.5)
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(theme.secondaryInk)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(theme.ink.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                    .help(L("Fechar", "Close"))
                }
                .padding(.bottom, 12)

                Text(L("Um momento com Deus", "A moment with God"))
                    .font(.serif(22))
                    .foregroundStyle(theme.ink)
                    .padding(.bottom, 8)

                Text("“\(passage.text)”")
                    .font(.serif(14))
                    .italic()
                    .lineSpacing(2)
                    .lineLimit(2)
                    .foregroundStyle(theme.secondaryInk)
                    .padding(.bottom, 16)

                HStack(spacing: 8) {
                    Button(action: onRead) {
                        Text(L("Ler agora", "Read now"))
                            .font(.system(size: 12.5, weight: .semibold))
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(AmenButtonStyle(theme: theme, done: false))

                    Button(action: onLater) {
                        Text(L("Em 15 min", "In 15 min"))
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundStyle(theme.ink)
                            .padding(.horizontal, 2)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)

                    Spacer()
                    Eyebrow(text: passage.reference, color: theme.secondaryInk, size: 9)
                }
            }
            .padding(18)
        }
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(theme.isLight ? Color.black.opacity(0.08) : Color.white.opacity(0.12), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(theme.isLight ? 0.12 : 0.35), radius: 14, y: 6)
        .environment(\.colorScheme, theme.isLight ? .light : .dark)
    }
}

/// Slides the card in from the right *inside* its window, so the window itself never moves.
private struct SlideIn<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var shown = false

    var body: some View {
        content
            .offset(x: shown ? 0 : 16)
            .opacity(shown ? 1 : 0)
            .onAppear { withAnimation(.smooth(duration: 0.45)) { shown = true } }
    }
}

/// Non-activating floating panel so the reminder never steals focus from what you are typing.
@MainActor
final class ReminderToastController {
    private var panel: NSPanel?

    /// Transparent room around the card for its shadow and the slide-in.
    private static let inset: CGFloat = 24
    /// Gap between the card and the screen edges (below the menu bar).
    private static let margin: CGFloat = 12

    func show(passage: Passage, theme: CardTheme, onRead: @escaping () -> Void, onLater: @escaping () -> Void) {
        dismiss(animated: false)
        let content = SlideIn {
            ReminderToastView(passage: passage, theme: theme,
                              onRead: { [weak self] in self?.dismiss(); onRead() },
                              onLater: { [weak self] in self?.dismiss(); onLater() },
                              onClose: { [weak self] in self?.dismiss() })
        }
        .padding(Self.inset)
        let hosting = NSHostingView(rootView: content)
        let size = hosting.fittingSize

        let panel = NSPanel(contentRect: NSRect(origin: .zero, size: size),
                            styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: false)
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.contentView = hosting

        // The window is placed once, already at its final spot. (Animating the window's origin never
        // finished on a non-activating panel and left the card stuck 40 pt to the right, off screen.)
        let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main ?? NSScreen.screens[0]
        let origin = FloatingPlacement.topRight(window: size, inset: Self.inset, margin: Self.margin, in: screen.visibleFrame)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        panel.orderFrontRegardless()
        self.panel = panel
    }

    /// Current window frame and the screen it is on (for the placement check in the demo).
    var placement: (window: NSRect, visible: NSRect)? {
        guard let panel, let screen = panel.screen else { return nil }
        return (panel.frame, screen.visibleFrame)
    }

    var isVisible: Bool { panel?.isVisible ?? false }

    func dismiss(animated: Bool = true) {
        guard let panel else { return }
        self.panel = nil
        guard animated else { panel.orderOut(nil); return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: {
            MainActor.assumeIsolated { panel.orderOut(nil) }
        })
    }
}
