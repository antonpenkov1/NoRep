import Foundation

enum BenchmarksModels {

    enum Load {
        struct Response {
            var benchmarks: [BenchmarkWOD]
            var bestByName: [String: WorkoutResult]
        }

        struct ViewModel: Equatable {
            struct Row: Equatable, Identifiable {
                var id: String
                var name: String
                var scheme: String
                var movements: String
                var bestText: String?
            }

            struct Section: Equatable, Identifiable {
                var id: String
                var title: String
                var rows: [Row]
            }

            var sections: [Section]
        }
    }
}
