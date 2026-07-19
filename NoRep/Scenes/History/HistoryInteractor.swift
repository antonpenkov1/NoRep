import Foundation

@MainActor
protocol HistoryBusinessLogic {
    func load()
    func delete(ids: [UUID])
    func clearAll()
}

@MainActor
final class HistoryInteractor: HistoryBusinessLogic {

    private let presenter: HistoryPresentationLogic
    private let historyStore: HistoryStore

    init(presenter: HistoryPresentationLogic, historyStore: HistoryStore = .shared) {
        self.presenter = presenter
        self.historyStore = historyStore
    }

    func load() {
        presenter.presentLoad(.init(results: historyStore.load()))
    }

    func delete(ids: [UUID]) {
        historyStore.delete(ids: Set(ids))
        load()
    }

    func clearAll() {
        historyStore.clear()
        load()
    }
}
