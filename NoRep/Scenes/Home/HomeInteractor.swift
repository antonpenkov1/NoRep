import Foundation

@MainActor
protocol HomeBusinessLogic {
    func load(_ request: HomeModels.Load.Request)
    func repeatLast()
    func startPreset(_ preset: HomeModels.Preset)
}

@MainActor
final class HomeInteractor: HomeBusinessLogic {

    private let presenter: HomePresentationLogic
    private let historyStore: HistoryStore
    private let defaultsStore: SetupDefaultsStore
    private let onStart: (WorkoutPlan) -> Void

    init(
        presenter: HomePresentationLogic,
        historyStore: HistoryStore = .shared,
        defaultsStore: SetupDefaultsStore = .shared,
        onStart: @escaping (WorkoutPlan) -> Void
    ) {
        self.presenter = presenter
        self.historyStore = historyStore
        self.defaultsStore = defaultsStore
        self.onStart = onStart
    }

    func load(_ request: HomeModels.Load.Request) {
        let response = HomeModels.Load.Response(
            types: WorkoutType.allCases,
            completedCount: historyStore.load().count,
            lastPlan: defaultsStore.lastPlan
        )
        presenter.presentLoad(response)
    }

    func repeatLast() {
        guard let plan = defaultsStore.lastPlan else { return }
        onStart(plan)
    }

    func startPreset(_ preset: HomeModels.Preset) {
        let plan = WorkoutPlan(
            type: preset.type,
            blocks: [MixBlock(block: preset.block)],
            countdown: defaultsStore.countdown
        )
        onStart(plan)
    }
}
