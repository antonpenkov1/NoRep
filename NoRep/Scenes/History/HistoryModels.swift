import Foundation

enum HistoryModels {

    enum Load {
        struct Response {
            var results: [WorkoutResult]
        }

        struct ViewModel: Equatable {
            struct Row: Equatable, Identifiable {
                var id: UUID
                var title: String
                var detail: String
                var dateText: String
                var timeText: String
                var scoreText: String?
            }

            var rows: [Row]
            var isEmpty: Bool { rows.isEmpty }
        }
    }
}
