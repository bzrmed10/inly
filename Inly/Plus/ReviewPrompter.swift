import Foundation
import Observation

/// Asks for an App Store rating only at happy moments (new tray, a week-long streak, goal met again),
/// never in the first days, at most every 4 months. Apple's own prompt also limits itself to 3 a year.
@MainActor
@Observable
final class ReviewPrompter {
    static let shared = ReviewPrompter()

    enum Moment { case newTray, streak, goalMet }

    /// RootView watches this and shows Apple's rating prompt when it turns true.
    var shouldAsk = false

    private let defaults = UserDefaults.standard
    private enum Key {
        static let firstLaunch = "reviewFirstLaunch"
        static let lastAsk = "reviewLastAsk"
        static let asks = "reviewAskCount"
    }

    private init() {
        if defaults.object(forKey: Key.firstLaunch) == nil { defaults.set(Date.now, forKey: Key.firstLaunch) }
    }

    var daysSinceFirstLaunch: Int {
        let first = defaults.object(forKey: Key.firstLaunch) as? Date ?? .now
        return Calendar.current.dateComponents([.day], from: first, to: .now).day ?? 0
    }

    func note(_ moment: Moment) {
        guard !ProcessInfo.processInfo.arguments.contains("-demoData") else { return }
        guard daysSinceFirstLaunch >= 3, defaults.integer(forKey: Key.asks) < 3 else { return }
        if let last = defaults.object(forKey: Key.lastAsk) as? Date, Date.now.timeIntervalSince(last) < 120 * 86_400 { return }
        defaults.set(Date.now, forKey: Key.lastAsk)
        defaults.set(defaults.integer(forKey: Key.asks) + 1, forKey: Key.asks)
        shouldAsk = true
    }
}
