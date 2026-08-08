import Foundation

@MainActor
protocol HistoryPresentationLogic {
    func presentLoad(_ response: HistoryModels.Load.Response)
    func presentDetail(_ response: HistoryModels.Detail.Response)
}

@MainActor
final class HistoryPresenter: HistoryPresentationLogic {

    weak var display: HistoryViewStore?

    private static let feelings = ["🤕", "😮‍💨", "😐", "💪", "🔥"]

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()

    func presentLoad(_ response: HistoryModels.Load.Response) {
        let rows = response.results.map { result in
            HistoryModels.Load.ViewModel.Row(
                id: result.id,
                title: result.title,
                detail: result.detail,
                note: result.note,
                dateText: dateFormatter.string(from: result.date),
                timeText: TimeFormat.clock(TimeInterval(result.totalSeconds)),
                scoreText: result.rounds.map { $0 == 1 ? "1 round" : "\($0) rounds" },
                rxText: result.isRx.map { $0 ? "RX" : "SCALED" },
                feelingEmoji: feelingEmoji(result.feeling)
            )
        }

        let stats = response.stats
        display?.displayLoad(HistoryModels.Load.ViewModel(
            rows: rows,
            stats: .init(
                streakText: "\(stats.streakDays)",
                thisWeekText: "\(stats.thisWeek)",
                thisMonthText: "\(stats.thisMonth)",
                totalText: "\(stats.totalWorkouts)",
                totalTimeText: stats.totalTimeText
            ),
            heatWeeks: stats.weeks
        ))
    }

    func presentDetail(_ response: HistoryModels.Detail.Response) {
        let result = response.result

        var attempts: [HistoryModels.Detail.ViewModel.Attempt] = []
        var caption: String?
        if response.series.count > 1 {
            let comparable = response.series.filter { other in
                result.typeID == WorkoutType.forTime.rawValue || other.rounds != nil
            }
            if comparable.count > 1 {
                let byTime = result.typeID == WorkoutType.forTime.rawValue
                caption = byTime ? "Time — lower is better" : "Rounds — higher is better"
                let bestValue = byTime
                    ? comparable.map(\.totalSeconds).min().map(Double.init)
                    : comparable.compactMap(\.rounds).max().map(Double.init)
                attempts = comparable.map { attempt in
                    let value = byTime ? Double(attempt.totalSeconds) : Double(attempt.rounds ?? 0)
                    return HistoryModels.Detail.ViewModel.Attempt(
                        id: attempt.id,
                        date: attempt.date,
                        dateText: shortDateFormatter.string(from: attempt.date),
                        value: value,
                        scoreText: attempt.scoreText,
                        isBest: value == bestValue,
                        isCurrent: attempt.id == result.id
                    )
                }
            }
        }

        display?.displayDetail(HistoryModels.Detail.ViewModel(
            id: result.id,
            title: result.title,
            dateText: dateFormatter.string(from: result.date),
            timeText: TimeFormat.clock(TimeInterval(result.totalSeconds)),
            scoreText: result.rounds.map { $0 == 1 ? "1 round" : "\($0) rounds" },
            detail: result.detail,
            note: result.note,
            rxText: result.isRx.map { $0 ? "RX" : "SCALED" },
            feelingEmoji: feelingEmoji(result.feeling),
            roundDurations: result.roundDurations,
            attempts: attempts,
            progressionCaption: caption
        ))
    }

    private func feelingEmoji(_ feeling: Int?) -> String? {
        guard let feeling, (1...Self.feelings.count).contains(feeling) else { return nil }
        return Self.feelings[feeling - 1]
    }
}
