import Foundation
import UserNotifications

/// Local reminders while the aligners are out: a heads-up before the budget ends, and one when it has.
enum OutReminders {
    private static let ids = ["out-soon", "out-over"]

    static func schedule(budgetEnd: Date, now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)

        let soon = budgetEnd.addingTimeInterval(-10 * 60)
        if soon > now.addingTimeInterval(5) {
            add(center, id: "out-soon", at: soon,
                title: "10 minutes of out-time left",
                body: "Time to wrap up and put your aligners back in.")
        }
        if budgetEnd > now.addingTimeInterval(5) {
            add(center, id: "out-over", at: budgetEnd,
                title: "Put your aligners back in",
                body: "Today's out-time budget is used up.")
        }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    private static func add(_ center: UNUserNotificationCenter, id: String, at date: Date, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let interval = max(1, date.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
