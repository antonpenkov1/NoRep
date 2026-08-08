import Foundation

enum HomeModels {

    enum Load {
        struct Request {}

        struct Response {
            var types: [WorkoutType]
            var completedCount: Int
            var lastPlan: WorkoutPlan?
        }

        struct ViewModel: Equatable {
            struct TimerCard: Equatable, Identifiable {
                var id: String
                var type: WorkoutType
                var title: String
                var subtitle: String
                var systemImage: String
            }

            struct QuickStart: Equatable {
                var title: String
                var detail: String
            }

            var cards: [TimerCard]
            var historyLine: String
            var repeatLast: QuickStart?
        }
    }

    enum Preset: String, CaseIterable {
        case emom10
        case amrap12
        case tabata

        var title: String {
            switch self {
            case .emom10: return "EMOM 10"
            case .amrap12: return "AMRAP 12"
            case .tabata: return "TABATA"
            }
        }

        var block: WorkoutBlock {
            switch self {
            case .emom10: return .emom(EmomConfig(rounds: 10, interval: 60))
            case .amrap12: return .amrap(AmrapConfig(duration: 12 * 60))
            case .tabata: return .tabata(TabataConfig())
            }
        }

        var type: WorkoutType {
            switch self {
            case .emom10: return .emom
            case .amrap12: return .amrap
            case .tabata: return .tabata
            }
        }
    }
}
