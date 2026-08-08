import Foundation

@MainActor
protocol SetupBusinessLogic {
    func load()
    func update(_ field: SetupModels.Field)
    func start()
}

@MainActor
final class SetupInteractor: SetupBusinessLogic {

    private let presenter: SetupPresentationLogic
    private let defaultsStore: SetupDefaultsStore
    private let onStart: (WorkoutPlan) -> Void
    private var state: SetupModels.State

    init(
        type: WorkoutType,
        presenter: SetupPresentationLogic,
        defaultsStore: SetupDefaultsStore = .shared,
        onStart: @escaping (WorkoutPlan) -> Void
    ) {
        self.presenter = presenter
        self.defaultsStore = defaultsStore
        self.onStart = onStart
        self.state = SetupModels.State(
            type: type,
            emom: defaultsStore.emom,
            amrap: defaultsStore.amrap,
            forTime: defaultsStore.forTime,
            tabata: defaultsStore.tabata,
            countdown: defaultsStore.countdown,
            soundEnabled: defaultsStore.soundEnabled,
            name: "",
            note: ""
        )
    }

    func load() {
        presenter.presentRefresh(.init(state: state))
    }

    func update(_ field: SetupModels.Field) {
        switch field {
        case .emom(let config):
            state.emom = clamp(config)
            defaultsStore.emom = state.emom
        case .amrap(let config):
            state.amrap = AmrapConfig(duration: max(10, config.duration))
            defaultsStore.amrap = state.amrap
        case .forTime(let config):
            var c = config
            c.timeCap = max(10, c.timeCap)
            state.forTime = c
            defaultsStore.forTime = c
        case .tabata(let config):
            var c = config
            c.rounds = min(max(1, c.rounds), 30)
            c.work = max(5, c.work)
            c.rest = max(0, c.rest)
            state.tabata = c
            defaultsStore.tabata = c
        case .countdown(let value):
            state.countdown = value
            defaultsStore.countdown = value
        case .sound(let enabled):
            state.soundEnabled = enabled
            defaultsStore.soundEnabled = enabled
        case .name(let text):
            state.name = text
        case .note(let text):
            state.note = text
        }
        presenter.presentRefresh(.init(state: state))
    }

    func start() {
        let block: WorkoutBlock
        switch state.type {
        case .emom: block = .emom(state.emom)
        case .amrap: block = .amrap(state.amrap)
        case .forTime: block = .forTime(state.forTime)
        case .tabata: block = .tabata(state.tabata)
        case .mix: return // Mix has its own builder scene.
        }
        let note = state.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = state.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = WorkoutPlan(
            type: state.type,
            blocks: [MixBlock(block: block, note: note.isEmpty ? nil : note)],
            countdown: state.countdown,
            customName: name.isEmpty ? nil : name
        )
        onStart(plan)
    }

    private func clamp(_ config: EmomConfig) -> EmomConfig {
        var c = config
        c.rounds = min(max(1, c.rounds), 99)
        c.interval = max(10, c.interval)
        return c
    }
}
