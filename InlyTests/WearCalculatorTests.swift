import Foundation
import Testing
@testable import Inly

struct WearCalculatorTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour, minute: minute))!
    }

    @Test func sessionIsSplitAtMidnight() {
        let s = SessionSpan(start: date(1, 23, 30), end: date(2, 0, 30))
        let day1 = WearCalculator.dayInterval(containing: date(1, 12), calendar: cal)
        let day2 = WearCalculator.dayInterval(containing: date(2, 12), calendar: cal)
        #expect(WearCalculator.outSeconds(in: day1, sessions: [s], now: date(3, 0)) == 1800)
        #expect(WearCalculator.outSeconds(in: day2, sessions: [s], now: date(3, 0)) == 1800)
    }

    @Test func openSessionCountsUntilNow() {
        let s = SessionSpan(start: date(1, 12), end: nil)
        let day = WearCalculator.dayInterval(containing: date(1, 12), calendar: cal)
        #expect(WearCalculator.outSeconds(in: day, sessions: [s], now: date(1, 12, 20)) == 1200)
    }

    @Test func snapshotBudgetLeft() {
        let sessions = [
            SessionSpan(start: date(1, 8), end: date(1, 8, 30)),
            SessionSpan(start: date(1, 12), end: nil),
        ]
        let snap = WearCalculator.snapshot(
            sessions: sessions, now: date(1, 12, 15), budgetSeconds: 7200, calendar: cal
        )
        #expect(snap.isOut)
        #expect(snap.outSeconds == 2700)
        #expect(snap.leftSeconds == 4500)
        #expect(!snap.isOverBudget)
        #expect(abs(snap.budgetUsed - 0.375) < 0.0001)
    }

    @Test func goalProgressIsWornOverGoal() {
        // 12:00, nothing out -> 12h worn of a 22h goal.
        let snap = WearCalculator.snapshot(sessions: [], now: date(1, 12), budgetSeconds: 7200, calendar: cal)
        #expect(abs(snap.goalProgress - 12.0 / 22.0) < 0.0001)
        #expect(abs(snap.wornFraction - 1.0) < 0.0001)
    }

    @Test func overBudgetClampsLeftToZero() {
        let sessions = [SessionSpan(start: date(1, 6), end: date(1, 9))]
        let snap = WearCalculator.snapshot(
            sessions: sessions, now: date(1, 10), budgetSeconds: 7200, calendar: cal
        )
        #expect(snap.isOverBudget)
        #expect(snap.leftSeconds == 0)
        #expect(!snap.isOut)
    }

    @Test func averageWornHoursOverTwoDays() {
        // Day 1: 2h out, day 2: 4h out -> worn 22h and 20h -> avg 21h.
        let sessions = [
            SessionSpan(start: date(1, 8), end: date(1, 10)),
            SessionSpan(start: date(2, 8), end: date(2, 12)),
        ]
        let avg = WearCalculator.averageWornHours(
            from: date(1, 0), to: date(3, 0), sessions: sessions, now: date(5, 0), calendar: cal
        )
        #expect(abs(avg - 21) < 0.0001)
    }
}

struct DailyWearTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test func dailyWearOldestFirstAndTodayPartial() {
        func date(_ d: Int, _ h: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 3, day: d, hour: h))! }
        let sessions = [SessionSpan(start: date(1, 8), end: date(1, 10))]
        let days = WearCalculator.dailyWear(endingOn: date(2, 12), days: 2, sessions: sessions, calendar: cal)
        #expect(days.count == 2)
        #expect(days[0].wornHours == 22)
        #expect(days[1].wornHours == 12)
        #expect(days[1].elapsedSeconds == 12 * 3600)
    }
}

struct DayWearAndGreetingTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ d: Int, _ h: Int, _ m: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 3, day: d, hour: h, minute: m))!
    }

    @Test func dayWearForPastDay() {
        let s = [SessionSpan(start: date(1, 12), end: date(1, 13, 30))]
        let w = WearCalculator.dayWear(on: date(1, 5), sessions: s, now: date(5, 0), calendar: cal)
        #expect(w.wornHours == 22.5)
        #expect(w.elapsedSeconds == 86_400)
    }

    @Test func overlapDetection() {
        let others = [SessionSpan(start: date(1, 12), end: date(1, 13))]
        #expect(WearCalculator.hasOverlap(start: date(1, 12, 30), end: date(1, 14), others: others, now: date(2, 0)))
        #expect(!WearCalculator.hasOverlap(start: date(1, 13), end: date(1, 14), others: others, now: date(2, 0)))
        let open = [SessionSpan(start: date(1, 20), end: nil)]
        #expect(WearCalculator.hasOverlap(start: date(1, 21), end: date(1, 22), others: open, now: date(1, 23)))
    }

    @Test func greetingByHour() {
        #expect(Greeting.phrase(for: date(1, 8), calendar: cal) == "Good morning")
        #expect(Greeting.phrase(for: date(1, 14), calendar: cal) == "Good afternoon")
        #expect(Greeting.phrase(for: date(1, 20), calendar: cal) == "Good evening")
        #expect(Greeting.phrase(for: date(1, 2), calendar: cal) == "Good evening")
    }
}

struct TrackingStartTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ d: Int, _ h: Int, _ m: Int = 0) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 3, day: d, hour: h, minute: m))!
    }

    @Test func firstDayCountsFromTrackingStart() {
        // Started tracking at 21:30, now 21:40, 9 minutes out -> only 1 minute worn, not 21h.
        let s = [SessionSpan(start: date(1, 21, 31), end: date(1, 21, 40))]
        let snap = WearCalculator.snapshot(
            sessions: s, now: date(1, 21, 40), budgetSeconds: 7200, calendar: cal, trackingStart: date(1, 21, 30)
        )
        #expect(snap.wornSeconds == 60)
        #expect(snap.outSeconds == 540)
    }

    @Test func daysBeforeTrackingHaveNoData() {
        let w = WearCalculator.dayWear(on: date(1, 12), sessions: [], now: date(3, 12), calendar: cal, trackingStart: date(2, 8))
        #expect(w.elapsedSeconds == 0)
        let w2 = WearCalculator.dayWear(on: date(2, 12), sessions: [], now: date(3, 12), calendar: cal, trackingStart: date(2, 8))
        #expect(w2.elapsedSeconds == 16 * 3600)
        #expect(w2.wornHours == 16)
    }
}
