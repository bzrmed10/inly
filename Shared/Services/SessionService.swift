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

    func isOut() -> Bool { openSession() != nil }

    func toggle() {
        if isOut() { putBackIn() } else { takeOut() }
    }

    // MARK: Actions

    func takeOut(reason: OutReason = .other, at date: Date = .now) {
        if openSession() != nil { return }
        context.insert(WearSession(start: date, reason: reason))
        save()
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
        if DemoData.isEnabled {
            DemoData.seed(context)
            return
        }
        let count = (try? context.fetchCount(FetchDescriptor<Tray>())) ?? 0
        guard count == 0 else { return }
        let settings = WearSettings.load()
        context.insert(Tray(number: 1, startDate: Calendar.current.startOfDay(for: .now), plannedDays: settings.defaultTrayDays))
        save()
    }

    // MARK: Trays

    struct TrayUndo: Sendable {
        let newTrayID: PersistentIdentifier
        let closedTrayID: PersistentIdentifier?
    }

    func currentTray() -> Tray? {
        var d = FetchDescriptor<Tray>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        d.fetchLimit = 1
        return try? context.fetch(d).first
    }

    /// Closes the current tray on `date` and starts the next one.
    @discardableResult
    func startNextTray(on date: Date, plannedDays: Int) -> TrayUndo {
        let all = (try? context.fetch(FetchDescriptor<Tray>())) ?? []
        let current = all.first(where: { $0.endDate == nil })
        current?.endDate = max(date, current?.startDate ?? date)
        let number = (all.map(\.number).max() ?? 0) + 1
        let tray = Tray(number: number, startDate: date, plannedDays: plannedDays)
        context.insert(tray)
        save()
        TrayNotifications.scheduleSwitchReminder(for: tray)
        return TrayUndo(newTrayID: tray.persistentModelID, closedTrayID: current?.persistentModelID)
    }

    func undoStartTray(_ undo: TrayUndo) {
        if let closed = undo.closedTrayID, let t = context.model(for: closed) as? Tray {
            t.endDate = nil
            TrayNotifications.scheduleSwitchReminder(for: t)
        }
        if let n = context.model(for: undo.newTrayID) as? Tray {
            context.delete(n)
        }
        save()
    }

    /// Align the Live Activity with stored state (call on launch, foreground and after changes).
    func reconcileLiveActivity(now: Date = .now) {
        let open = openSession()
        var left: TimeInterval = 0
        if let open {
            let others = allSpans().filter { $0.start != open.start }
            let snap = WearCalculator.snapshot(
                sessions: others, now: open.start,
                budgetSeconds: WearSettings.load().budgetSeconds, calendar: .current
            )
            left = snap.leftSeconds
        }
        if let open {
            OutReminders.schedule(budgetEnd: open.start.addingTimeInterval(max(1, left)), now: now)
        } else {
            OutReminders.cancel()
        }
        let start = open?.start
        let reason = open?.reasonRaw ?? OutReason.other.rawValue
        Task {
            await LiveActivityController.reconcile(outStart: start, reasonRaw: reason, budgetLeftAtStart: left)
        }
    }

    private func save() {
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
        ControlCenter.shared.reloadAllControls()
        reconcileLiveActivity()
    }
}
