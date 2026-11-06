import Foundation
import UserNotifications

/// One reminder to schedule. Pure data so the timing can be unit-tested.
struct PlannedReminder: Equatable, Sendable {
    let id: String
    let date: Date
    let title: String
    let body: String
}

/// Local reminders while the aligners are out: "still out?" nudges for the chosen reason,
/// a heads-up before the daily budget ends, and one when it has.
enum OutReminders {
    static let categoryID = "OUT"
    static let putBackActionID = "PUT_BACK_IN"
    private static let ids = ["out-soon", "out-over", "out-still-1", "out-still-2"]

    /// Works out which reminders to schedule. `stillOutMinutes` of 0 turns the "still out?" nudge off.
    static func plan(
        outStart: Date, reason: OutReason, stillOutMinutes: Int, budgetEnd: Date, now: Date
    ) -> [PlannedReminder] {
        var result: [PlannedReminder] = []
        let floor = now.addingTimeInterval(5)

        if stillOutMinutes > 0 {
            let name = reason == .other ? "Your aligners" : "Your aligners (\(reason.title.lowercased()))"
            for n in 1...2 {
                let at = outStart.addingTimeInterval(TimeInterval(stillOutMinutes * 60 * n))
                guard at > floor else { continue }
                result.append(PlannedReminder(
                    id: "out-still-\(n)", date: at,
                    title: n == 1 ? "Still out?" : "Still out. Time to put them back?",
                    body: "\(name) have been out for \(stillOutMinutes * n) minutes."
                ))
            }
        }

        let soon = budgetEnd.addingTimeInterval(-10 * 60)
        if soon > floor {
            result.append(PlannedReminder(
                id: "out-soon", date: soon,
                title: "10 minutes of out-time left",
                body: "Time to wrap up and put your aligners back in."
            ))
        }
        if budgetEnd > floor {
            result.append(PlannedReminder(
                id: "out-over", date: budgetEnd,
                title: "Put your aligners back in",
                body: "Today's out-time budget is used up."
            ))
        }
        return result
    }

    static func schedule(outStart: Date, reason: OutReason, budgetEnd: Date, now: Date = .now) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        let settings = WearSettings.load()
        guard settings.remindersEnabled else { return }

        let planned = plan(
            outStart: outStart, reason: reason, stillOutMinutes: settings.stillOut(for: reason),
            budgetEnd: budgetEnd, now: now
        )
        for p in planned { add(center, p) }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// Registers the "Put back in" button shown on these notifications.
    static func registerCategory() {
        let action = UNNotificationAction(identifier: putBackActionID, title: "Put back in", options: [])
        let category = UNNotificationCategory(identifier: categoryID, actions: [action], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private static func add(_ center: UNUserNotificationCenter, _ p: PlannedReminder) {
        let content = UNMutableNotificationContent()
        content.title = p.title
        content.body = p.body
        content.sound = .default
        content.categoryIdentifier = categoryID
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, p.date.timeIntervalSinceNow), repeats: false)
        center.add(UNNotificationRequest(identifier: p.id, content: content, trigger: trigger))
    }
}

/// Handles taps on the "Put back in" button, and shows reminders even while the app is open.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        guard response.actionIdentifier == OutReminders.putBackActionID else { return }
        await MainActor.run { SessionService.shared.putBackIn() }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
