import SwiftUI
import HoraDePausarCore

/// "Decorar": each step hides more words; tap a hidden word to peek at it.
struct MemorizeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let passage: Passage
    @State private var level: Int

    init(passage: Passage, startLevel: Int = 0) {
        self.passage = passage
        _level = State(initialValue: min(max(startLevel, 0), Memorize.levels))
    }
    @State private var revealed: Set<Int> = []
    private var theme: CardTheme { .calm(colorScheme) }

    private var words: [Memorize.Word] { Memorize.words(passage.text) }
    private var hidden: Set<Int> {
        Memorize.hidden(wordCount: words.count, level: level, seed: Memorize.seed(for: passage.id))
    }

    var body: some View {
        VStack(spacing: 22) {
            HStack {
                Eyebrow(text: "\(L("Decorar", "Memorize")) · \(passage.reference)", color: theme.accent, size: 11)
                Spacer()
                Text(level == 0 ? L("Texto completo", "Full text") : L("Etapa \(level) de \(Memorize.levels)", "Step \(level) of \(Memorize.levels)"))
                    .font(.system(size: 11.5))
                    .foregroundStyle(theme.secondaryInk)
            }
            ScrollView {
                FlowLayout(spacing: 7, lineSpacing: 10) {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                        WordView(word: word, isHidden: hidden.contains(index) && !revealed.contains(index), theme: theme)
                            .onTapGesture { if hidden.contains(index) { revealed.formSymmetricDifference([index]) } }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .subtleScrollIndicator()
            .frame(maxHeight: .infinity)
            HStack(spacing: 10) {
                Button(L("Fechar", "Close")) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button(L("Recomeçar", "Start over")) { change(to: 0) }
                    .disabled(level == 0)
                Button(level == Memorize.levels ? L("Tudo escondido", "All hidden") : L("Esconder mais", "Hide more")) { change(to: level + 1) }
                    .buttonStyle(.borderedProminent)
                    .tint(theme.accent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(level == Memorize.levels)
            }
        }
        .padding(26)
        .frame(width: 640, height: 440)
        .background(ThemeBackground(theme: theme).ignoresSafeArea())
        .environment(\.colorScheme, theme.isLight ? .light : .dark)
    }

    private func change(to newLevel: Int) {
        withAnimation(.snappy) {
            level = newLevel
            revealed = []
        }
    }
}

private struct WordView: View {
    let word: Memorize.Word
    let isHidden: Bool
    let theme: CardTheme

    var body: some View {
        HStack(spacing: 0) {
            Text(word.prefix)
            Text(word.core)
                .opacity(isHidden ? 0 : 1)
                .frame(minWidth: isHidden ? 22 : nil)
                .background {
                    if isHidden {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(theme.accent.opacity(0.18))
                            .strokeBorder(theme.accent.opacity(0.45), lineWidth: 0.75)
                            .padding(.vertical, 3)
                    }
                }
            Text(word.suffix)
        }
        .font(.serif(22))
        .foregroundStyle(theme.ink)
        .contentShape(Rectangle())
        .help(isHidden ? L("Toque para ver a palavra", "Click to see the word") : "")
    }
}

/// Lays children out left to right, wrapping to centered lines.
struct FlowLayout: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews: subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: .unspecified)
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func rows(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let added = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if added > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row(indices: [index], width: size.width, height: size.height)
            } else {
                current.indices.append(index)
                current.width = added
                current.height = max(current.height, size.height)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
