import Foundation

enum Greeting {
    /// "Good morning" before noon, "Good afternoon" until 6pm, otherwise "Good evening".
    static func phrase(for date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return L10n.t("Good morning")
        case 12..<18: return L10n.t("Good afternoon")
        default: return L10n.t("Good evening")
        }
    }
}
