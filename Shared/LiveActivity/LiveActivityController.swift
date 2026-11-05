import ActivityKit
import Foundation

/// Starts, updates and ends the "aligners out" Live Activity so it always mirrors stored state.
/// Methods are nonisolated and only take Sendable values, so `Activity` objects never cross
/// an isolation boundary (Swift 6 strict concurrency).
enum LiveActivityController {
    typealias InlyActivity = Activity<InlyActivityAttributes>

    /// Bring the Live Activity in line with the current open session (or lack of one).
    static func reconcile(outStart: Date?, reasonRaw: String, budgetLeftAtStart: TimeInterval) async {
        guard let outStart else {
            await endAll()
            return
        }
        let budgetEnd = outStart.addingTimeInterval(max(1, budgetLeftAtStart))
        let state = InlyActivityAttributes.ContentState(reasonRaw: reasonRaw)
        let content = ActivityContent(state: state, staleDate: budgetEnd)

        if let existing = InlyActivity.activities.first(where: { $0.attributes.outStart == outStart }) {
            await existing.update(content)
            return
        }

        // A different (old) activity may be running; end it before starting a new one.
        await endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = InlyActivityAttributes(outStart: outStart, budgetEnd: budgetEnd)
        _ = try? InlyActivity.request(attributes: attributes, content: content, pushType: nil)
    }

    static func endAll() async {
        for activity in InlyActivity.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
