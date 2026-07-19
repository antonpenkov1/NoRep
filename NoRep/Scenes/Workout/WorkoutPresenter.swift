import SwiftUI

@MainActor
protocol WorkoutPresentationLogic {
    func presentTick(_ response: WorkoutSceneModels.Tick.Response)
    func presentSummary(_ response: WorkoutSceneModels.Summary.Response)
}

@MainActor
final class WorkoutPresenter: WorkoutPresentationLogic {

    weak var display: WorkoutViewStore?

    func presentTick(_ response: WorkoutSceneModels.Tick.Response) {
        let snapshot = response.snapshot

        let state: WorkoutSceneModels.DisplayState
        switch snapshot.state {
        case .idle: state = .idle
        case .running: state = .running
        case .paused: state = .paused
        case .finished: state = .finished
        }

        guard let segment = snapshot.segment, state != .finished else {
            display?.displayTick(WorkoutSceneModels.Tick.ViewModel(
                state: state,
                blockTitle: "",
                label: "",
                timeText: "",
                phaseColor: Theme.accent,
                progress: nil,
                totalLine: "",
                nextUpLine: nil,
                showsRoundButton: false,
                roundsText: "",
                showsDoneSegment: false,
                showsSkip: false
            ))
            return
        }

        let timeText: String
        var progress: Double?
        if let duration = segment.duration {
            if segment.countsUp {
                timeText = TimeFormat.clock(snapshot.segmentElapsed)
                progress = snapshot.segmentElapsed / duration
            } else {
                let remaining = duration - snapshot.segmentElapsed
                timeText = segment.kind == .prepare
                    ? "\(max(1, Int(remaining.rounded(.up))))"
                    : TimeFormat.clockCeil(remaining)
                progress = remaining / duration
            }
        } else {
            timeText = TimeFormat.clock(snapshot.segmentElapsed)
            progress = nil
        }

        let nextUpLine = response.nextSegment.map { next in
            let duration = next.duration.map { " \(TimeFormat.clock($0))" } ?? ""
            return "Next: \(next.kind == .rest ? "REST" : next.blockTitle)\(duration)"
        }

        display?.displayTick(WorkoutSceneModels.Tick.ViewModel(
            state: state,
            blockTitle: segment.blockTitle,
            label: segment.label,
            timeText: timeText,
            phaseColor: Theme.color(for: segment.kind),
            progress: progress.map { max(0, min(1, $0)) },
            totalLine: "Total \(TimeFormat.clock(snapshot.totalElapsed))",
            nextUpLine: nextUpLine,
            showsRoundButton: segment.tracksRounds,
            roundsText: response.totalRounds == 1 ? "1 round" : "\(response.totalRounds) rounds",
            showsDoneSegment: segment.duration == nil,
            showsSkip: response.nextSegment != nil && segment.kind != .prepare
        ))
    }

    func presentSummary(_ response: WorkoutSceneModels.Summary.Response) {
        display?.displaySummary(WorkoutSceneModels.Summary.ViewModel(
            title: response.plan.title,
            detail: response.plan.detail,
            totalText: TimeFormat.clock(response.totalElapsed),
            roundsText: response.totalRounds > 0
                ? (response.totalRounds == 1 ? "1 round" : "\(response.totalRounds) rounds")
                : nil
        ))
    }
}
