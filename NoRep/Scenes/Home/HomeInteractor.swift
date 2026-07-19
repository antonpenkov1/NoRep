import Foundation

@MainActor
protocol HomeBusinessLogic {
    func load(_ request: HomeModels.Load.Request)
}

@MainActor
final class HomeInteractor: HomeBusinessLogic {

    private let presenter: HomePresentationLogic
    private let historyStore: HistoryStore

    init(presenter: HomePresentationLogic, historyStore: HistoryStore = .shared) {
        self.presenter = presenter
        self.historyStore = historyStore
    }

    func load(_ request: HomeModels.Load.Request) {
        let response = HomeModels.Load.Response(
            types: WorkoutType.allCases,
            completedCount: historyStore.load().count
        )
        presenter.presentLoad(response)
    }
}
