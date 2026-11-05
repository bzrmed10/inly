import AppIntents
import SwiftData
import SwiftUI
import WidgetKit

// MARK: - Entry

struct WearEntry: TimelineEntry, Sendable {
    let date: Date
    let isOut: Bool
    let outStart: Date
    let budgetEnd: Date
    let wornSeconds: TimeInterval
    /// Worn time against the daily goal, 0...1.
    let wornFraction: Double
    /// Out-time left today at `date`.
    let leftSeconds: TimeInterval
    let goalHours: Int
    let trayLine: String?

    var isOver: Bool { isOut && date >= budgetEnd }

    /// 0...1 share of the out-time budget used by this entry's date (ring while out).
    var outProgress: Double {
        let total = budgetEnd.timeIntervalSince(outStart)
        guard total > 0 else { return 1 }
        return min(1, max(0, date.timeIntervalSince(outStart) / total))
    }

    static let placeholder = WearEntry(
        date: .now, isOut: false, outStart: .now, budgetEnd: .now.addingTimeInterval(3600),
        wornSeconds: 14 * 3600, wornFraction: 0.64, leftSeconds: 50 * 60, goalHours: 22, trayLine: "Tray 7 · Day 9 of 14"
    )
}

// MARK: - Provider (reads the shared App Group store)

struct WearProvider: TimelineProvider {
    func placeholder(in context: Context) -> WearEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (WearEntry) -> Void) {
        completion(context.isPreview ? .placeholder : Self.load(now: .now))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<WearEntry>) -> Void) {
        let first = Self.load(now: .now)
        var entries = [first]
        var refresh = Date.now.addingTimeInterval(15 * 60)

        if first.isOut, first.budgetEnd > .now {
            // While out, add an entry every 5 minutes so the ring keeps filling, plus one at the budget end.
            var t = Date.now.addingTimeInterval(5 * 60)
            while t < first.budgetEnd, entries.count < 36 {
                entries.append(Self.entry(from: first, at: t))
                t = t.addingTimeInterval(5 * 60)
            }
            entries.append(Self.entry(from: first, at: first.budgetEnd))
            refresh = first.budgetEnd.addingTimeInterval(15 * 60)
        }
        completion(Timeline(entries: entries, policy: .after(refresh)))
    }

    /// The same data at a later moment (only the out-time left and the ring move while out).
    private static func entry(from e: WearEntry, at date: Date) -> WearEntry {
        WearEntry(
            date: date, isOut: e.isOut, outStart: e.outStart, budgetEnd: e.budgetEnd,
            wornSeconds: e.wornSeconds, wornFraction: e.wornFraction,
            leftSeconds: max(0, e.budgetEnd.timeIntervalSince(date)),
            goalHours: e.goalHours, trayLine: e.trayLine
        )
    }

    static func load(now: Date) -> WearEntry {
        let context = ModelContext(DataStore.makeContainer())
        let sessions = (try? context.fetch(FetchDescriptor<WearSession>())) ?? []
        let spans = sessions.map { SessionSpan(start: $0.start, end: $0.end) }
        let settings = WearSettings.load()
        let tracking = settings.resolvedTrackingStart(firstSession: sessions.map(\.start).min())
        let snap = WearCalculator.snapshot(
            sessions: spans, now: now, budgetSeconds: settings.budgetSeconds, calendar: .current, trackingStart: tracking
        )

        let open = sessions.first(where: { $0.end == nil })
        var budgetEnd = now.addingTimeInterval(snap.leftSeconds)
        if let open {
            let others = spans.filter { $0.start != open.start }
            let before = WearCalculator.snapshot(sessions: others, now: open.start, budgetSeconds: settings.budgetSeconds, calendar: .current)
            budgetEnd = open.start.addingTimeInterval(max(1, before.leftSeconds))
        }

        var tray: String?
        var d = FetchDescriptor<Tray>(predicate: #Predicate { $0.endDate == nil }, sortBy: [SortDescriptor(\.startDate, order: .reverse)])
        d.fetchLimit = 1
        if let t = try? context.fetch(d).first {
            let day = TrayLogic.dayNumber(start: t.startDate, now: now, calendar: .current)
            tray = "Tray \(t.number) · Day \(day) of \(t.plannedDays)"
        }

        return WearEntry(
            date: now, isOut: open != nil, outStart: open?.start ?? now, budgetEnd: budgetEnd,
            wornSeconds: snap.wornSeconds, wornFraction: snap.goalProgress, leftSeconds: snap.leftSeconds,
            goalHours: settings.goalHours, trayLine: tray
        )
    }
}

// MARK: - Widget

