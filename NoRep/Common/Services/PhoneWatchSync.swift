import Foundation
import WatchConnectivity

/// Receives finished workouts from the watch and lands them in the journal.
final class PhoneWatchSync: NSObject, WCSessionDelegate {

    static let shared = PhoneWatchSync()

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["workoutResult"] as? Data,
              let result = try? JSONDecoder().decode(WorkoutResult.self, from: data) else { return }
        Task { @MainActor in
            HistoryStore.shared.add(result)
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
