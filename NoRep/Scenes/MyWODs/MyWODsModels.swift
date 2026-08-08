import Foundation

enum MyWODsModels {

    enum Load {
        struct Response {
            var wods: [SavedWOD]
            var bestByName: [String: WorkoutResult]
        }

        struct ViewModel: Equatable {
            struct Row: Equatable, Identifiable {
                var id: UUID
                var name: String
                var scheme: String
                var movements: String?
                var bestText: String?
            }

            var rows: [Row]
            var isEmpty: Bool { rows.isEmpty }
        }
    }
}
