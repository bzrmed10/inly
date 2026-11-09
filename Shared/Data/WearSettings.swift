import Foundation

/// User settings stored in the App Group so the app and widgets agree.
enum RetainerSchedule: String, CaseIterable, Sendable {
    case fullTime, nightly, fewNights
}

struct WearSettings: Sendable, Equatable {
    var goalHours: Int = 22
    var totalTrays: Int = 24
    var defaultTrayDays: Int = 14
    var remindersEnabled: Bool = true
    var userName: String = ""
    var onboardingDone: Bool = false
    /// When tracking really began (end of setup). Time before this is never counted as worn.
    var trackingStart: Date?
    /// Next orthodontist visit, if the user entered one.
    var nextAppointment: Date?
    /// Minutes after which to ask "still out?", per reason (OutReason raw value). 0 = off.
    var stillOutMinutes: [String: Int] = WearSettings.defaultStillOut
    /// Planned trays of every finished phase (key = phase number). The current phase uses `totalTrays`.
    var phaseTotals: [Int: Int] = [:]
    /// Retainer mode: treatment is over and Inly tracks the retainer instead.
    var retainerMode = false
    var retainerStart: Date?
    var retainerSchedule: RetainerSchedule = .nightly
    /// Hours of wear per day while in retainer mode (nightly and few-nights schedules).
    var retainerHours = 8
    /// Nights per week for the few-nights schedule.
    var retainerNights = 4
    /// The treatment goal to restore if the user leaves retainer mode.
    var treatmentGoalHours: Int?
    var bedtimeReminder = true
    /// Minutes after midnight.
    var bedtimeMinutes = 22 * 60 + 30

    /// True when the aligners are only worn at night, so "out" nudges would be noise.
    var isNightRetainer: Bool { retainerMode && retainerSchedule != .fullTime }

    static let defaultStillOut: [String: Int] = ["meal": 45, "brushing": 10, "drink": 15, "other": 30]

    func stillOut(for reason: OutReason) -> Int {
        stillOutMinutes[reason.rawValue] ?? Self.defaultStillOut[reason.rawValue] ?? 30
    }

    mutating func setStillOut(_ minutes: Int, for reason: OutReason) {
        stillOutMinutes[reason.rawValue] = minutes
    }

    var goalSeconds: TimeInterval { TimeInterval(goalHours) * 3600 }
    /// Allowed time out of the mouth per day.
    var budgetSeconds: TimeInterval { 86_400 - goalSeconds }

