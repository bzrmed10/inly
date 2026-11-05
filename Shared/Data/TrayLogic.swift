import Foundation

/// Pure tray date maths (no database), so it is easy to test.
enum TrayLogic {
    enum Timing: Equatable, Sendable {
        case early(days: Int)
        case onTime
        case late(days: Int)
    }

    /// 1-based day number on the tray for `now` (day 1 = the start date).
    static func dayNumber(start: Date, now: Date, calendar: Calendar) -> Int {
        let d = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: now)).day ?? 0
        return max(1, d + 1)
    }

    /// Days spent on a tray. Finished trays count start -> switch date (at least 1).
    static func daysSpent(start: Date, end: Date?, now: Date, calendar: Calendar) -> Int {
        guard let end else { return dayNumber(start: start, now: now, calendar: calendar) }
        let d = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: end)).day ?? 0
        return max(1, d)
    }

    /// The day the next tray is due (start + planned days).
    static func switchDate(start: Date, plannedDays: Int, calendar: Calendar) -> Date {
        let s = calendar.startOfDay(for: start)
        return calendar.date(byAdding: .day, value: plannedDays, to: s) ?? s
    }

    /// Is switching on `date` early, on time or late compared with the plan?
    static func timing(start: Date, plannedDays: Int, switchingOn date: Date, calendar: Calendar) -> Timing {
        let spent = daysSpent(start: start, end: date, now: date, calendar: calendar)
        if spent < plannedDays { return .early(days: plannedDays - spent) }
        if spent > plannedDays { return .late(days: spent - plannedDays) }
        return .onTime
    }

    /// Whole calendar days since the tray was started (0 on the start day).
    static func daysElapsed(start: Date, now: Date, calendar: Calendar) -> Int {
        let d = calendar.dateComponents([.day], from: calendar.startOfDay(for: start), to: calendar.startOfDay(for: now)).day ?? 0
        return max(0, d)
    }

    /// Extra days beyond the plan: 0 until the switch day, then +1, +2 ... (same maths as history).
    static func overage(start: Date, plannedDays: Int, now: Date, calendar: Calendar) -> Int {
        max(0, daysElapsed(start: start, now: now, calendar: calendar) - plannedDays)
    }

    /// Days until the switch day. 0 = switch today, negative = overdue.
    static func daysUntilSwitch(start: Date, plannedDays: Int, now: Date, calendar: Calendar) -> Int {
        plannedDays - daysElapsed(start: start, now: now, calendar: calendar)
    }
}
