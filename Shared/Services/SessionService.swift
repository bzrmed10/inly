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

    enum LastToggle: Sendable {
        case tookOut(start: Date)
        case putBack(start: Date)
    }
    private(set) var lastToggle: LastToggle?

    func takeOut(reason: OutReason = .other, at date: Date = .now) {
        if openSession() != nil { return }
        context.insert(WearSession(start: date, reason: reason))
        lastToggle = .tookOut(start: date)
        save()
    }

    func putBackIn(at date: Date = .now) {
        guard let s = openSession() else { return }
        s.end = max(date, s.start)
        lastToggle = .putBack(start: s.start)
        save()
    }

    /// Reverts the last Take out / Put back in (for accidental taps).
    func undoLastToggle() {
        guard let last = lastToggle else { return }
        lastToggle = nil
        switch last {
        case .tookOut(let start):
            if let s = openSession(), s.start == start { context.delete(s) }
        case .putBack(let start):
            let all = (try? context.fetch(FetchDescriptor<WearSession>())) ?? []
            if let s = all.first(where: { $0.start == start }) { s.end = nil }
        }
        save()
    }

    // MARK: Editing sessions

    func addSession(start: Date, end: Date, reason: OutReason) {
        context.insert(WearSession(start: start, end: end, reason: reason))
        save()
    }

    func delete(_ session: WearSession) {
        context.delete(session)
        save()
    }

    /// Call after changing a session's fields in a view.
    func commit() { save() }

    func setReason(_ reason: OutReason) {
        openSession()?.reason = reason
        save()
    }

    /// Demo / fresh-start launch arguments (UI tests). Real users go through setup instead.
    func ensureTray() {
        if DemoData.isEnabled {
            DemoData.seed(context)
        } else if ProcessInfo.processInfo.arguments.contains("-freshStart") {
            WearSettings.reset()
        }
    }

    /// First-launch setup: replaces any trays with the one the user is on right now.
    func completeSetup(name: String, currentTray: Int, totalTrays: Int, plannedDays: Int, dayOnTray: Int, goalHours: Int) {
        let all = (try? context.fetch(FetchDescriptor<Tray>())) ?? []
        for t in all { context.delete(t) }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let start = cal.date(byAdding: .day, value: -(max(1, dayOnTray) - 1), to: today) ?? today
        let tray = Tray(number: currentTray, startDate: start, plannedDays: plannedDays)
        context.insert(tray)

        var settings = WearSettings.load()
        settings.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.totalTrays = max(totalTrays, currentTray)
        settings.defaultTrayDays = plannedDays
        settings.goalHours = goalHours
        settings.onboardingDone = true
        settings.trackingStart = .now
        settings.save()
        save()
        TrayNotifications.scheduleSwitchReminder(for: tray)
    }

    /// Adds planned days to the current tray on purpose (e.g. the orthodontist says three more days).
    func extendCurrentTray(by days: Int) {
        guard days > 0, let tray = currentTray() else { return }
        tray.plannedDays += days
        save()
        TrayNotifications.scheduleSwitchReminder(for: tray)
    }

    // MARK: Trays

    struct TrayUndo: Sendable {
        let newTrayID: PersistentIdentifier
        let closedTrayID: PersistentIdentifier?
    }

    struct TrayRecord: Sendable {
        let number: Int
        let startDate: Date
        let endDate: Date?
        let plannedDays: Int
    }

    struct DeleteUndo: Sendable {
        let record: TrayRecord
        let reopenedID: PersistentIdentifier?
        let reopenedPreviousEnd: Date?
    }

    /// Deletes a tray. If it was the current one, the previous tray becomes current again.
    func deleteTray(_ tray: Tray) -> DeleteUndo {
        let record = TrayRecord(number: tray.number, startDate: tray.startDate, endDate: tray.endDate, plannedDays: tray.plannedDays)
        var reopenedID: PersistentIdentifier?
        var previousEnd: Date?
        if tray.endDate == nil {
            let all = (try? context.fetch(FetchDescriptor<Tray>())) ?? []
            let previous = all
                .filter { $0.endDate != nil && $0.number < tray.number }
                .max(by: { $0.number < $1.number })
            if let previous {
                previousEnd = previous.endDate
                previous.endDate = nil
                reopenedID = previous.persistentModelID
            }
        }
        context.delete(tray)
        save()
        rescheduleTrayReminder()
        return DeleteUndo(record: record, reopenedID: reopenedID, reopenedPreviousEnd: previousEnd)
    }

    func undoDelete(_ undo: DeleteUndo) {
        let r = undo.record
        context.insert(Tray(number: r.number, startDate: r.startDate, endDate: r.endDate, plannedDays: r.plannedDays))
        if let id = undo.reopenedID, let t = context.model(for: id) as? Tray {
            t.endDate = undo.reopenedPreviousEnd
        }
        save()
        rescheduleTrayReminder()
    }

    private func rescheduleTrayReminder() {
        if let t = currentTray() { TrayNotifications.scheduleSwitchReminder(for: t) } else { TrayNotifications.cancel() }
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

    /// The latest Live Activity update, so intents can wait for it before the process is suspended.
    private var activityTask: Task<Void, Never>?

    func waitForLiveActivity() async {
        await activityTask?.value
    }

    /// Align the Live Activity with stored state (call on launch, foreground and after changes).
    func reconcileLiveActivity(now: Date = .now) {
        writeWidgetSnapshot()
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
        let start = open?.start
        let reason = open?.reasonRaw ?? OutReason.other.rawValue
        // Live Activity first: it is the visible part, reminders can follow.
        activityTask = Task {
            await LiveActivityController.reconcile(outStart: start, reasonRaw: reason, budgetLeftAtStart: left)
        }
        if let open {
            OutReminders.schedule(
                outStart: open.start, reason: OutReason(rawValue: reason) ?? .other,
                budgetEnd: open.start.addingTimeInterval(max(1, left)), now: now
            )
        } else {
            OutReminders.cancel()
        }
    }

    /// Copies what the widgets need into the App Group so they never have to open the database.
    func writeWidgetSnapshot() {
        let all = (try? context.fetch(FetchDescriptor<WearSession>())) ?? []
        let tray = currentTray().map { WidgetSnapshot.TrayInfo(number: $0.number, startDate: $0.startDate, plannedDays: $0.plannedDays) }
        WidgetSnapshot.make(
            sessions: all.map { SessionSpan(start: $0.start, end: $0.end) },
            firstSessionStart: all.map(\.start).min(), tray: tray
        ).save()
    }

    private func save() {
        try? context.save()
        writeWidgetSnapshot()
        WidgetCenter.shared.reloadAllTimelines()
        reconcileLiveActivity()
        ControlCenter.shared.reloadAllControls()
    }
}
