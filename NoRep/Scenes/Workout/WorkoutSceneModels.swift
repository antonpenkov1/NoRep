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
            /// Movements hint for the current block.
            var noteText: String?
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
            var result: WorkoutResult
            /// Earlier results with the same name (benchmark series), best first.
            var previousBest: WorkoutResult?
            var attemptNumber: Int
            var isPR: Bool
        }

        struct ViewModel: Equatable {
            var name: String
            var detail: String
            var totalText: String
            var roundsText: String?
            var note: String
            var isRx: Bool?
            var feeling: Int?
            /// Per-round durations in seconds for the splits chart.
            var roundDurations: [Double]
            var splitLines: [String]
            /// "New PR! Previous best 8:45" / "Best 7:10 · attempt #4"
            var prLine: String?
            var isPR: Bool
        }
    }

    struct SummaryEdit {
        var name: String
        var note: String
        var isRx: Bool?
        var feeling: Int?
    }
}
