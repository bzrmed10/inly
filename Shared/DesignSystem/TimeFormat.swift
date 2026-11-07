import Foundation

enum TimeFormat {
    /// "21h 40m" / "45m" / "0m"
    static func hoursMinutes(_ seconds: TimeInterval) -> String {
        L10n.hoursMinutes(seconds)
    }

    /// "1:05:09" or "05:09"
    static func clock(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }
}
