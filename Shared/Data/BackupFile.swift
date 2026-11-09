import Foundation

/// Everything Inly knows, in one portable file (JSON). Used for iCloud Drive / Files backups.
struct BackupFile: Codable, Equatable, Sendable {
    static let currentVersion = 2

    struct Settings: Codable, Equatable, Sendable {
        var goalHours: Int
        var totalTrays: Int
        var defaultTrayDays: Int
        var remindersEnabled: Bool
        var userName: String
        var trackingStart: Date?
        var nextAppointment: Date?
        var stillOutMinutes: [String: Int]
        // Added in version 2. Missing in older backups, which then read as "initial treatment, no retainer".
        var phaseTotals: [String: Int]?
        var retainerMode: Bool?
        var retainerStart: Date?
        var retainerSchedule: String?
        var retainerHours: Int?
        var retainerNights: Int?
        var treatmentGoalHours: Int?
        var bedtimeReminder: Bool?
        var bedtimeMinutes: Int?

        init(_ s: WearSettings) {
            phaseTotals = Dictionary(uniqueKeysWithValues: s.phaseTotals.map { (String($0.key), $0.value) })
            retainerMode = s.retainerMode
            retainerStart = s.retainerStart
            retainerSchedule = s.retainerSchedule.rawValue
            retainerHours = s.retainerHours
            retainerNights = s.retainerNights
            treatmentGoalHours = s.treatmentGoalHours
            bedtimeReminder = s.bedtimeReminder
            bedtimeMinutes = s.bedtimeMinutes
            goalHours = s.goalHours
            totalTrays = s.totalTrays
            defaultTrayDays = s.defaultTrayDays
            remindersEnabled = s.remindersEnabled
            userName = s.userName
            trackingStart = s.trackingStart
            nextAppointment = s.nextAppointment
            stillOutMinutes = s.stillOutMinutes
        }

        func apply() -> WearSettings {
            var s = WearSettings()
            s.goalHours = goalHours
            s.totalTrays = totalTrays
            s.defaultTrayDays = defaultTrayDays
            s.remindersEnabled = remindersEnabled
            s.userName = userName
            s.trackingStart = trackingStart
            s.nextAppointment = nextAppointment
            s.stillOutMinutes.merge(stillOutMinutes) { _, new in new }
            if let phaseTotals { s.phaseTotals = Dictionary(uniqueKeysWithValues: phaseTotals.compactMap { k, v in Int(k).map { ($0, v) } }) }
            if let retainerMode { s.retainerMode = retainerMode }
            s.retainerStart = retainerStart
            if let raw = retainerSchedule, let v = RetainerSchedule(rawValue: raw) { s.retainerSchedule = v }
            if let retainerHours { s.retainerHours = retainerHours }
            if let retainerNights { s.retainerNights = retainerNights }
            s.treatmentGoalHours = treatmentGoalHours
            if let bedtimeReminder { s.bedtimeReminder = bedtimeReminder }
            if let bedtimeMinutes { s.bedtimeMinutes = bedtimeMinutes }
            s.onboardingDone = true
            return s
        }
    }

    struct Session: Codable, Equatable, Sendable {
        var start: Date
        var end: Date?
        var reason: String
    }

    struct TrayEntry: Codable, Equatable, Sendable {
        var number: Int
        var startDate: Date
        var endDate: Date?
        var plannedDays: Int
        var photo: Data?
        // Added in version 2 (missing = initial treatment).
        var phase: Int?
        var phaseBase: Int?
    }

    struct Note: Codable, Equatable, Sendable {
        var trayNumber: Int
        var date: Date
        var text: String
    }

    var version: Int = BackupFile.currentVersion
    var createdAt: Date
    var settings: Settings
    var sessions: [Session]
    var trays: [TrayEntry]
    var notes: [Note]

    enum BackupError: Error, LocalizedError {
        case unreadable, newerVersion
        var errorDescription: String? {
            switch self {
            case .unreadable: L10n.t("This file isn't an Inly backup.")
            case .newerVersion: L10n.t("This backup was made by a newer version of Inly. Update the app first.")
            }
        }
    }

    func encoded() throws -> Data {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return try e.encode(self)
    }

    static func decode(_ data: Data) throws -> BackupFile {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        guard let file = try? d.decode(BackupFile.self, from: data) else { throw BackupError.unreadable }
        guard file.version <= currentVersion else { throw BackupError.newerVersion }
        return file
    }
}
