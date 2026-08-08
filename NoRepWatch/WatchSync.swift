import Foundation
import WatchConnectivity

/// Ships finished workout results to the paired iPhone's journal.
final class WatchSync: NSObject, WCSessionDelegate {

    static let shared = WatchSync()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func send(_ result: WorkoutResult) {
        guard WCSession.isSupported(),
              let data = try? JSONEncoder().encode(result) else { return }
        // transferUserInfo queues until the phone is reachable.
        WCSession.default.transferUserInfo(["workoutResult": data])
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}
}
