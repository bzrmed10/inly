import Foundation

/// A plain value copy of a session, safe to pass anywhere.
struct SessionSpan: Sendable, Equatable {
    var start: Date
    var end: Date?
}

struct WearSnapshot: Sendable, Equatable {
    var isOut: Bool
    /// Seconds out today (including a running session).
    var outSeconds: TimeInterval
    /// Seconds worn so far today.
    var wornSeconds: TimeInterval
    var budgetSeconds: TimeInterval
    /// Budget remaining (never below 0).
    var leftSeconds: TimeInterval
    var isOverBudget: Bool
    /// 0...1: share of the daily out budget that has been used.
    var budgetUsed: Double
    /// 0...1: share of the day's elapsed time worn.
    var wornFraction: Double
}

enum WearCalculator {
    static func dayInterval(containing date: Date, calendar: Calendar) -> DateInterval {
        let start = calendar.startOfDay(for: date)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        return DateInterval(start: start, end: end)
    }

    /// Seconds out inside `interval`. Open sessions count up to `now`.
    static func outSeconds(in interval: DateInterval, sessions: [SessionSpan], now: Date) -> TimeInterval {
        var total: TimeInterval = 0
        for s in sessions {
            let end = s.end ?? now
            let lo = max(s.start, interval.start)
            let hi = min(end, interval.end)
            if hi > lo { total += hi.timeIntervalSince(lo) }
        }
        return total
    }

    static func snapshot(
        sessions: [SessionSpan],
        now: Date,
        budgetSeconds: TimeInterval,
        calendar: Calendar
    ) -> WearSnapshot {
        let day = dayInterval(containing: now, calendar: calendar)
        let out = outSeconds(in: day, sessions: sessions, now: now)
        let elapsed = max(1, min(now, day.end).timeIntervalSince(day.start))
        let worn = max(0, elapsed - out)
        let isOut = sessions.contains { $0.end == nil && $0.start <= now }
        let left = max(0, budgetSeconds - out)
        return WearSnapshot(
            isOut: isOut,
            outSeconds: out,
            wornSeconds: worn,
            budgetSeconds: budgetSeconds,
            leftSeconds: left,
            isOverBudget: out > budgetSeconds,
            budgetUsed: budgetSeconds > 0 ? min(1, out / budgetSeconds) : 1,
            wornFraction: min(1, worn / elapsed)
        )
    }

    /// Average hours worn per full day between `start` and `end` (or now).
    /// Days are counted by calendar day; the last, partial day counts only elapsed time.
    static func averageWornHours(
        from start: Date,
        to end: Date,
        sessions: [SessionSpan],
        now: Date,
        calendar: Calendar
    ) -> Double {
        let upper = min(end, now)
        guard upper > start else { return 0 }
        var cursor = calendar.startOfDay(for: start)
        var wornTotal: TimeInterval = 0
        var elapsedTotal: TimeInterval = 0
        while cursor < upper {
            let day = dayInterval(containing: cursor, calendar: calendar)
            let lo = max(day.start, start)
            let hi = min(day.end, upper)
            if hi > lo {
                let window = DateInterval(start: lo, end: hi)
                let out = outSeconds(in: window, sessions: sessions, now: now)
                wornTotal += window.duration - out
                elapsedTotal += window.duration
            }
            cursor = day.end
        }
        guard elapsedTotal > 0 else { return 0 }
        return (wornTotal / elapsedTotal) * 24
    }
}
