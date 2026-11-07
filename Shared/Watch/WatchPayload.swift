import Foundation

/// What the iPhone tells the watch (and the commands the watch sends back). Plain Foundation so it builds on both.
struct WatchPayload: Codable, Sendable, Equatable {
    var isOut: Bool
    var outStart: Date
    var budgetEnd: Date
    var wornSeconds: TimeInterval
    var wornFraction: Double
    var leftSeconds: TimeInterval
    var goalHours: Int
    var trayLine: String?
    /// Language code (en, fr, ar, es) the watch should use, so it matches the iPhone.
    var language: String?

    static let payloadKey = "payload"
    static let commandKey = "command"
    static let takeOutCommand = "takeOut"
    static let putBackCommand = "putBackIn"

    init(isOut: Bool, outStart: Date, budgetEnd: Date, wornSeconds: TimeInterval, wornFraction: Double,
         leftSeconds: TimeInterval, goalHours: Int, trayLine: String?, language: String? = nil) {
        self.isOut = isOut; self.outStart = outStart; self.budgetEnd = budgetEnd
        self.wornSeconds = wornSeconds; self.wornFraction = wornFraction
        self.leftSeconds = leftSeconds; self.goalHours = goalHours; self.trayLine = trayLine
        self.language = language
    }

    var data: Data? { try? JSONEncoder().encode(self) }
    var dictionary: [String: Any] { data.map { [Self.payloadKey: $0] } ?? [:] }

    static func decode(_ data: Data?) -> WatchPayload? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(WatchPayload.self, from: data)
    }
}
