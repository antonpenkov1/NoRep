import Foundation

enum SetupModels {

    struct State {
        var type: WorkoutType
        var emom: EmomConfig
        var amrap: AmrapConfig
        var forTime: ForTimeConfig
        var tabata: TabataConfig
        var countdown: TimeInterval
        var soundEnabled: Bool
        /// Workout name ("Fran") — the PR-tracking key.
        var name: String
        /// The movements: "21-15-9 thrusters / pull-ups".
        var note: String
    }

    enum Refresh {
        struct Response {
            var state: State
        }

        struct ViewModel: Equatable {
            var title: String
            var summary: String
            var emom: EmomConfig
            var amrap: AmrapConfig
            var forTime: ForTimeConfig
            var tabata: TabataConfig
            var countdown: TimeInterval
            var soundEnabled: Bool
            var name: String
            var note: String
        }
    }

    enum Field {
        case emom(EmomConfig)
        case amrap(AmrapConfig)
        case forTime(ForTimeConfig)
        case tabata(TabataConfig)
        case countdown(TimeInterval)
        case sound(Bool)
        case name(String)
        case note(String)
    }
}
