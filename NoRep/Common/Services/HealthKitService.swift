import HealthKit

/// Writes finished workouts to Apple Health as functional strength training.
/// Nothing is ever read; nothing leaves the device.
final class HealthKitService {

    static let shared = HealthKitService()

    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
            return true
        } catch {
            return false
        }
    }

    func save(result: WorkoutResult) async {
        guard isAvailable, result.totalSeconds > 0 else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining

        let end = result.date
        let start = end.addingTimeInterval(-TimeInterval(result.totalSeconds))
        let builder = HKWorkoutBuilder(healthStore: store, configuration: configuration, device: .local())

        do {
            try await builder.beginCollection(at: start)
            try await builder.endCollection(at: end)
            try await builder.finishWorkout()
        } catch {
            // Health write is best-effort; the journal remains the source of truth.
        }
    }
}
