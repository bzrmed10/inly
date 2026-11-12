import SwiftUI
import WidgetKit

/// Watch face complications: today's wear ring, the live out timer and the tray line.
@main
struct InlyWatchWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WatchWearComplication()
    }
}

struct ComplicationEntry: TimelineEntry {
    let date: Date
    let payload: WatchPayload?

    static let placeholder = ComplicationEntry(date: .now, payload: WatchPayload(
        isOut: false, outStart: .now, budgetEnd: .now.addingTimeInterval(3600), wornSeconds: 18 * 3600,
        wornFraction: 0.82, leftSeconds: 50 * 60, goalHours: 22, trayLine: "Tray 7 · Day 9 of 14", asOf: .now, plus: true))
}

struct ComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> ComplicationEntry { .placeholder }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (ComplicationEntry) -> Void) {
        completion(context.isPreview ? .placeholder : ComplicationEntry(date: .now, payload: WatchPayload.loadShared()))
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<ComplicationEntry>) -> Void) {
        let now = Date.now
        let payload = WatchPayload.loadShared()
        guard let p = payload, p.isPlus else {
            completion(Timeline(entries: [ComplicationEntry(date: now, payload: payload)], policy: .never))
            return
        }
        if p.isOut {
            // The timer text ticks by itself; refresh when the out-time budget runs out so the colour changes.
            let refresh = p.budgetEnd > now ? min(p.budgetEnd, now.addingTimeInterval(30 * 60)) : now.addingTimeInterval(30 * 60)
            completion(Timeline(entries: [ComplicationEntry(date: now, payload: p)], policy: .after(refresh)))
        } else {
            // Worn time grows while the aligners are in: one entry every 10 minutes for the next 2 hours.
            let entries = (0..<12).map { ComplicationEntry(date: now.addingTimeInterval(Double($0) * 600), payload: p) }
            completion(Timeline(entries: entries, policy: .atEnd))
        }
    }
}

struct WatchWearComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "InlyWatchWear", provider: ComplicationProvider()) { entry in
            ComplicationView(entry: entry)
                .environment(\.layoutDirection, L10n.layoutDirection)
                .containerBackground(for: .widget) { Theme.night }
        }
        .configurationDisplayName("Inly")
        .description("Today's aligner wear and the out timer.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

private struct ComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ComplicationEntry

    var body: some View {
        if let p = entry.payload, p.isPlus {
            switch family {
            case .accessoryCircular: circular(p)
            case .accessoryRectangular: rectangular(p)
            case .accessoryInline: inline(p)
            case .accessoryCorner: corner(p)
            default: circular(p)
            }
        } else {
            placeholderView(locked: entry.payload != nil)
        }
    }

    private func color(_ p: WatchPayload) -> Color {
        if p.isOut { return entry.date >= p.budgetEnd ? Theme.overColor : Theme.outColor }
        return Theme.inColor
    }

    private func outRange(_ p: WatchPayload) -> ClosedRange<Date> {
        p.outStart...max(p.budgetEnd, p.outStart.addingTimeInterval(1))
    }

    private func circular(_ p: WatchPayload) -> some View {
        Group {
            if p.isOut {
                ProgressView(timerInterval: outRange(p), countsDown: false) { EmptyView() } currentValueLabel: {
                    Text(p.outStart, style: .timer).monospacedDigit().font(Theme.font(11, .heavy))
                }
                .progressViewStyle(.circular)
                .tint(color(p))
            } else {
                Gauge(value: p.wornFraction(at: entry.date)) { EmptyView() } currentValueLabel: {
                    Text(shortHours(p.wornSeconds(at: entry.date))).font(Theme.font(13, .heavy))
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(color(p))
            }
        }
        .widgetAccentable()
    }

    private func rectangular(_ p: WatchPayload) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(p.isOut ? L10n.t("Aligners OUT") : L10n.t("Aligners IN"))
                .font(Theme.font(14, .heavy)).foregroundStyle(color(p)).widgetAccentable()
            if p.isOut {
                Text(p.outStart, style: .timer).monospacedDigit().font(Theme.font(20, .heavy))
                ProgressView(timerInterval: outRange(p), countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                    .tint(color(p))
            } else {
                Text(L10n.t("%@ worn today", TimeFormat.hoursMinutes(p.wornSeconds(at: entry.date))))
                    .font(Theme.font(15, .heavy)).lineLimit(1).minimumScaleFactor(0.7)
                if let line = p.trayLine {
                    Text(line).font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inline(_ p: WatchPayload) -> some View {
        Group {
            if p.isOut {
                Text("\(Image(systemName: "timer")) \(Text(p.outStart, style: .timer))")
            } else {
                Text(L10n.t("%@ worn today", TimeFormat.hoursMinutes(p.wornSeconds(at: entry.date))))
            }
        }
    }

    private func corner(_ p: WatchPayload) -> some View {
        Image(systemName: p.isOut ? "timer" : "checkmark")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(color(p))
            .widgetLabel {
                if p.isOut {
                    ProgressView(timerInterval: outRange(p), countsDown: false) { EmptyView() } currentValueLabel: { EmptyView() }
                        .tint(color(p))
                } else {
                    Gauge(value: p.wornFraction(at: entry.date)) { EmptyView() }
                        .tint(color(p))
                }
            }
    }

    /// Not connected yet, or Inly+ is not unlocked on the iPhone.
    private func placeholderView(locked: Bool) -> some View {
        Group {
            switch family {
            case .accessoryRectangular:
                VStack(alignment: .leading, spacing: 2) {
                    Text("Inly").font(Theme.font(15, .heavy))
                    Text(locked ? L10n.t("Unlock with Inly+ on your iPhone.") : L10n.t("Open Inly on your iPhone once to connect."))
                        .font(Theme.font(12, .semibold)).foregroundStyle(Theme.muted).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .accessoryInline:
                Text(locked ? "Inly+" : "Inly")
            default:
                Image(systemName: locked ? "lock.fill" : "circle.dashed")
                    .font(.system(size: 18, weight: .bold))
            }
        }
    }

    /// "18h" style label for the small ring.
    private func shortHours(_ seconds: TimeInterval) -> String {
        "\(Int(seconds / 3600))h"
    }
}
