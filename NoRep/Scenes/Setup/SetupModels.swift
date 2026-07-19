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
        }
    }

    enum Field {
        case emom(EmomConfig)
        case amrap(AmrapConfig)
        case forTime(ForTimeConfig)
        case tabata(TabataConfig)
        case countdown(TimeInterval)
        case sound(Bool)
    }
}
