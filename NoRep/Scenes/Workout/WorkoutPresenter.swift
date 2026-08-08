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
                noteText: nil,
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
            return String(localized: "Next: \(next.kind == .rest ? "REST" : next.blockTitle)\(duration)")
        }

        display?.displayTick(WorkoutSceneModels.Tick.ViewModel(
            state: state,
            blockTitle: segment.blockTitle,
            label: segment.label,
            timeText: timeText,
            phaseColor: Theme.color(for: segment.kind),
            progress: progress.map { max(0, min(1, $0)) },
            totalLine: String(localized: "Total \(TimeFormat.clock(snapshot.totalElapsed))"),
            nextUpLine: nextUpLine,
            noteText: segment.note,
            showsRoundButton: segment.tracksRounds,
            roundsText: response.totalRounds == 1
                ? String(localized: "1 round")
                : String(localized: "\(response.totalRounds) rounds"),
            showsDoneSegment: segment.duration == nil,
            showsSkip: response.nextSegment != nil && segment.kind != .prepare
        ))
    }

    func presentSummary(_ response: WorkoutSceneModels.Summary.Response) {
        let result = response.result

        var prLine: String?
        if response.isPR, let previous = response.previousBest {
            prLine = String(localized: "New PR! Previous best \(previous.scoreText)")
        } else if let best = response.previousBest {
            prLine = String(localized: "Best \(best.scoreText) · attempt #\(response.attemptNumber)")
        }

        let durations = result.roundDurations
        let splitLines = durations.enumerated().map { index, seconds in
            String(localized: "Round \(index + 1) — \(TimeFormat.clock(seconds))")
        }

        display?.displaySummary(WorkoutSceneModels.Summary.ViewModel(
            name: result.title,
            detail: result.detail,
            totalText: TimeFormat.clock(TimeInterval(result.totalSeconds)),
            roundsText: result.rounds.map { $0 == 1 ? String(localized: "1 round") : String(localized: "\($0) rounds") },
            note: result.note ?? "",
            isRx: result.isRx,
            feeling: result.feeling,
            roundDurations: durations,
            splitLines: splitLines,
            prLine: prLine,
            isPR: response.isPR
        ))
    }
}