    private enum Key {
        static let goal = "goalHours"
        static let total = "totalTrays"
        static let days = "defaultTrayDays"
        static let reminders = "remindersEnabled"
        static let name = "userName"
        static let onboarded = "onboardingDone"
        static let tracking = "trackingStart"
        static let stillOut = "stillOutMinutes"
        static let appointment = "nextAppointment"
        static let phaseTotals = "phaseTotals"
        static let retainerMode = "retainerMode"
        static let retainerStart = "retainerStart"
        static let retainerSchedule = "retainerSchedule"
        static let retainerHours = "retainerHours"
        static let retainerNights = "retainerNights"
        static let treatmentGoal = "treatmentGoalHours"
        static let bedtimeReminder = "bedtimeReminder"
        static let bedtimeMinutes = "bedtimeMinutes"
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: AppGroup.identifier) ?? .standard
    }

    static func load() -> WearSettings {
        let d = defaults
        var s = WearSettings()
        if d.object(forKey: Key.goal) != nil { s.goalHours = d.integer(forKey: Key.goal) }
        if d.object(forKey: Key.total) != nil { s.totalTrays = d.integer(forKey: Key.total) }
        if d.object(forKey: Key.days) != nil { s.defaultTrayDays = d.integer(forKey: Key.days) }
        if d.object(forKey: Key.reminders) != nil { s.remindersEnabled = d.bool(forKey: Key.reminders) }
        s.userName = d.string(forKey: Key.name) ?? ""
        s.onboardingDone = d.bool(forKey: Key.onboarded)
        if d.object(forKey: Key.tracking) != nil { s.trackingStart = Date(timeIntervalSince1970: d.double(forKey: Key.tracking)) }
        if d.object(forKey: Key.appointment) != nil { s.nextAppointment = Date(timeIntervalSince1970: d.double(forKey: Key.appointment)) }
        if let saved = d.dictionary(forKey: Key.stillOut) as? [String: Int] {
            s.stillOutMinutes.merge(saved) { _, new in new }
        }
        if let totals = d.dictionary(forKey: Key.phaseTotals) as? [String: Int] {
            s.phaseTotals = Dictionary(uniqueKeysWithValues: totals.compactMap { k, v in Int(k).map { ($0, v) } })
        }
        if d.object(forKey: Key.retainerMode) != nil { s.retainerMode = d.bool(forKey: Key.retainerMode) }
        if d.object(forKey: Key.retainerStart) != nil { s.retainerStart = Date(timeIntervalSince1970: d.double(forKey: Key.retainerStart)) }
        if let raw = d.string(forKey: Key.retainerSchedule), let v = RetainerSchedule(rawValue: raw) { s.retainerSchedule = v }
        if d.object(forKey: Key.retainerHours) != nil { s.retainerHours = d.integer(forKey: Key.retainerHours) }
        if d.object(forKey: Key.retainerNights) != nil { s.retainerNights = d.integer(forKey: Key.retainerNights) }
        if d.object(forKey: Key.treatmentGoal) != nil { s.treatmentGoalHours = d.integer(forKey: Key.treatmentGoal) }
        if d.object(forKey: Key.bedtimeReminder) != nil { s.bedtimeReminder = d.bool(forKey: Key.bedtimeReminder) }
        if d.object(forKey: Key.bedtimeMinutes) != nil { s.bedtimeMinutes = d.integer(forKey: Key.bedtimeMinutes) }
        return s
    }

    /// Forget everything (used by UI tests that need a first launch).
    static func reset() {
        let d = defaults
        for k in [Key.goal, Key.total, Key.days, Key.reminders, Key.name, Key.onboarded, Key.tracking, Key.stillOut, Key.appointment, Key.phaseTotals, Key.retainerMode, Key.retainerStart, Key.retainerSchedule, Key.retainerHours, Key.retainerNights, Key.treatmentGoal, Key.bedtimeReminder, Key.bedtimeMinutes] { d.removeObject(forKey: k) }
    }

    func save() {
        let d = Self.defaults
        d.set(goalHours, forKey: Key.goal)
        d.set(totalTrays, forKey: Key.total)
        d.set(defaultTrayDays, forKey: Key.days)
        d.set(remindersEnabled, forKey: Key.reminders)
        d.set(userName, forKey: Key.name)
        d.set(onboardingDone, forKey: Key.onboarded)
        d.set(stillOutMinutes, forKey: Key.stillOut)
        d.set(Dictionary(uniqueKeysWithValues: phaseTotals.map { (String($0.key), $0.value) }), forKey: Key.phaseTotals)
        d.set(retainerMode, forKey: Key.retainerMode)
        if let retainerStart { d.set(retainerStart.timeIntervalSince1970, forKey: Key.retainerStart) } else { d.removeObject(forKey: Key.retainerStart) }
        d.set(retainerSchedule.rawValue, forKey: Key.retainerSchedule)
        d.set(retainerHours, forKey: Key.retainerHours)
        d.set(retainerNights, forKey: Key.retainerNights)
        if let treatmentGoalHours { d.set(treatmentGoalHours, forKey: Key.treatmentGoal) } else { d.removeObject(forKey: Key.treatmentGoal) }
        d.set(bedtimeReminder, forKey: Key.bedtimeReminder)
        d.set(bedtimeMinutes, forKey: Key.bedtimeMinutes)
        if let nextAppointment { d.set(nextAppointment.timeIntervalSince1970, forKey: Key.appointment) } else { d.removeObject(forKey: Key.appointment) }
        if let trackingStart { d.set(trackingStart.timeIntervalSince1970, forKey: Key.tracking) } else { d.removeObject(forKey: Key.tracking) }
    }
}

extension WearSettings {
    /// The moment tracking began: the saved one, else the first logged break, else unknown.
    func resolvedTrackingStart(firstSession: Date?) -> Date? {
        trackingStart ?? firstSession
    }
}

extension WearSettings {
    /// Sets the daily goal that matches the retainer schedule (nights use `retainerHours`).
    mutating func applyRetainerGoal() {
        guard retainerMode else { return }
        goalHours = retainerHours
    }
}
