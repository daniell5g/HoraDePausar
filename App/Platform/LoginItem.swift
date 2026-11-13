import Foundation
import ServiceManagement

/// "Abrir ao iniciar o Mac". macOS remembers the login item by where the app lives, so when the app
/// moves (renamed folder, a fresh copy from the .dmg dragged to Aplicativos) the registration is
/// renewed from wherever the app runs now.
enum LoginItem {
    private static let wantedKey = "LaunchAtLoginWanted"
    private static let pathKey = "LaunchAtLoginPath"

    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ enable: Bool) throws {
        if enable { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        let defaults = UserDefaults.standard
        defaults.set(enable, forKey: wantedKey)
        if enable { defaults.set(Bundle.main.bundleURL.path, forKey: pathKey) } else { defaults.removeObject(forKey: pathKey) }
    }

    /// At launch: if the person turned it on, make sure it opens this copy of the app.
    static func followAppLocation() {
        let defaults = UserDefaults.standard
        let wanted = defaults.object(forKey: wantedKey) as? Bool ?? isEnabled
        guard wanted, defaults.string(forKey: pathKey) != Bundle.main.bundleURL.path else { return }
        try? SMAppService.mainApp.unregister()
        do { try set(true) } catch { NSLog("Login item: could not register: \(error)") }
    }
}
