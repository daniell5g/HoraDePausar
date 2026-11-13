import Foundation

/// Command-line switches for screenshots and review runs (Debug builds only; a Release build
/// always starts with none, so the app people install cannot be steered by arguments).
///
///     -StateFile <file>   use this state file instead of the real history
///     -Demo <surface>     open menu|toast|settings|main|main-close|note|memorize|journal|share
///     -DemoLevel <n>      start "Decorar" n steps in
///     -Snapshot <dir>     save every open window as PNG, then quit
///     -Export <dir>       write today's share image in every theme and format, then quit
struct LaunchOptions {
    var stateFile: URL?
    var demo: String?
    var memorizeLevel = 0
    var snapshotDir: URL?
    var exportDir: URL?

    /// Screenshot/export runs, which must leave the real install alone.
    var isToolingRun: Bool { demo != nil || exportDir != nil }

    static var current: LaunchOptions {
        #if DEBUG
        let defaults = UserDefaults.standard
        let url = { (key: String) in defaults.string(forKey: key).map { URL(fileURLWithPath: $0) } }
        return LaunchOptions(stateFile: url("StateFile"),
                             demo: defaults.string(forKey: "Demo"),
                             memorizeLevel: defaults.integer(forKey: "DemoLevel"),
                             snapshotDir: url("Snapshot"),
                             exportDir: url("Export"))
        #else
        return LaunchOptions()
        #endif
    }
}
