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

struct WearStatusTests {
    @Test func buildsStatusWhileOut() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let snap = WidgetSnapshot(
            spans: [
                .init(start: now.addingTimeInterval(-86_400 * 2), end: now.addingTimeInterval(-86_400 * 2 + 3600)),
                .init(start: now.addingTimeInterval(-600), end: nil),
            ],
            firstSessionStart: now.addingTimeInterval(-86_400 * 2),
            tray: .init(number: 3, startDate: now.addingTimeInterval(-86_400 * 4), plannedDays: 14)
        )
        let status = WearStatus.make(from: snap, settings: WearSettings(), now: now)
        #expect(status.isOut)
        #expect(status.budgetEnd > now)
        #expect(status.trayLine?.hasPrefix("Tray 3") == true)
    }

    @Test func snapshotRoundTrips() throws {
        let snap = WidgetSnapshot(spans: [.init(start: .now, end: nil)], firstSessionStart: .now, tray: nil)
        let data = try JSONEncoder().encode(snap)
        #expect(try JSONDecoder().decode(WidgetSnapshot.self, from: data).spans.count == 1)
    }
}

struct InsightsTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func day(_ n: Int, worn: Double, elapsed: Double = 24) -> DayWear {
        DayWear(day: cal.date(from: DateComponents(year: 2026, month: 3, day: n))!, wornSeconds: worn * 3600, elapsedSeconds: elapsed * 3600)
    }
    private var today: Date { cal.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 15))! }

    @Test func streakCountsDaysMeetingTheGoal() {
        let days = [day(5, worn: 20), day(6, worn: 22.5), day(7, worn: 23), day(8, worn: 22), day(9, worn: 22.1), day(10, worn: 5, elapsed: 15)]
        let s = Insights.streak(days: days, goalHours: 22, today: today, calendar: cal)
        #expect(s.current == 4)
        #expect(s.best == 4)
    }

    @Test func missedDayBreaksTheStreakButTodayInProgressDoesNot() {
        let days = [day(6, worn: 23), day(7, worn: 23), day(8, worn: 18), day(9, worn: 23), day(10, worn: 4, elapsed: 15)]
        let s = Insights.streak(days: days, goalHours: 22, today: today, calendar: cal)
        #expect(s.current == 1)
        #expect(s.best == 2)
    }

    @Test func finishDateAddsRemainingTrays() throws {
        let start = cal.date(from: DateComponents(year: 2026, month: 3, day: 1))!
        let f = try #require(Insights.forecast(
            currentStart: start, plannedDays: 14, currentNumber: 3, totalTrays: 5, defaultDays: 14, now: today, calendar: cal
        ))
        #expect(f.traysLeft == 2)
        #expect(f.finishDate == cal.date(from: DateComponents(year: 2026, month: 4, day: 12)))
    }

    @Test func overdueTrayIsAssumedSwitchedToday() throws {
        let start = cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let f = try #require(Insights.forecast(
            currentStart: start, plannedDays: 14, currentNumber: 4, totalTrays: 4, defaultDays: 14, now: today, calendar: cal
        ))
        #expect(f.finishDate == cal.startOfDay(for: today))
    }
}

struct ReportBuilderTests {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    @Test func dailyCSVHasHeaderAndOneRowPerDay() {
        let now = cal.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!
        let start = cal.date(from: DateComponents(year: 2026, month: 3, day: 7))!
        let breakStart = cal.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 12))!
        let spans = [SessionSpan(start: breakStart, end: breakStart.addingTimeInterval(3600))]
        let input = ReportBuilder.Input(
            name: "A", goalHours: 22, from: start, now: now, trackingStart: start, spans: spans,
            breaks: [], trays: [], notes: [], appointment: nil, calendar: cal
        )
        let lines = ReportBuilder.dailyCSV(input).split(separator: "\n").map(String.init)
        #expect(lines.first == "date,hours_worn,hours_out,goal_hours,goal_met,day_complete")
        #expect(lines.count == 5)
        #expect(lines[2].hasPrefix("2026-03-08,23.00,1.00,22,yes,yes"))
    }

    @Test func breaksCSVListsMinutesAndEscapes() {
        let now = cal.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))!
        let s = cal.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 8))!
        let input = ReportBuilder.Input(
            name: "", goalHours: 22, from: s.addingTimeInterval(-86_400), now: now, trackingStart: nil, spans: [],
            breaks: [.init(start: s, end: s.addingTimeInterval(1800), reason: "Meal, lunch")], trays: [], notes: [], appointment: nil, calendar: cal
        )
        let csv = ReportBuilder.breaksCSV(input)
        #expect(csv.contains("2026-03-09 08:00,2026-03-09 08:30,30,\"Meal, lunch\""))
    }

    @Test func pdfIsGenerated() {
        let now = Date.now
        let input = ReportBuilder.Input(
            name: "Test", goalHours: 22, from: now.addingTimeInterval(-5 * 86_400), now: now,
            trackingStart: now.addingTimeInterval(-5 * 86_400), spans: [], breaks: [],
            trays: [.init(number: 1, start: now.addingTimeInterval(-5 * 86_400), end: nil, plannedDays: 14)],
            notes: [.init(trayNumber: 1, date: now, text: "Sore teeth")], appointment: nil
        )
        let data = ReportBuilder.pdf(input)
        #expect(data.count > 1000)
        #expect(String(decoding: data.prefix(4), as: UTF8.self) == "%PDF")
    }
}
