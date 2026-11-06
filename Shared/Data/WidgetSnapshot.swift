import Foundation

/// A small copy of what the widgets need, kept in the App Group's UserDefaults.
/// Widgets read this instead of opening the SwiftData store, so they never fight the app over the database file.
struct WidgetSnapshot: Codable, Sendable, Equatable {
    struct Span: Codable, Sendable, Equatable {
        var start: Date
        var end: Date?
    }
    struct TrayInfo: Codable, Sendable, Equatable {
        var number: Int
        var startDate: Date
        var plannedDays: Int
    }

    /// Recent sessions only (the last few days plus any running one).
    var spans: [Span] = []
    var firstSessionStart: Date?
    var tray: TrayInfo?

    private static let key = "widgetSnapshot.v1"
    private static var defaults: UserDefaults { UserDefaults(suiteName: AppGroup.identifier) ?? .standard }

    static func load() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) { Self.defaults.set(data, forKey: Self.key) }
    }

    /// Keeps only sessions that can matter to "today" and the out-time budget.
    static func make(
        sessions: [SessionSpan], firstSessionStart: Date?, tray: TrayInfo?, now: Date = .now
    ) -> WidgetSnapshot {
        let cutoff = now.addingTimeInterval(-3 * 86_400)
        let recent = sessions
            .filter { $0.end == nil || ($0.end ?? .distantPast) >= cutoff }
            .map { Span(start: $0.start, end: $0.end) }
        return WidgetSnapshot(spans: recent, firstSessionStart: firstSessionStart, tray: tray)
    }
}
