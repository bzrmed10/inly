import Foundation

/// Everything a glance (widget, watch) needs to show, worked out from the compact snapshot.
struct WearStatus: Sendable, Equatable {
    var isOut: Bool
    var outStart: Date
    var budgetEnd: Date
    var wornSeconds: TimeInterval
    var wornFraction: Double
    var leftSeconds: TimeInterval
    var goalHours: Int
    var trayLine: String?

    static func make(from data: WidgetSnapshot, settings: WearSettings, now: Date) -> WearStatus {
        let spans = data.spans.map { SessionSpan(start: $0.start, end: $0.end) }
        let tracking = settings.resolvedTrackingStart(firstSession: data.firstSessionStart)
        let snap = WearCalculator.snapshot(
            sessions: spans, now: now, budgetSeconds: settings.budgetSeconds, calendar: .current, trackingStart: tracking
        )

        let open = spans.first(where: { $0.end == nil })
        var budgetEnd = now.addingTimeInterval(snap.leftSeconds)
        if let open {
            let others = spans.filter { $0.start != open.start }
            let before = WearCalculator.snapshot(sessions: others, now: open.start, budgetSeconds: settings.budgetSeconds, calendar: .current)
            budgetEnd = open.start.addingTimeInterval(max(1, before.leftSeconds))
        }

        var tray: String?
        if let t = data.tray {
            let day = TrayLogic.dayNumber(start: t.startDate, now: now, calendar: .current)
            tray = "Tray \(t.number) · Day \(day) of \(t.plannedDays)"
        }
        return WearStatus(
            isOut: open != nil, outStart: open?.start ?? now, budgetEnd: budgetEnd,
            wornSeconds: snap.wornSeconds, wornFraction: snap.goalProgress, leftSeconds: snap.leftSeconds,
            goalHours: settings.goalHours, trayLine: tray
        )
    }
}

extension WatchPayload {
    init(_ s: WearStatus) {
        self.init(isOut: s.isOut, outStart: s.outStart, budgetEnd: s.budgetEnd, wornSeconds: s.wornSeconds,
                  wornFraction: s.wornFraction, leftSeconds: s.leftSeconds, goalHours: s.goalHours, trayLine: s.trayLine)
    }
}
