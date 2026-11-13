import Foundation

/// Random draw that avoids repeating anything shown recently.
public enum PassagePicker {
    /// Picks uniformly among passages not in `recent` (oldest → newest). When every passage of the
    /// pool was shown recently, returns the one seen longest ago, so a pick always exists.
    public static func pick<G: RandomNumberGenerator>(from pool: [Passage], avoiding recent: [String], using rng: inout G) -> Passage? {
        guard !pool.isEmpty else { return nil }
        let excluded = Set(recent)
        if let fresh = pool.filter({ !excluded.contains($0.id) }).randomElement(using: &rng) { return fresh }
        var lastSeen: [String: Int] = [:]
        for (index, id) in recent.enumerated() { lastSeen[id] = index }
        return pool.min { (lastSeen[$0.id] ?? -1) < (lastSeen[$1.id] ?? -1) }
    }
}
