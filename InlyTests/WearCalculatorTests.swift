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
