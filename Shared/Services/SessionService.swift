import Foundation
import SwiftData
import WidgetKit

/// Single entry point for changing wear state. Used by the app, intents and (later) widgets.
@MainActor
final class SessionService {
    static let shared = SessionService()

    let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer = DataStore.makeContainer()) {
        self.container = container
    }

    // MARK: Queries

    func openSession() -> WearSession? {
        var d = FetchDescriptor<WearSession>(
            predicate: #Predicate { $0.end == nil },
            sortBy: [SortDescriptor(\.start, order: .reverse)]
        )
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    func allSpans() -> [SessionSpan] {
        let all = (try? context.fetch(FetchDescriptor<WearSession>())) ?? []
        return all.map { SessionSpan(start: $0.start, end: $0.end) }
    }

    // MARK: Actions

    @discardableResult
    func takeOut(reason: OutReason = .other, at date: Date = .now) -> WearSession {
        if let existing = openSession() { return existing }
        let s = WearSession(start: date, reason: reason)
        context.insert(s)
        save()
        return s
    }

    func putBackIn(at date: Date = .now) {
        guard let s = openSession() else { return }
        s.end = max(date, s.start)
        save()
    }

    func setReason(_ reason: OutReason) {
        openSession()?.reason = reason
        save()
    }

    /// Makes sure there is always a current tray (tray 1 on first launch).
    func ensureTray() {
        let count = (try? context.fetchCount(FetchDescriptor<Tray>())) ?? 0
        guard count == 0 else { return }
        let settings = WearSettings.load()
        context.insert(Tray(number: 1, startDate: Calendar.current.startOfDay(for: .now), plannedDays: settings.defaultTrayDays))
        save()
    }

    private func save() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