struct WearWidget: Widget {
    let kind = "InlyWear"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WearProvider()) { entry in
            WearWidgetView(entry: entry)
                .containerBackground(for: .widget) { Theme.night }
        }
        .configurationDisplayName("Aligner wear")
        .description("See how long your aligners have been in or out.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Views

private struct WearWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WearEntry

    private var color: Color {
        if entry.isOver { return Theme.overColor }
        return entry.isOut ? Theme.outColor : Theme.inColor
    }

    private var outRange: ClosedRange<Date> {
        entry.outStart...max(entry.budgetEnd, entry.outStart.addingTimeInterval(1))
    }

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        case .accessoryCircular: circular
        case .accessoryRectangular: rectangular
        default: small
        }
    }

    // MARK: Home Screen

    /// Big number in the middle of the ring: live timer while out, worn time while in.
    private var centerValue: some View {
        Group {
            if entry.isOut {
                Text(timerInterval: entry.outStart...entry.outStart.addingTimeInterval(86_400), countsDown: false)
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            } else {
                Text(TimeFormat.hoursMinutes(entry.wornSeconds))
            }
        }
        .font(Theme.font(22, .heavy))
        .minimumScaleFactor(0.5)
        .lineLimit(1)
    }

    private var ring: some View {
        let progress = entry.isOut ? entry.outProgress : entry.wornFraction
        return ZStack {
            Circle().stroke(Theme.raised, lineWidth: 9)
            Circle()
                .trim(from: 0, to: max(0.001, progress))
                .stroke(color, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(entry.isOut ? "OUT" : "WORN")
                    .font(Theme.font(10, .heavy)).tracking(1).foregroundStyle(color)
                centerValue
            }
            .padding(.horizontal, 16)
        }
    }

    /// "35m left" (static) or a live countdown while out.
    private func leftLabel(font: Font) -> some View {
        Group {
            if entry.isOut {
                if entry.isOver {
                    Text("Over budget")
                } else {
                    HStack(spacing: 4) {
                        Text(timerInterval: Date.now...max(entry.budgetEnd, Date.now.addingTimeInterval(1)), countsDown: true)
                            .monospacedDigit()
                            .fixedSize()
                        Text("left")
                    }
                }
            } else {
                Text("\(TimeFormat.hoursMinutes(entry.leftSeconds)) left")
            }
        }
        .font(font)
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }

    private var small: some View {
        VStack(spacing: 6) {
            ring.padding(3)
            leftLabel(font: Theme.font(13, .heavy))
        }
    }

    private var medium: some View {
        HStack(spacing: 16) {
            ring.frame(width: 118, height: 118)
            VStack(alignment: .leading, spacing: 6) {
                if let line = entry.trayLine {
                    Text(line).font(Theme.font(13, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
                }
                leftLabel(font: Theme.font(16, .heavy))
                Text(entry.isOut && !entry.isOver ? "Back in by \(entry.budgetEnd.formatted(date: .omitted, time: .shortened))" : "Goal \(entry.goalHours)h a day")
                    .font(Theme.font(13, .medium)).foregroundStyle(Theme.muted).lineLimit(1)
                Spacer(minLength: 0)
                Button(intent: ToggleWearIntent()) {
                    Text(entry.isOut ? "Put back in" : "Take out")
                        .font(Theme.font(16, .heavy))
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .background(entry.isOut ? Theme.outColor : Theme.inColor, in: Capsule())
                .foregroundStyle(Theme.night)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Lock Screen

    private var circular: some View {
        Group {
            if entry.isOut {
                ProgressView(timerInterval: outRange, countsDown: false) { EmptyView() } currentValueLabel: {
                    Image(systemName: "timer")
                }
                .progressViewStyle(.circular)
            } else {
                Gauge(value: entry.wornFraction) { EmptyView() } currentValueLabel: {
                    Image(systemName: "checkmark")
                }
                .gaugeStyle(.accessoryCircularCapacity)
            }
        }
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.isOut ? "Aligners OUT" : "Aligners IN")
                .font(.system(.headline, design: .rounded, weight: .heavy))
            if entry.isOut {
                Text(timerInterval: entry.outStart...entry.outStart.addingTimeInterval(86_400), countsDown: false)
                    .font(.system(.title3, design: .rounded, weight: .heavy)).monospacedDigit()
                ProgressView(timerInterval: outRange, countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                leftLabel(font: .system(.caption, design: .rounded, weight: .semibold))
            } else {
                Text("\(TimeFormat.hoursMinutes(entry.wornSeconds)) worn today")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                ProgressView(value: entry.wornFraction)
                leftLabel(font: .system(.caption, design: .rounded, weight: .semibold))
            }
        }
    }
}
