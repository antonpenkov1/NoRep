import UIKit

@MainActor
protocol WorkoutBusinessLogic {
    func start()
    func togglePause()
    func addRound()
    func advanceSegment()
    func finishEarly()
    func abandon()
    func updateSummary(_ edit: WorkoutSceneModels.SummaryEdit)
}

@MainActor
final class WorkoutInteractor: WorkoutBusinessLogic {

    private let presenter: WorkoutPresentationLogic
    private let plan: WorkoutPlan
    private let engine = TimerEngine()
    private let sound: SoundService
    private let haptics = HapticService()
    private let historyStore: HistoryStore
    private let liveActivity = LiveActivityService()

    /// Rounds tallied per segment index (AMRAP / For Time).
    private var rounds: [Int: Int] = [:]
    /// Cumulative work-time marks, one per tallied round.
    private var splits: [Double] = []
    private var lastSnapshot: TimerEngine.Snapshot?
    private var savedResult: WorkoutResult?

    init(
        plan: WorkoutPlan,
        presenter: WorkoutPresentationLogic,
        historyStore: HistoryStore = .shared,
        defaultsStore: SetupDefaultsStore = .shared
    ) {
        self.plan = plan
        self.presenter = presenter
        self.historyStore = historyStore
        self.sound = SoundService(isEnabled: defaultsStore.soundEnabled)
        wireEngine()
    }

    func start() {
        guard engine.state == .idle else { return }
        let segments = WorkoutCompiler.compile(plan)
        UIApplication.shared.isIdleTimerDisabled = true
        sound.beginWorkoutSession()
        engine.start(segments: segments)
        liveActivity.start(title: plan.title)
        pushLiveActivityState()
    }

    func togglePause() {
        switch engine.state {
        case .running: engine.pause()
        case .paused: engine.resume()
        default: break
        }
        pushLiveActivityState()
    }

    func addRound() {
        guard engine.state == .running, engine.currentSegment?.tracksRounds == true else { return }
        rounds[engine.segmentIndex, default: 0] += 1
        splits.append(((lastSnapshot?.totalElapsed ?? 0) * 10).rounded() / 10)
        haptics.roundCounted()
        pushLiveActivityState()
    }

    func advanceSegment() {
        engine.advance()
    }

    func finishEarly() {
        engine.stop()
    }

    /// Leaving without finishing — nothing is saved.
    func abandon() {
        UIApplication.shared.isIdleTimerDisabled = false
        sound.endWorkoutSession()
        liveActivity.end()
    }

    func updateSummary(_ edit: WorkoutSceneModels.SummaryEdit) {
        guard var result = savedResult else { return }
        let name = edit.name.trimmingCharacters(in: .whitespacesAndNewlines)
        result.title = name.isEmpty ? plan.type.title : name
        let note = edit.note.trimmingCharacters(in: .whitespacesAndNewlines)
        result.note = note.isEmpty ? nil : note
        result.isRx = edit.isRx
        result.feeling = edit.feeling
        savedResult = result
        historyStore.update(result)
        presentSummary(result)
    }

    // MARK: - Engine wiring

    private func wireEngine() {
        engine.onTick = { [weak self] snapshot in
            guard let self else { return }
            self.lastSnapshot = snapshot
            self.presenter.presentTick(.init(
                snapshot: snapshot,
                totalRounds: self.totalRounds,
                nextSegment: self.nextSegment(after: snapshot.segmentIndex)
            ))
            if snapshot.state == .finished {
                self.handleFinished(snapshot: snapshot)
            }
        }

        engine.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .warningTick:
                self.sound.play(.tick)
                self.haptics.tick()
            case .segmentStarted(let segment):
                switch segment.kind {
                case .work:
                    self.sound.play(.go)
                    self.haptics.segmentChange()
                case .rest:
                    self.sound.play(.rest)
                    self.haptics.segmentChange()
                case .prepare:
                    break
                }
                self.pushLiveActivityState()
            case .finished:
                self.sound.play(.finish)
                self.haptics.finished()
            }
        }
    }

    private func handleFinished(snapshot: TimerEngine.Snapshot) {
        UIApplication.shared.isIdleTimerDisabled = false
        sound.endWorkoutSession()
        liveActivity.end()
        if savedResult == nil {
            let notes = plan.blocks.compactMap(\.trimmedNote)
            let result = WorkoutResult(
                date: Date(),
                title: plan.title,
                detail: plan.detail,
                totalSeconds: Int(snapshot.totalElapsed.rounded()),
                rounds: totalRounds > 0 ? totalRounds : nil,
                typeID: plan.type.rawValue,
                splits: splits.isEmpty ? nil : splits,
                note: notes.isEmpty ? nil : notes.joined(separator: "\n")
            )
            savedResult = result
            historyStore.add(result)
        }
        if let savedResult {
            presentSummary(savedResult)
        }
    }

    private func presentSummary(_ result: WorkoutResult) {
        let series = historyStore.results(named: result.title, excluding: result.id)
        // Comparable: For Time compares by time; everything else needs round counts on both sides.
        let comparable = series.filter { other in
            result.typeID == WorkoutType.forTime.rawValue || (result.rounds != nil && other.rounds != nil)
        }
        let best = comparable.min { $0.beats($1) }
        let isPR = !comparable.isEmpty && comparable.allSatisfy { result.beats($0) }
        presenter.presentSummary(.init(
            result: result,
            previousBest: best,
            attemptNumber: series.count + 1,
            isPR: isPR
        ))
    }

    private var totalRounds: Int {
        rounds.values.reduce(0, +)
    }

    private func nextSegment(after index: Int) -> WorkoutSegment? {
        let next = index + 1
        return engine.segments.indices.contains(next) ? engine.segments[next] : nil
    }

    private func pushLiveActivityState() {
        guard let snapshot = lastSnapshot ?? nil else {
            liveActivity.update(engineState: engine.state, segment: engine.currentSegment, segmentElapsed: 0, roundsText: nil)
            return
        }
        liveActivity.update(
            engineState: engine.state,
            segment: engine.currentSegment,
            segmentElapsed: snapshot.segmentElapsed,
            roundsText: engine.currentSegment?.tracksRounds == true ? "\(totalRounds)" : nil
        )
    }
}
