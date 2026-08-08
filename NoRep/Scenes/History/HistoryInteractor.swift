import Foundation

@MainActor
protocol HistoryBusinessLogic {
    func load()
    func showDetail(id: UUID)
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
        let results = historyStore.load()
        presenter.presentLoad(.init(results: results, stats: JournalStats.compute(from: results)))
    }

    func showDetail(id: UUID) {
        let results = historyStore.load()
        guard let result = results.first(where: { $0.id == id }) else { return }
        var series = historyStore.results(named: result.title, excluding: result.id)
        series.append(result)
        series.sort { $0.date < $1.date }
        presenter.presentDetail(.init(result: result, series: series))
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
