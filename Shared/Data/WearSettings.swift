import Foundation

/// User settings stored in the App Group so the app and widgets agree.
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
        return s
    }

    /// Forget everything (used by UI tests that need a first launch).
    static func reset() {
        let d = defaults
        for k in [Key.goal, Key.total, Key.days, Key.reminders, Key.name, Key.onboarded, Key.tracking, Key.stillOut, Key.appointment] { d.removeObject(forKey: k) }
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
