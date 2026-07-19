import Foundation

enum MixBuilderModels {

    enum Refresh {
        struct Response {
            var blocks: [MixBlock]
            var countdown: TimeInterval
        }

        struct ViewModel: Equatable {
            struct Row: Equatable, Identifiable {
                var id: UUID
                var title: String
                var summary: String
                var systemImage: String
                var isRest: Bool
                var block: WorkoutBlock
            }

            var rows: [Row]
            var totalLine: String
            var canStart: Bool
        }
    }
}
