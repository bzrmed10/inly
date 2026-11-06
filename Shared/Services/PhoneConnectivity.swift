import Foundation
@preconcurrency import WatchConnectivity

/// iPhone side of the Apple Watch link: pushes the current state and runs Take out / Put back in sent from the watch.
final class PhoneConnectivity: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = PhoneConnectivity()

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// Sends the latest state to the watch (the newest value wins, delivered even if the watch app is closed).
    func push(_ status: WearStatus) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        try? session.updateApplicationContext(WatchPayload(status).dictionary)
    }

    // MARK: WCSessionDelegate

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in SessionService.shared.writeWidgetSnapshot() }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in SessionService.shared.writeWidgetSnapshot() }
    }

    nonisolated func session(
        _ session: WCSession, didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        let command = message[WatchPayload.commandKey] as? String
        nonisolated(unsafe) let reply = replyHandler
        Task { @MainActor in
            let status = SessionService.shared.handleWatchCommand(command)
            reply(status.map { WatchPayload($0).dictionary } ?? [:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        let command = userInfo[WatchPayload.commandKey] as? String
        Task { @MainActor in _ = SessionService.shared.handleWatchCommand(command) }
    }
}
