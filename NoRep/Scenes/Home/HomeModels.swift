import Foundation

enum HomeModels {

    enum Load {
        struct Request {}

        struct Response {
            var types: [WorkoutType]
            var completedCount: Int
        }

        struct ViewModel: Equatable {
            struct TimerCard: Equatable, Identifiable {
                var id: String
                var type: WorkoutType
                var title: String
                var subtitle: String
                var systemImage: String
            }

            var cards: [TimerCard]
            var historyLine: String
        }
    }
}
