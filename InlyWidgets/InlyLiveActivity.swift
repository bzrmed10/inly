import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct InlyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: InlyActivityAttributes.self) { context in
            LockScreenView(context: context)
                .environment(\.layoutDirection, L10n.layoutDirection)
                .activityBackgroundTint(Theme.night)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            let tint = LiveStyle.color(context)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    LiveRing(context: context)
                        .frame(width: 44, height: 44)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(timerInterval: context.attributes.outStart...context.attributes.outStart.addingTimeInterval(86_400),
                             countsDown: false)
                            .font(Theme.timerFont(30))
                            .foregroundStyle(tint)
                            .multilineTextAlignment(.trailing)
                        Text(L10n.t("out"))
                            .font(Theme.font(12, .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(LiveStyle.reason(context).title)
                        .font(Theme.font(15, .heavy))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 10) {
                        BudgetBar(context: context)
                        HStack {
                            Text(LiveStyle.backBy(context))
                                .font(Theme.font(13, .medium))
                                .foregroundStyle(Theme.muted)
                            Spacer()
                            Button(intent: PutBackInIntent()) {
                                Text(L10n.t("Put back in"))
                                    .font(Theme.font(15, .heavy))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .background(Theme.outColor, in: Capsule())
                            .foregroundStyle(Theme.night)
                        }
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                LiveRing(context: context)
                    .frame(width: 22, height: 22)
            } compactTrailing: {
                Text(timerInterval: context.attributes.outStart...context.attributes.outStart.addingTimeInterval(86_400),
                     countsDown: false)
                    .font(Theme.timerFont(14))
                    .foregroundStyle(tint)
                    .frame(width: 52)
                    .multilineTextAlignment(.trailing)
            } minimal: {
                LiveRing(context: context)
                    .padding(2)
            }
            .keylineTint(tint)
        }
    }
}

// MARK: - Shared pieces

private enum LiveStyle {
    /// Amber while inside the budget; coral once the budget end (stale date) has passed.
    static func color(_ context: ActivityViewContext<InlyActivityAttributes>) -> Color {
        context.isStale ? Theme.overColor : Theme.outColor
    }

    static func reason(_ context: ActivityViewContext<InlyActivityAttributes>) -> OutReason {
        OutReason(rawValue: context.state.reasonRaw) ?? .other
    }

    static func backBy(_ context: ActivityViewContext<InlyActivityAttributes>) -> String {
        let t = L10n.time(context.attributes.budgetEnd)
        return context.isStale ? L10n.t("Over budget") : L10n.t("Back in by %@", t)
    }

    static func range(_ context: ActivityViewContext<InlyActivityAttributes>) -> ClosedRange<Date> {
        let start = context.attributes.outStart
        return start...max(context.attributes.budgetEnd, start.addingTimeInterval(1))
    }
}

/// Circular countdown ring that fills toward the budget end without app updates.
private struct LiveRing: View {
    let context: ActivityViewContext<InlyActivityAttributes>

    var body: some View {
        ProgressView(timerInterval: LiveStyle.range(context), countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            Image(systemName: LiveStyle.reason(context).symbol)
                .font(.system(size: 12, weight: .bold))
        }
        .progressViewStyle(.circular)
        .tint(LiveStyle.color(context))
    }
}

private struct BudgetBar: View {
    let context: ActivityViewContext<InlyActivityAttributes>

    var body: some View {
        ProgressView(timerInterval: LiveStyle.range(context), countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(LiveStyle.color(context))
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<InlyActivityAttributes>

    var body: some View {
        let tint = LiveStyle.color(context)
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                LiveRing(context: context)
                    .frame(width: 52, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.t("ALIGNERS OUT · %@", LiveStyle.reason(context).title.uppercased()))
                        .font(Theme.font(11, .heavy))
                        .tracking(1)
                        .foregroundStyle(tint)
                    Text(timerInterval: context.attributes.outStart...context.attributes.outStart.addingTimeInterval(86_400),
                         countsDown: false)
                        .font(Theme.timerFont(34))
                        .foregroundStyle(.white)
                }
                Spacer()
            }
            BudgetBar(context: context)
            HStack {
                Text(LiveStyle.backBy(context))
                    .font(Theme.font(13, .medium))
                    .foregroundStyle(Theme.muted)
                Spacer()
                Button(intent: PutBackInIntent()) {
                    Text(L10n.t("Put back in"))
                        .font(Theme.font(15, .heavy))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
                .background(Theme.outColor, in: Capsule())
                .foregroundStyle(Theme.night)
            }
        }
        .padding(16)
    }
}
