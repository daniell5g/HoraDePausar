import Foundation
@preconcurrency import UserNotifications
import HoraDePausarCore

/// The macOS notification flavor of the reminder; a click opens "Hoje".
final class NotificationPoster: NSObject {
    private let onOpen: () -> Void

    init(onOpen: @escaping () -> Void) {
        self.onOpen = onOpen
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    func post(_ passage: Passage) {
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = L("Hora de pausar", "Time to pause")
            content.subtitle = passage.reference
            content.body = passage.text
            content.sound = nil
            try? await center.add(UNNotificationRequest(identifier: "horadepausar.daily", content: content, trigger: nil))
        }
    }
}

extension NotificationPoster: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        await MainActor.run { self.onOpen() }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list]
    }
}
