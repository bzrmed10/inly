import Foundation
import Testing
@testable import Inly

struct TrayLogicTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func d(_ day: Int, _ hour: Int = 12) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 3, day: day, hour: hour))!
    }

    @Test func dayNumberStartsAtOne() {
        #expect(TrayLogic.dayNumber(start: d(1, 20), now: d(1, 23), calendar: cal) == 1)
        #expect(TrayLogic.dayNumber(start: d(1, 20), now: d(9, 1), calendar: cal) == 9)
    }

    @Test func finishedTrayDays() {
        #expect(TrayLogic.daysSpent(start: d(1), end: d(15), now: d(20), calendar: cal) == 14)
        #expect(TrayLogic.daysSpent(start: d(1), end: d(1, 18), now: d(20), calendar: cal) == 1)
    }

    @Test func switchDateIsStartPlusPlan() {
        let s = TrayLogic.switchDate(start: d(1, 18), plannedDays: 14, calendar: cal)
        #expect(cal.component(.day, from: s) == 15)
    }

    @Test func timing() {
        #expect(TrayLogic.timing(start: d(1), plannedDays: 14, switchingOn: d(13), calendar: cal) == .early(days: 2))
        #expect(TrayLogic.timing(start: d(1), plannedDays: 14, switchingOn: d(15), calendar: cal) == .onTime)
        #expect(TrayLogic.timing(start: d(1), plannedDays: 14, switchingOn: d(17), calendar: cal) == .late(days: 2))
    }

    @Test func overageStartsAfterSwitchDay() {
        #expect(TrayLogic.overage(start: d(1), plannedDays: 14, now: d(14), calendar: cal) == 0)
        #expect(TrayLogic.overage(start: d(1), plannedDays: 14, now: d(15), calendar: cal) == 0)
        #expect(TrayLogic.overage(start: d(1), plannedDays: 14, now: d(17), calendar: cal) == 2)
    }

    @Test func daysUntilSwitch() {
        #expect(TrayLogic.daysUntilSwitch(start: d(1), plannedDays: 14, now: d(10), calendar: cal) == 5)
        #expect(TrayLogic.daysUntilSwitch(start: d(1), plannedDays: 14, now: d(15), calendar: cal) == 0)
        #expect(TrayLogic.daysUntilSwitch(start: d(1), plannedDays: 14, now: d(16), calendar: cal) == -1)
    }
}
