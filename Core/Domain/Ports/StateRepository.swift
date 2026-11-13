import Foundation

/// Where the user's `AppState` is kept. The domain and use cases only know this protocol;
/// the JSON file on disk (`JSONStateRepository`) is one implementation, tests use an in-memory one.
public protocol StateRepository {
    /// The saved state, or a fresh `AppState` when nothing was saved yet or it cannot be read.
    func load() -> AppState
    func save(_ state: AppState) throws
}
