import ActivityKit
import Foundation

/// Shared between the app and the widget extension.
struct WorkoutActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        var blockTitle: String
        var label: String
        /// "work" / "rest" / "prepare" — the widget maps this to a color.
        var kind: String
        /// Countdown target; the widget renders an auto-ticking timer toward it.
        var endDate: Date?
        /// Anchor for count-up segments (For Time).
        var startDate: Date
        var isPaused: Bool
        /// Frozen display while paused (timers can't pause mid-flight in a widget).
        var pausedTimeText: String
        var roundsText: String?
    }

    var workoutTitle: String
}
