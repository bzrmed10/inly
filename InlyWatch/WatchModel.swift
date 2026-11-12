import Foundation
import Observation
@preconcurrency import WatchConnectivity
import WatchKit
import WidgetKit

/// Holds the latest state from the iPhone and sends Take out / Put back in to it.
@MainActor
@Observable
final class WatchModel: NSObject {
    private(set) var payload: WatchPayload?
    private(set) var phoneReachable = false

    private let storeKey = "lastPayload"

    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: storeKey) { payload = WatchPayload.decode(data) }
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func apply(_ data: Data?) {
        guard let new = WatchPayload.decode(data) else { return }
        payload = new
        if let language = new.language {
            UserDefaults.standard.set(language, forKey: L10n.storageKey)
            UserDefaults(suiteName: AppGroup.identifier)?.set(language, forKey: L10n.storageKey)
        }
        UserDefaults.standard.set(data, forKey: storeKey)
        new.saveShared()
        WidgetCenter.shared.reloadAllTimelines()
    }

    func toggle() {
        guard let current = payload else { return }
        let takingOut = !current.isOut
        WKInterfaceDevice.current().play(takingOut ? .directionUp : .success)

        // Show the change straight away; the iPhone's answer replaces it.
        var next = current
        let now = Date.now
        next.isOut = takingOut
        if takingOut {
            next.outStart = now
            next.budgetEnd = now.addingTimeInterval(max(1, current.leftSeconds))
        }
        payload = next
        next.saveShared()
        WidgetCenter.shared.reloadAllTimelines()

        let command = takingOut ? WatchPayload.takeOutCommand : WatchPayload.putBackCommand
        send(command)
    }

    private func send(_ command: String) {
        let session = WCSession.default
        let message = [WatchPayload.commandKey: command]
        if session.isReachable {
            session.sendMessage(message, replyHandler: { [weak self] reply in
                let data = reply[WatchPayload.payloadKey] as? Data
                Task { @MainActor in self?.apply(data) }
            }, errorHandler: { _ in
                // Could not reach the iPhone: queue it, it is delivered when the phone is next available.
                WCSession.default.transferUserInfo(message)
            })
        } else {
            session.transferUserInfo(message)
        }
    }
}

extension WatchModel: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        let data = session.receivedApplicationContext[WatchPayload.payloadKey] as? Data
        let reachable = session.isReachable
        Task { @MainActor in
            self.phoneReachable = reachable
            if data != nil { self.apply(data) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext[WatchPayload.payloadKey] as? Data
        Task { @MainActor in self.apply(data) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        let reachable = session.isReachable
        Task { @MainActor in self.phoneReachable = reachable }
    }
}
