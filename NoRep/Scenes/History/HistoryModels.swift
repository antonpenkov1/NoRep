import Foundation

enum HistoryModels {

    enum Load {
        struct Response {
            var results: [WorkoutResult]
            var stats: JournalStats
        }

        struct ViewModel: Equatable {
            struct Stats: Equatable {
                var streakText: String
                var thisWeekText: String
                var thisMonthText: String
                var totalText: String
                var totalTimeText: String
            }

            struct Row: Equatable, Identifiable {
                var id: UUID
                var title: String
                var detail: String
                var note: String?
                var dateText: String
                var timeText: String
                var scoreText: String?
                var rxText: String?
                var feelingEmoji: String?
            }

            var rows: [Row]
            var stats: Stats
            var heatWeeks: [[JournalStats.HeatDay]]
            var csvURL: URL?
            var jsonURL: URL?
            var isEmpty: Bool { rows.isEmpty }
        }
    }

    enum Detail {
        struct Response {
            var result: WorkoutResult
            /// All attempts of this named workout (including this one), oldest first.
            var series: [WorkoutResult]
        }

        struct ViewModel: Equatable, Identifiable {
            struct Attempt: Equatable, Identifiable {
                var id: UUID
                var date: Date
                var dateText: String
                /// Chart value: seconds for For Time, rounds otherwise.
                var value: Double
                var scoreText: String
                var isBest: Bool
                var isCurrent: Bool
            }

            var id: UUID
            var title: String
            var dateText: String
            var timeText: String
            var scoreText: String?
            var detail: String
            var note: String?
            var rxText: String?
            var feelingEmoji: String?
            var roundDurations: [Double]
            /// Progression across attempts; empty when the workout was done once.
            var attempts: [Attempt]
            /// "Time, lower is better" / "Rounds, higher is better"
            var progressionCaption: String?
        }
    }
}
