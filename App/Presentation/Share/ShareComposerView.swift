import AppKit
import SwiftUI
import HoraDePausarCore

/// Window where the user styles the image and sends it out.
struct ShareComposerView: View {
    @Environment(DevotionStore.self) private var store
    var passage: Passage

    @State private var theme: CardTheme = .linho
    @State private var format: ShareFormat = .stories
    @State private var typeface: ShareTypeface = .classic
    @State private var rendered: NSImage?
    @State private var status: String?
    @State private var anchor = SharingAnchor.Reference()

    var body: some View {
        HStack(spacing: 0) {
            preview
            controls
                .frame(width: 300)
        }
        .frame(minWidth: 860, minHeight: 640)
        .onAppear {
            theme = store.cardTheme
            render()
        }
        .onChange(of: theme) { _, new in store.cardTheme = new; render() }
        .onChange(of: format) { render() }
        .onChange(of: typeface) { render() }
        .onChange(of: store.language) { render() }
    }

    private var preview: some View {
        ZStack {
            Color.dynamic(light: 0xE7E8E4, dark: 0x111417)
            if let rendered {
                Image(nsImage: rendered)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 16)
                    .padding(36)
                    .id(rendered)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: rendered)
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("Compartilhar", "Share"))
                    .font(.serif(26))
                Text(current.reference)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            section(L("Formato", "Format")) {
                Picker(L("Formato", "Format"), selection: $format) {
                    ForEach(ShareFormat.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Text(format.caption)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            section(L("Fundo", "Background")) {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(78), spacing: 10), count: 3), spacing: 10) {
                    ForEach(CardTheme.allCases) { option in
                        ThemeSwatch(theme: option, selected: option == theme) { theme = option }
                    }
                }
            }

            section(L("Letra", "Typeface")) {
                Picker(L("Letra", "Typeface"), selection: $typeface) {
                    ForEach(ShareTypeface.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    shareViaPicker()
                } label: {
                    Label(L("Compartilhar…", "Share…"), systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.extraLarge)
                .background(SharingAnchor(reference: anchor))

                HStack(spacing: 10) {
                    Button { airDrop() } label: {
                        Label("iPhone", systemImage: "airplayaudio").frame(maxWidth: .infinity)
                    }
                    .help(L("Enviar por AirDrop para o iPhone e postar no Stories ou Status", "Send to your iPhone with AirDrop and post to Stories or Status"))
                    Button { copy() } label: {
                        Label(L("Copiar", "Copy"), systemImage: "doc.on.doc").frame(maxWidth: .infinity)
                    }
                    Button { save() } label: {
                        Label(L("Salvar", "Save"), systemImage: "arrow.down.circle").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.large)

                Text(status ?? L("Dica: o macOS não publica direto no Stories do Instagram nem no Status do WhatsApp. Envie para o iPhone por AirDrop, ou copie e cole numa conversa.",
                                  "Tip: macOS can't post straight to Instagram Stories or WhatsApp Status. Send the image to your iPhone with AirDrop, or copy and paste it into a chat."))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .padding(.top, 18)
    }

    /// The passage in the current app language (the window may outlive a language change).
    private var current: Passage { store.passage(id: passage.id) ?? passage }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: title, size: 10)
            content()
        }
    }

    // MARK: - Actions

    private func render() {
        rendered = ShareRenderer.image(passage: current, theme: theme, format: format, typeface: typeface)
    }

    private func fileURL() -> URL? {
        guard let rendered else { return nil }
        return ShareRenderer.temporaryFile(image: rendered, passage: current)
    }

    private func shareViaPicker() {
        guard let url = fileURL(), let view = anchor.view else { return }
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    private func airDrop() {
        guard let url = fileURL() else { return }
        if let service = NSSharingService(named: .sendViaAirDrop), service.canPerform(withItems: [url]) {
            service.perform(withItems: [url])
        } else {
            status = L("AirDrop indisponível agora. Ative o Bluetooth e o Wi‑Fi e tente de novo.", "AirDrop isn't available right now. Turn on Bluetooth and Wi‑Fi and try again.")
        }
    }

    private func copy() {
        guard let rendered else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([rendered])
        status = L("Imagem copiada. Cole (⌘V) numa conversa do WhatsApp ou onde quiser.", "Image copied. Paste it (⌘V) into a WhatsApp chat or anywhere you like.")
    }

    private func save() {
        guard let rendered, let data = ShareRenderer.pngData(rendered) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = ShareRenderer.fileName(for: current)
        panel.directoryURL = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try data.write(to: url, options: .atomic)
                status = L("Salvo em", "Saved to") + " \(url.deletingLastPathComponent().lastPathComponent)/\(url.lastPathComponent)."
            } catch {
                status = L("Não consegui salvar: ", "Couldn't save: ") + error.localizedDescription
            }
        }
    }
}

struct ThemeSwatch: View {
    var theme: CardTheme
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ThemeBackground(theme: theme)
                    .frame(width: 78, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(selected ? Brand.accent : Color.primary.opacity(0.12), lineWidth: selected ? 2.5 : 0.5)
                    }
                Text(theme.title)
                    .font(.system(size: 10.5, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? .primary : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Exposes the NSView behind a SwiftUI button so the share picker can anchor to it.
struct SharingAnchor: NSViewRepresentable {
    final class Reference { weak var view: NSView? }
    var reference: Reference

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        reference.view = view
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) { reference.view = nsView }
}
