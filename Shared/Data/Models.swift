import Foundation
import SwiftData

enum OutReason: String, CaseIterable, Codable, Sendable {
    case meal, brushing, drink, other

    var title: String {
        switch self {
        case .meal: "Meal"
        case .brushing: "Brushing"
        case .drink: "Drink"
        case .other: "Other"
        }
    }

    var symbol: String {
        switch self {
        case .meal: "fork.knife"
        case .brushing: "sparkles"
        case .drink: "cup.and.saucer.fill"
        case .other: "ellipsis"
        }
    }
}

/// One period during which the aligners were OUT. `end == nil` means still out.
@Model
final class WearSession {
    var start: Date = Date.now
    var end: Date?
    var reasonRaw: String = OutReason.other.rawValue

    init(start: Date, end: Date? = nil, reason: OutReason = .other) {
        self.start = start
        self.end = end
        self.reasonRaw = reason.rawValue
    }

    var reason: OutReason {
        get { OutReason(rawValue: reasonRaw) ?? .other }
        set { reasonRaw = newValue.rawValue }
    }
}

/// One aligner tray. `endDate == nil` means it is the current tray.
@Model
final class Tray {
    var number: Int = 1
    var startDate: Date = Date.now
    var endDate: Date?
    var plannedDays: Int = 14
    /// Progress photo for this tray (stored outside the database file).
    @Attribute(.externalStorage) var photoData: Data?

    init(number: Int, startDate: Date, endDate: Date? = nil, plannedDays: Int = 14) {
        self.number = number
        self.startDate = startDate
        self.endDate = endDate
        self.plannedDays = plannedDays
    }
}

/// A short note about a tray, e.g. "sore teeth". Linked by tray number so deleting a tray never loses notes by accident.
@Model
final class TrayNote {
    var trayNumber: Int = 1
    var date: Date = Date.now
    var text: String = ""

    init(trayNumber: Int, text: String, date: Date = .now) {
        self.trayNumber = trayNumber
        self.text = text
        self.date = date
    }
}
