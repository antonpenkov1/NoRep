import Foundation

@MainActor
protocol BenchmarksBusinessLogic {
    func load()
    func start(id: String)
}

@MainActor
final class BenchmarksInteractor: BenchmarksBusinessLogic {

    private let presenter: BenchmarksPresentationLogic
    private let historyStore: HistoryStore
    private let defaultsStore: SetupDefaultsStore
    private let onStart: (WorkoutPlan) -> Void

    init(
        presenter: BenchmarksPresentationLogic,
        historyStore: HistoryStore = .shared,
        defaultsStore: SetupDefaultsStore = .shared,
        onStart: @escaping (WorkoutPlan) -> Void
    ) {
        self.presenter = presenter
        self.historyStore = historyStore
        self.defaultsStore = defaultsStore
        self.onStart = onStart
    }

    func load() {
        var bestByName: [String: WorkoutResult] = [:]
        for wod in BenchmarkLibrary.all {
            if let best = historyStore.best(named: wod.name) {
                bestByName[wod.name] = best
            }
        }
        presenter.presentLoad(.init(benchmarks: BenchmarkLibrary.all, bestByName: bestByName))
    }

    func start(id: String) {
        guard let wod = BenchmarkLibrary.all.first(where: { $0.id == id }) else { return }
        onStart(wod.plan(countdown: defaultsStore.countdown))
    }
}
