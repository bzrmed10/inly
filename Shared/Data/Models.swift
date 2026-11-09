import Foundation
import SwiftData

enum OutReason: String, CaseIterable, Codable, Sendable {
    case meal, brushing, drink, other

    var title: String {
        switch self {
        case .meal: L10n.t("Meal")
        case .brushing: L10n.t("Brushing")
        case .drink: L10n.t("Drink")
        case .other: L10n.t("Other")
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
    var reasonRaw: String = OutReason.meal.rawValue

    init(start: Date, end: Date? = nil, reason: OutReason = .meal) {
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
    /// 0 = initial treatment, 1 = refinement 1, ... Trays saved before phases existed read as 0.
    var phase: Int = 0
    /// `number` stays unique across the whole treatment (notes and photos rely on it);
    /// the number the user sees restarts in each phase: `number - phaseBase`.
    var phaseBase: Int = 0

    init(number: Int, startDate: Date, endDate: Date? = nil, plannedDays: Int = 14, phase: Int = 0, phaseBase: Int = 0) {
        self.number = number
        self.startDate = startDate
        self.endDate = endDate
        self.plannedDays = plannedDays
        self.phase = phase
        self.phaseBase = phaseBase
    }

    /// The tray number shown to the user (restarts at 1 in every phase).
    var displayNumber: Int { max(1, number - phaseBase) }
}

extension Tray {
    /// "Tray 3" or "Refinement 1 · Tray 3".
    var fullLabel: String {
        phase > 0 ? L10n.t("Refinement %d · Tray %d", phase, displayNumber) : L10n.t("Tray %d", displayNumber)
    }
}

enum TreatmentPhase {
    /// "Initial treatment", "Refinement 1", ...
    static func name(_ phase: Int) -> String {
        phase <= 0 ? L10n.t("Initial treatment") : L10n.t("Refinement %d", phase)
    }
    static var retainerName: String { L10n.t("Retainer") }
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
