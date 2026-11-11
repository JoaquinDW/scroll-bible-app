// Not part of the app target yet. Add a "Shield Action Extension" target, then use this file.
import ManagedSettings
import UserNotifications

/// Handles the "Read to unlock" tap. iOS does not let a shield open another app directly,
/// so we post a notification that deep-links to lumen://session when tapped.
final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler)
    }

    private func respond(to action: ShieldAction, _ completionHandler: @escaping (ShieldActionResponse) -> Void) {
        guard action == .primaryButtonPressed else {
            completionHandler(.close)
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "Lumen"
        content.body = "Tap to open today's reading."
        content.userInfo = ["url": "lumen://session"]
        let request = UNNotificationRequest(identifier: "shield.read", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in
            completionHandler(.close)
        }
    }
}
