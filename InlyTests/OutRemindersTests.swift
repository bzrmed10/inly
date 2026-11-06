import Foundation
import Testing
@testable import Inly

struct OutRemindersTests {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    @Test func stillOutFiresAfterChosenMinutes() {
        let plan = OutReminders.plan(
            outStart: start, reason: .brushing, stillOutMinutes: 10,
            budgetEnd: start.addingTimeInterval(3 * 3600), now: start
        )
        let first = plan.first { $0.id == "out-still-1" }
        #expect(first?.date == start.addingTimeInterval(600))
        #expect(plan.contains { $0.id == "out-still-2" && $0.date == start.addingTimeInterval(1200) })
    }

    @Test func zeroMinutesTurnsStillOutOff() {
        let plan = OutReminders.plan(
            outStart: start, reason: .meal, stillOutMinutes: 0,
            budgetEnd: start.addingTimeInterval(3600), now: start
        )
        #expect(!plan.contains { $0.id.hasPrefix("out-still") })
        #expect(plan.contains { $0.id == "out-over" })
    }

    @Test func pastRemindersAreSkipped() {
        let plan = OutReminders.plan(
            outStart: start, reason: .drink, stillOutMinutes: 15,
            budgetEnd: start.addingTimeInterval(1800), now: start.addingTimeInterval(1000)
        )
        #expect(!plan.contains { $0.id == "out-still-1" })
        #expect(plan.contains { $0.id == "out-still-2" })
    }

    @Test func defaultsPerReason() {
        let s = WearSettings()
        #expect(s.stillOut(for: .brushing) == 10)
        #expect(s.stillOut(for: .meal) == 45)
    }
}

struct AppointmentReminderTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test func remindsEveningBeforeAndMorningOf() {
        let appt = cal.date(from: DateComponents(year: 2026, month: 12, day: 10, hour: 14))!
        let now = cal.date(from: DateComponents(year: 2026, month: 12, day: 1, hour: 9))!
        let plan = AppointmentReminders.plan(for: appt, now: now, calendar: cal)
        #expect(plan.map(\.id) == ["appt-eve", "appt-morning"])
        #expect(plan[0].date == cal.date(from: DateComponents(year: 2026, month: 12, day: 9, hour: 18)))
        #expect(plan[1].date == cal.date(from: DateComponents(year: 2026, month: 12, day: 10, hour: 8)))
    }

    @Test func skipsRemindersAlreadyInThePast() {
        let appt = cal.date(from: DateComponents(year: 2026, month: 12, day: 10, hour: 14))!
        let now = cal.date(from: DateComponents(year: 2026, month: 12, day: 10, hour: 9))!
        #expect(AppointmentReminders.plan(for: appt, now: now, calendar: cal).isEmpty)
    }
}
