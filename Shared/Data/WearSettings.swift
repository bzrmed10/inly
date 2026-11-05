import Foundation

/// User settings stored in the App Group so the app and widgets agree.
struct WearSettings: Sendable, Equatable {
    var goalHours: Int = 22
    var totalTrays: Int = 24
    var defaultTrayDays: Int = 14
    var remindersEnabled: Bool = true

    var goalSeconds: TimeInterval { TimeInterval(goalHours) * 3600 }
    /// Allowed time out of the mouth per day.
    var budgetSeconds: TimeInterval { 86_400 - goalSeconds }

    private enum Key {
        static let goal = "goalHours"
        static let total = "totalTrays"
        static let days = "defaultTrayDays"
        static let reminders = "remindersEnabled"
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
        return s
    }

    func save() {
        let d = Self.defaults
        d.set(goalHours, forKey: Key.goal)
        d.set(totalTrays, forKey: Key.total)
        d.set(defaultTrayDays, forKey: Key.days)
        d.set(remindersEnabled, forKey: Key.reminders)
    }
}
