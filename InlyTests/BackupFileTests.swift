import Foundation
import Testing
@testable import Inly

struct BackupFileTests {
    private func sample() -> BackupFile {
        var s = WearSettings()
        s.userName = "Sam"
        s.goalHours = 21
        s.totalTrays = 30
        s.nextAppointment = Date(timeIntervalSince1970: 1_800_000_000)
        s.setStillOut(5, for: .meal)
        return BackupFile(
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            settings: .init(s),
            sessions: [
                .init(start: Date(timeIntervalSince1970: 1_700_000_100), end: Date(timeIntervalSince1970: 1_700_001_000), reason: "meal"),
                .init(start: Date(timeIntervalSince1970: 1_700_002_000), end: nil, reason: "other"),
            ],
            trays: [.init(number: 3, startDate: Date(timeIntervalSince1970: 1_699_000_000), endDate: nil, plannedDays: 14, photo: Data([1, 2, 3]))],
            notes: [.init(trayNumber: 3, date: Date(timeIntervalSince1970: 1_700_000_500), text: "sore teeth")]
        )
    }

    @Test func roundTrip() throws {
        let file = sample()
        let back = try BackupFile.decode(file.encoded())
        #expect(back == file)
    }

    @Test func settingsApplyKeepsValues() {
        let applied = sample().settings.apply()
        #expect(applied.userName == "Sam")
        #expect(applied.goalHours == 21)
        #expect(applied.totalTrays == 30)
        #expect(applied.stillOut(for: .meal) == 5)
        #expect(applied.onboardingDone)
    }

    @Test func rejectsGarbage() {
        #expect(throws: BackupFile.BackupError.self) { try BackupFile.decode(Data("nope".utf8)) }
    }

    @Test func rejectsNewerVersion() throws {
        var file = sample()
        file.version = BackupFile.currentVersion + 1
        #expect(throws: BackupFile.BackupError.self) { try BackupFile.decode(file.encoded()) }
    }
}
