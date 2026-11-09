import Foundation
import Testing
@testable import Inly

struct PhaseTests {
    private func date(_ days: Int) -> Date { Date(timeIntervalSince1970: 1_700_000_000 + Double(days) * 86_400) }

    @Test func trayNumbersRestartInEachPhase() {
        let a = Tray(number: 15, startDate: date(0))
        #expect(a.displayNumber == 15)
        let b = Tray(number: 16, startDate: date(1), phase: 1, phaseBase: 15)
        #expect(b.displayNumber == 1)
        #expect(b.fullLabel.contains("1"))
    }

    /// A backup made before phases existed must still load, with everything in the initial treatment.
    @Test func oldBackupLoadsAsInitialTreatment() throws {
        let json = """
        {"version":1,"createdAt":"2024-01-01T00:00:00Z",
         "settings":{"goalHours":22,"totalTrays":24,"defaultTrayDays":14,"remindersEnabled":true,"userName":"Sam","stillOutMinutes":{"meal":45}},
         "sessions":[{"start":"2024-01-01T08:00:00Z","end":"2024-01-01T09:00:00Z","reason":"meal"}],
         "trays":[{"number":3,"startDate":"2023-12-20T00:00:00Z","plannedDays":14}],
         "notes":[{"trayNumber":3,"date":"2023-12-25T00:00:00Z","text":"sore"}]}
        """
        let file = try BackupFile.decode(Data(json.utf8))
        #expect(file.trays.count == 1)
        #expect(file.trays[0].phase == nil)
        #expect(file.trays[0].number == 3)
        let s = file.settings.apply()
        #expect(s.retainerMode == false)
        #expect(s.phaseTotals.isEmpty)
        #expect(s.totalTrays == 24)
        #expect(file.notes[0].text == "sore")
    }

    @Test func phaseAndRetainerSettingsRoundTrip() throws {
        var s = WearSettings()
        s.phaseTotals = [0: 22]
        s.retainerMode = true
        s.retainerSchedule = .fewNights
        s.retainerHours = 9
        s.retainerNights = 3
        s.treatmentGoalHours = 22
        let file = BackupFile(
            createdAt: date(0), settings: .init(s), sessions: [],
            trays: [.init(number: 16, startDate: date(1), endDate: nil, plannedDays: 7, photo: nil, phase: 1, phaseBase: 15)],
            notes: []
        )
        let back = try BackupFile.decode(file.encoded())
        let applied = back.settings.apply()
        #expect(applied.phaseTotals == [0: 22])
        #expect(applied.retainerMode)
        #expect(applied.retainerSchedule == .fewNights)
        #expect(applied.retainerHours == 9)
        #expect(applied.retainerNights == 3)
        #expect(back.trays[0].phase == 1)
        #expect(back.trays[0].phaseBase == 15)
    }

    @Test func retainerGoalFollowsSchedule() {
        var s = WearSettings()
        s.goalHours = 22
        s.retainerMode = true
        s.retainerHours = 8
        s.applyRetainerGoal()
        #expect(s.goalHours == 8)
        #expect(s.isNightRetainer == false || s.retainerSchedule != .fullTime)
    }

    @Test func weekScoreCountsGoalDays() {
        let cal = Calendar(identifier: .gregorian)
        let start = cal.startOfDay(for: Date(timeIntervalSince1970: 1_700_000_000))
        let days: [DayWear] = (0..<7).map { i in
            let day = cal.date(byAdding: .day, value: i, to: start)!
            return DayWear(day: day, wornSeconds: i < 5 ? 23 * 3600 : 10 * 3600, elapsedSeconds: 86_400)
        }
        let today = cal.date(byAdding: .day, value: 7, to: start)!
        let score = Insights.weekScore(days: days, goalHours: 22, today: today, calendar: cal)
        #expect(score.met == 5)
        #expect(score.target == 7)
        let nights = Insights.weekScore(days: days, goalHours: 22, nightsPerWeek: 4, today: today, calendar: cal)
        #expect(nights.target == 4)
        #expect(nights.fraction == 1)
    }

    @Test func defaultOutReasonIsMeal() {
        #expect(WearSession(start: .now).reason == .meal)
    }
}
