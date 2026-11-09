import Foundation

/// Streaks and the estimated finish date. Pure maths so it is easy to test.
enum Insights {
    struct Streak: Equatable, Sendable {
        var current: Int
        var best: Int
    }

    /// Days in a row where the wear goal was reached.
    /// - `days` are oldest first and end with today.
    /// - A finished day counts when its worn share reaches goal/24 (so the partial first day counts fairly).
    /// - Days with under an hour of tracking (before tracking began) count as "no data" and end a run.
    /// - Today adds to the streak once it is met, but never breaks it while the day is still in progress.
    static func streak(days: [DayWear], goalHours: Int, today: Date, calendar: Calendar) -> Streak {
        let todayStart = calendar.startOfDay(for: today)
        let need = Double(goalHours) / 24
        var run = 0
        var best = 0
        for d in days {
            let isToday = calendar.startOfDay(for: d.day) == todayStart
            guard d.elapsedSeconds >= 3600 else { run = 0; continue }
            let met = d.wornSeconds / d.elapsedSeconds >= need - 1e-9
            if isToday {
                if met { run += 1 }
            } else if met {
                run += 1
            } else {
                run = 0
            }
            best = max(best, run)
        }
        return Streak(current: run, best: best)
    }

    struct WeekScore: Equatable, Sendable {
        var met: Int
        var target: Int
        /// 0...1
        var fraction: Double { target == 0 ? 0 : min(1, Double(met) / Double(target)) }
    }

    /// How many of the last 7 days reached the goal. `nightsPerWeek` caps the target for "a few nights a week" retainer use.
    /// Days before tracking began are ignored, and today only counts once it is met.
    static func weekScore(days: [DayWear], goalHours: Int, nightsPerWeek: Int? = nil, today: Date, calendar: Calendar) -> WeekScore {
        let todayStart = calendar.startOfDay(for: today)
        let need = Double(goalHours) / 24
        var met = 0
        var counted = 0
        for d in days.suffix(7) {
            guard d.elapsedSeconds >= 3600 else { continue }
            let ok = d.wornSeconds / d.elapsedSeconds >= need - 1e-9
            if calendar.startOfDay(for: d.day) == todayStart {
                if ok { met += 1; counted += 1 }
            } else {
                counted += 1
                if ok { met += 1 }
            }
        }
        let target = nightsPerWeek.map { min($0, max(counted, 1)) } ?? max(counted, 1)
        return WeekScore(met: met, target: target)
    }

    struct Forecast: Equatable, Sendable {
        var finishDate: Date
        var traysLeft: Int
        var daysLeft: Int
    }

    /// When the last tray ends if every remaining tray gets its planned days.
    /// An overdue current tray is assumed to be switched today.
    static func forecast(
        currentStart: Date, plannedDays: Int, currentNumber: Int,
        totalTrays: Int, defaultDays: Int, now: Date, calendar: Calendar
    ) -> Forecast? {
        guard totalTrays >= currentNumber, currentNumber >= 1 else { return nil }
        let today = calendar.startOfDay(for: now)
        let due = TrayLogic.switchDate(start: currentStart, plannedDays: plannedDays, calendar: calendar)
        let currentEnds = max(due, today)
        let traysLeft = totalTrays - currentNumber
        guard let finish = calendar.date(byAdding: .day, value: traysLeft * max(1, defaultDays), to: currentEnds) else { return nil }
        let daysLeft = calendar.dateComponents([.day], from: today, to: finish).day ?? 0
        return Forecast(finishDate: finish, traysLeft: traysLeft, daysLeft: max(0, daysLeft))
    }
}
