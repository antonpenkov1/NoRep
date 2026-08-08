import Foundation

@MainActor
protocol SetupPresentationLogic {
    func presentRefresh(_ response: SetupModels.Refresh.Response)
}

@MainActor
final class SetupPresenter: SetupPresentationLogic {

    weak var display: SetupViewStore?

    func presentRefresh(_ response: SetupModels.Refresh.Response) {
        let s = response.state
        display?.displayRefresh(SetupModels.Refresh.ViewModel(
            title: s.type.title,
            summary: summary(for: s),
            emom: s.emom,
            amrap: s.amrap,
            forTime: s.forTime,
            tabata: s.tabata,
            countdown: s.countdown,
            soundEnabled: s.soundEnabled,
            name: s.name,
            note: s.note
        ))
    }

    private func summary(for s: SetupModels.State) -> String {
        switch s.type {
        case .emom:
            let total = TimeInterval(s.emom.rounds) * s.emom.interval
            return String(localized: "\(s.emom.rounds) rounds × \(TimeFormat.clock(s.emom.interval)) — total \(TimeFormat.clock(total))")
        case .amrap:
            return String(localized: "As many rounds as possible in \(TimeFormat.clock(s.amrap.duration))")
        case .forTime:
            return s.forTime.isCapEnabled
                ? String(localized: "Finish the work before \(TimeFormat.clock(s.forTime.timeCap))")
                : String(localized: "Clock runs up until you hit Finish")
        case .tabata:
            let block = WorkoutBlock.tabata(s.tabata)
            let total = block.totalDuration ?? 0
            return String(localized: "\(s.tabata.rounds) × (\(Int(s.tabata.work))s work / \(Int(s.tabata.rest))s rest) — total \(TimeFormat.clock(total))")
        case .mix:
            return ""
        }
    }
}
