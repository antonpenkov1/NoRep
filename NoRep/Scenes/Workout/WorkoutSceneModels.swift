import SwiftUI

enum WorkoutSceneModels {

    enum DisplayState: Equatable {
        case idle
        case running
        case paused
        case finished
    }

    enum Tick {
        struct Response {
            var snapshot: TimerEngine.Snapshot
            var totalRounds: Int
            var nextSegment: WorkoutSegment?
        }

        struct ViewModel: Equatable {
            var state: DisplayState
            var blockTitle: String
            var label: String
            var timeText: String
            var phaseColor: Color
            /// nil hides progress (open-ended segment).
            var progress: Double?
            var totalLine: String
            var nextUpLine: String?
            var showsRoundButton: Bool
            var roundsText: String
            /// The current open-ended segment can be completed manually.
            var showsDoneSegment: Bool
            /// There are further segments to skip into.
            var showsSkip: Bool
        }
    }

    enum Summary {
        struct Response {
            var plan: WorkoutPlan
            var totalElapsed: TimeInterval
            var totalRounds: Int
        }

        struct ViewModel: Equatable {
            var title: String
            var detail: String
            var totalText: String
            var roundsText: String?
        }
    }
}
