import Foundation

/// "Decorar": hides the words of a passage a little more at each step.
public enum Memorize {
    /// Steps after the full text; the last one hides every word.
    public static let levels = 4

    public struct Word: Equatable, Sendable {
        /// Letters that get hidden.
        public let core: String
        /// Leading and trailing punctuation, always visible.
        public let prefix: String
        public let suffix: String
    }

    public static func words(_ text: String) -> [Word] {
        text.split(whereSeparator: \.isWhitespace).map { token in
            let s = String(token)
            let head = s.prefix { !$0.isLetter && !$0.isNumber }
            let rest = s.dropFirst(head.count)
            var core = String(rest)
            var tail = ""
            while let last = core.last, !last.isLetter, !last.isNumber {
                tail.insert(last, at: tail.startIndex)
                core.removeLast()
            }
            return Word(core: core, prefix: String(head), suffix: tail)
        }
    }

    /// Indices of words hidden at `level` (0 = none, `levels` = all). Each level keeps the words
    /// already hidden and adds more, in an order fixed by `seed` so the same passage always
    /// hides the same way.
    public static func hidden(wordCount: Int, level: Int, seed: UInt64) -> Set<Int> {
        let level = max(0, min(level, levels))
        let count = (wordCount * level + levels - 1) / levels
        var rng = SplitMix64(state: seed)
        var order = Array(0..<wordCount)
        order.shuffle(using: &rng)
        return Set(order.prefix(count))
    }

    /// Stable across launches (unlike `String.hashValue`): FNV-1a of the passage id.
    public static func seed(for id: String) -> UInt64 {
        id.utf8.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }

    struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
}
