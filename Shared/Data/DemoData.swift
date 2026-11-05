import Foundation
import SwiftData

/// Launch-argument driven demo data, used by the screenshot UI tests only.
enum DemoData {
    static var isEnabled: Bool { ProcessInfo.processInfo.arguments.contains("-demoData") }
    static var startsOut: Bool { ProcessInfo.processInfo.arguments.contains("-demoOut") }

    @MainActor
    static func seed(_ context: ModelContext, now: Date = .now) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        context.insert(Tray(number: 7, startDate: cal.date(byAdding: .day, value: -8, to: today) ?? today, plannedDays: 14))
        func at(_ h: Int, _ m: Int) -> Date { cal.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now }
        if at(8, 35) < now {
            context.insert(WearSession(start: at(8, 0), end: at(8, 35), reason: .meal))
        }
        if at(13, 5) < now {
            context.insert(WearSession(start: at(12, 30), end: at(13, 5), reason: .meal))
        }
        if startsOut {
            context.insert(WearSession(start: now.addingTimeInterval(-14 * 60 - 12), reason: .meal))
        }
        try? context.save()
    }
}
