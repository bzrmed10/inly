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
    /// When the numbers above were true (worn time keeps growing after that while the aligners are in).
    var asOf: Date?
    /// Inly+ unlocked on the iPhone. Missing (older iPhone app) reads as unlocked.
    var plus: Bool?

    static let payloadKey = "payload"
    static let commandKey = "command"
    static let takeOutCommand = "takeOut"
    static let putBackCommand = "putBackIn"

    init(isOut: Bool, outStart: Date, budgetEnd: Date, wornSeconds: TimeInterval, wornFraction: Double,
         leftSeconds: TimeInterval, goalHours: Int, trayLine: String?, language: String? = nil,
         asOf: Date? = nil, plus: Bool? = nil) {
        self.isOut = isOut; self.outStart = outStart; self.budgetEnd = budgetEnd
        self.wornSeconds = wornSeconds; self.wornFraction = wornFraction
        self.leftSeconds = leftSeconds; self.goalHours = goalHours; self.trayLine = trayLine
        self.language = language
        self.asOf = asOf; self.plus = plus
    }

    var isPlus: Bool { plus ?? true }

    /// Worn seconds at a later moment while the aligners stay in (restarts at midnight).
    func wornSeconds(at date: Date, calendar: Calendar = .current) -> TimeInterval {
        guard !isOut, let asOf, date > asOf else { return wornSeconds }
        let dayStart = calendar.startOfDay(for: date)
        if dayStart > asOf { return date.timeIntervalSince(dayStart) }
        return wornSeconds + date.timeIntervalSince(asOf)
    }

    func wornFraction(at date: Date) -> Double {
        let goal = Double(max(1, goalHours)) * 3600
        return min(1, max(0, wornSeconds(at: date) / goal))
    }

    // MARK: Shared copy on the watch (read by the complications)

    static let storeKey = "watchPayload.v1"
    private static var groupDefaults: UserDefaults { UserDefaults(suiteName: AppGroup.identifier) ?? .standard }

    static func loadShared() -> WatchPayload? { decode(groupDefaults.data(forKey: storeKey)) }
    func saveShared() { if let data { Self.groupDefaults.set(data, forKey: Self.storeKey) } }

    var data: Data? { try? JSONEncoder().encode(self) }
    var dictionary: [String: Any] { data.map { [Self.payloadKey: $0] } ?? [:] }

    static func decode(_ data: Data?) -> WatchPayload? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(WatchPayload.self, from: data)
    }
}
