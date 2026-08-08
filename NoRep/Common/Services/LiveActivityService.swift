import ActivityKit
import Foundation

/// Starts, updates and ends the lock-screen / Dynamic Island Live Activity
/// that mirrors the running workout.
@MainActor
final class LiveActivityService {

    private var activity: Activity<WorkoutActivityAttributes>?

    func start(title: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        end()
        // Clean up activities orphaned by a force-quit — they linger frozen otherwise.
        for stale in Activity<WorkoutActivityAttributes>.activities {
            Task { await stale.end(nil, dismissalPolicy: .immediate) }
        }
        let attributes = WorkoutActivityAttributes(workoutTitle: title)
        let state = WorkoutActivityAttributes.ContentState(
            blockTitle: title.uppercased(),
            label: "GET READY",
            kind: SegmentKind.prepare.rawValue,
            endDate: nil,
            startDate: Date(),
            isPaused: false,
            pausedTimeText: "",
            roundsText: nil
        )
        activity = try? Activity.request(
            attributes: attributes,
            content: ActivityContent(state: state, staleDate: nil)
        )
    }

    func update(
        engineState: TimerEngine.State,
        segment: WorkoutSegment?,
        segmentElapsed: TimeInterval,
        roundsText: String?
    ) {
        guard let activity, let segment else { return }
        guard engineState == .running || engineState == .paused else { return }

        let now = Date()
        let isPaused = engineState == .paused

        var endDate: Date?
        var pausedText = TimeFormat.clock(segmentElapsed)
        if let duration = segment.duration, !segment.countsUp {
            endDate = now.addingTimeInterval(max(0, duration - segmentElapsed))
            pausedText = TimeFormat.clockCeil(duration - segmentElapsed)
        }

        let state = WorkoutActivityAttributes.ContentState(
            blockTitle: segment.blockTitle,
            label: segment.label,
            kind: segment.kind.rawValue,
            endDate: isPaused ? nil : endDate,
            startDate: now.addingTimeInterval(-segmentElapsed),
            isPaused: isPaused,
            pausedTimeText: pausedText,
            roundsText: roundsText
        )
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
