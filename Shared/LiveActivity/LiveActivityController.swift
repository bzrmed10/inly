import ActivityKit
import Foundation

/// Starts, updates and ends the "aligners out" Live Activity so it always mirrors stored state.
@MainActor
enum LiveActivityController {
    typealias InlyActivity = Activity<InlyActivityAttributes>

    /// Bring the Live Activity in line with the current open session (or lack of one).
    static func reconcile(openSession: WearSession?, budgetLeftAtStart: TimeInterval) {
        guard let session = openSession else {
            endAll()
            return
        }
        let budgetEnd = session.start.addingTimeInterval(max(1, budgetLeftAtStart))
        let state = InlyActivityAttributes.ContentState(reasonRaw: session.reasonRaw)
        let content = ActivityContent(state: state, staleDate: budgetEnd)

        if let existing = InlyActivity.activities.first(where: { $0.attributes.outStart == session.start }) {
            Task { await existing.update(content) }
            return
        }

        // A different (old) activity may be running; end it before starting a new one.
        endAll()
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let attributes = InlyActivityAttributes(outStart: session.start, budgetEnd: budgetEnd)
        _ = try? InlyActivity.request(attributes: attributes, content: content, pushType: nil)
    }

    static func endAll() {
        for activity in InlyActivity.activities {
            Task { await activity.end(nil, dismissalPolicy: .immediate) }
        }
    }
}
