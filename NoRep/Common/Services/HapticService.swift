import UIKit

@MainActor
final class HapticService {

    private let impact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    func tick() {
        impact.impactOccurred(intensity: 0.6)
    }

    func segmentChange() {
        impact.impactOccurred(intensity: 1.0)
    }

    func roundCounted() {
        impact.impactOccurred(intensity: 0.8)
    }

    func finished() {
        notification.notificationOccurred(.success)
    }
}
