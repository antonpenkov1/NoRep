import UIKit

@MainActor
protocol WorkoutBusinessLogic {
    func start()
    func togglePause()
    func addRound()
    func advanceSegment()
    func finishEarly()
    func abandon()
}

@MainActor
final class WorkoutInteractor: WorkoutBusinessLogic {

    private let presenter: WorkoutPresentationLogic
    private let plan: WorkoutPlan
    private let engine = TimerEngine()
    private let sound: SoundService
    private let haptics = HapticService()
    private let historyStore: HistoryStore

    /// Rounds tallied per segment index (AMRAP / For Time).
    private var rounds: [Int: Int] = [:]
    private var resultSaved = false

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
        engine.start(segments: segments)
    }

    func togglePause() {
        switch engine.state {
        case .running: engine.pause()
        case .paused: engine.resume()
        default: break
        }
    }

    func addRound() {
        guard engine.state == .running, engine.currentSegment?.tracksRounds == true else { return }
        rounds[engine.segmentIndex, default: 0] += 1
        haptics.roundCounted()
        emitTickFromCurrentState()
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
    }

    // MARK: - Engine wiring

    private func wireEngine() {
        engine.onTick = { [weak self] snapshot in
            guard let self else { return }
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
            case .finished:
                self.sound.play(.finish)
                self.haptics.finished()
            }
        }
    }

    private func handleFinished(snapshot: TimerEngine.Snapshot) {
        UIApplication.shared.isIdleTimerDisabled = false
        if !resultSaved {
            resultSaved = true
            historyStore.add(WorkoutResult(
                date: Date(),
                title: plan.title,
                detail: plan.detail,
                totalSeconds: Int(snapshot.totalElapsed.rounded()),
                rounds: totalRounds > 0 ? totalRounds : nil
            ))
        }
        presenter.presentSummary(.init(
            plan: plan,
            totalElapsed: snapshot.totalElapsed,
            totalRounds: totalRounds
        ))
    }

    private var totalRounds: Int {
        rounds.values.reduce(0, +)
    }

    private func nextSegment(after index: Int) -> WorkoutSegment? {
        let next = index + 1
        return engine.segments.indices.contains(next) ? engine.segments[next] : nil
    }

    private func emitTickFromCurrentState() {
        // Rounds changed outside a timer tick; the next engine tick (≤50ms away)
        // will refresh the display, so nothing else is needed while running.
    }
}
