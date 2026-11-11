import Foundation
import UserNotifications

/// One daily reminder, always worded as an invitation. Never guilt.
enum NotificationService {
    private static let identifier = "daily.invitation"

    /// Asks for permission (once) and schedules the daily invitation.
    @MainActor
    static func enable(for profile: UserProfile) {
        let message = content(for: profile)
        let hour = profile.reminderHour, minute = profile.reminderMinute
        Task {
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            schedule(title: message.title, body: message.body, hour: hour, minute: minute)
        }
    }

    /// Re-schedules with fresh wording, or clears the reminder when it is off.
    @MainActor
    static func refresh(for profile: UserProfile) {
        guard profile.remindersOn else {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
            return
        }
        let message = content(for: profile)
        schedule(title: message.title, body: message.body, hour: profile.reminderHour, minute: profile.reminderMinute)
    }

    @MainActor
    private static func content(for profile: UserProfile) -> (title: String, body: String) {
        let lang = profile.language
        let journey = ContentStore.shared.journey(profile.currentJourneyID)
        let topic = journey?.title.t(lang) ?? Brand.name
        return (Brand.name, Copy.notificationBody.f(lang, profile.displaySheepName, topic))
    }

    private static func schedule(title: String, body: String, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        var when = DateComponents()
        when.hour = hour
        when.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
