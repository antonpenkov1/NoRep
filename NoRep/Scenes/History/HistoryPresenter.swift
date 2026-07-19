import Foundation

@MainActor
protocol HistoryPresentationLogic {
    func presentLoad(_ response: HistoryModels.Load.Response)
}

@MainActor
final class HistoryPresenter: HistoryPresentationLogic {

    weak var display: HistoryViewStore?

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    func presentLoad(_ response: HistoryModels.Load.Response) {
        let rows = response.results.map { result in
            HistoryModels.Load.ViewModel.Row(
                id: result.id,
                title: result.title,
                detail: result.detail,
                dateText: dateFormatter.string(from: result.date),
                timeText: TimeFormat.clock(TimeInterval(result.totalSeconds)),
                scoreText: result.rounds.map { $0 == 1 ? "1 round" : "\($0) rounds" }
            )
        }
        display?.displayLoad(HistoryModels.Load.ViewModel(rows: rows))
    }
}
