import ActivityKit
import Foundation

/// Live Activity shown while the aligners are out.
/// Timers use `timerInterval` so the system counts without any app updates.
struct InlyActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var reasonRaw: String
    }

    /// When the aligners came out.
    var outStart: Date
    /// When today's out-time budget runs out (`outStart + budget left`).
    var budgetEnd: Date
}
