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
        content.title = L10n.t("Time for tray %d", next)
        content.body = L10n.t("Tray %d has had its %d days. Switch when you're ready, then log it in Inly.", tray.number, tray.plannedDays)
        content.sound = .default
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }
}


/// Reminders for the next orthodontist visit: the evening before and the morning of.
enum AppointmentReminders {
    private static let ids = ["appt-eve", "appt-morning"]

    struct Planned: Equatable, Sendable { let id: String; let date: Date; let title: String; let body: String }

    static func plan(for appointment: Date, now: Date = .now, calendar: Calendar = .current) -> [Planned] {
        var result: [Planned] = []
        let time = L10n.time(appointment)
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: appointment))
        if let dayBefore, let eve = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: dayBefore), eve > now {
            result.append(Planned(id: "appt-eve", date: eve, title: L10n.t("Orthodontist tomorrow"),
                                  body: L10n.t("Your appointment is at %@. Bring your current and previous trays.", time)))
        }
        if let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: appointment),
           morning > now, morning < appointment.addingTimeInterval(-30 * 60) {
            result.append(Planned(id: "appt-morning", date: morning, title: L10n.t("Orthodontist today"),
                                  body: L10n.t("Appointment at %@. Keep your aligners in until you arrive.", time)))
        }
        return result
    }

    static func schedule(_ appointment: Date?) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)
        guard let appointment else { return }
        for p in plan(for: appointment) {
            let content = UNMutableNotificationContent()
            content.title = p.title
            content.body = p.body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, p.date.timeIntervalSinceNow), repeats: false)
            center.add(UNNotificationRequest(identifier: p.id, content: content, trigger: trigger))
        }
    }
}
