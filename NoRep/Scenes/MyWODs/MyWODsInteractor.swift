import Foundation

@MainActor
protocol MyWODsBusinessLogic {
    func load()
    func start(id: UUID)
    func delete(ids: [UUID])
}

@MainActor
final class MyWODsInteractor: MyWODsBusinessLogic {

    private let presenter: MyWODsPresentationLogic
    private let wodStore: WODStore
    private let historyStore: HistoryStore
    private let defaultsStore: SetupDefaultsStore
    private let onStart: (WorkoutPlan) -> Void

    init(
        presenter: MyWODsPresentationLogic,
        wodStore: WODStore = .shared,
        historyStore: HistoryStore = .shared,
        defaultsStore: SetupDefaultsStore = .shared,
        onStart: @escaping (WorkoutPlan) -> Void
    ) {
        self.presenter = presenter
        self.wodStore = wodStore
        self.historyStore = historyStore
        self.defaultsStore = defaultsStore
        self.onStart = onStart
    }

    func load() {
        let wods = wodStore.load()
        var bestByName: [String: WorkoutResult] = [:]
        for wod in wods {
            if let best = historyStore.best(named: wod.name) {
                bestByName[wod.name] = best
            }
        }
        presenter.presentLoad(.init(wods: wods, bestByName: bestByName))
    }

    func start(id: UUID) {
        guard let wod = wodStore.load().first(where: { $0.id == id }) else { return }
        var plan = wod.plan
        plan.countdown = defaultsStore.countdown
        onStart(plan)
    }

    func delete(ids: [UUID]) {
        wodStore.delete(ids: Set(ids))
        load()
    }
}
