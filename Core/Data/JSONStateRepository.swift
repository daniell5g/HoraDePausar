import Foundation

/// Persists `AppState` as pretty-printed JSON with ISO-8601 dates, written atomically.
public struct JSONStateRepository: StateRepository {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() -> AppState {
        guard let data = try? Data(contentsOf: fileURL),
              let state = try? Self.decoder.decode(AppState.self, from: data) else { return AppState() }
        return state
    }

    public func save(_ state: AppState) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Self.encoder.encode(state).write(to: fileURL, options: .atomic)
    }

    static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
