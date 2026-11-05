import Foundation
import UserNotifications

/// One reminder on the day the next tray is due.
enum TrayNotifications {
    static let identifier = "tray-switch"

    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func scheduleSwitchReminder(for tray: Tray, calendar: Calendar = .current) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard tray.endDate == nil, WearSettings.load().remindersEnabled else { return }

        let day = TrayLogic.switchDate(start: tray.startDate, plannedDays: tray.plannedDays, calendar: calendar)
        var comps = calendar.dateComponents([.year, .month, .day], from: day)
        comps.hour = 9
        guard let fire = calendar.date(from: comps), fire > .now else { return }

        let next = tray.number + 1
        let content = UNMutableNotificationContent()
        content.title = "Time for tray \(next)"
        content.body = "Tray \(tray.number) has had its \(tray.plannedDays) days. Switch when you're ready, then log it in Inly."
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}
