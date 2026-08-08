import Foundation
import HealthKit
import WatchKit
import SwiftUI

/// Drives a workout on the wrist: shared TimerEngine + HKWorkoutSession
/// (keeps the app running and feeds the activity rings) + haptic cues.
@MainActor
final class WatchWorkoutManager: NSObject, ObservableObject {

    struct Display {
        var blockTitle = ""
        var label = ""
        var timeText = ""
        var kind = "prepare"
        var roundsText: String?
        var showsRoundButton = false
        var isPaused = false
        var isFinished = false
        var totalText = ""
    }

    @Published private(set) var display = Display()

    private let engine = TimerEngine()
    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var plan: WorkoutPlan?
    private var rounds = 0
    private var splits: [Double] = []
    private var lastTotal: TimeInterval = 0
    private var resultSent = false

    func start(plan: WorkoutPlan) {
        guard engine.state == .idle else { return }
        self.plan = plan
        wireEngine()
        startHealthSession()
        engine.start(segments: WorkoutCompiler.compile(plan))
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
        rounds += 1
        splits.append((lastTotal * 10).rounded() / 10)
        WKInterfaceDevice.current().play(.click)
        refreshRounds()
    }

    func advance() {
        engine.advance()
    }

    func finish() {
        engine.stop()
    }

    // MARK: - Internals

    private func wireEngine() {
        engine.onTick = { [weak self] snapshot in
            self?.render(snapshot)
        }
        engine.onEvent = { [weak self] event in
            guard let self else { return }
            switch event {
            case .warningTick:
                WKInterfaceDevice.current().play(.click)
            case .segmentStarted(let segment):
                switch segment.kind {
                case .work: WKInterfaceDevice.current().play(.start)
                case .rest: WKInterfaceDevice.current().play(.stop)
                case .prepare: break
                }
            case .halfway:
                WKInterfaceDevice.current().play(.directionUp)
            case .finished:
                WKInterfaceDevice.current().play(.success)
                self.handleFinished()
            }
        }
    }

    private func render(_ snapshot: TimerEngine.Snapshot) {
        lastTotal = snapshot.totalElapsed
        guard let segment = snapshot.segment, snapshot.state != .finished else { return }

        var timeText: String
        if let duration = segment.duration, !segment.countsUp {
            let remaining = duration - snapshot.segmentElapsed
            timeText = segment.kind == .prepare
                ? "\(max(1, Int(remaining.rounded(.up))))"
                : TimeFormat.clockCeil(remaining)
        } else {
            timeText = TimeFormat.clock(snapshot.segmentElapsed)
        }

        display = Display(
            blockTitle: segment.blockTitle,
            label: segment.label,
            timeText: timeText,
            kind: segment.kind.rawValue,
            roundsText: segment.tracksRounds ? "\(rounds)" : nil,
            showsRoundButton: segment.tracksRounds,
            isPaused: snapshot.state == .paused,
            isFinished: false,
            totalText: TimeFormat.clock(snapshot.totalElapsed)
        )
    }

    private func refreshRounds() {
        if display.showsRoundButton {
            display.roundsText = "\(rounds)"
        }
    }

    private func handleFinished() {
        endHealthSession()
        guard let plan, !resultSent else { return }
        resultSent = true
        let result = WorkoutResult(
            date: Date(),
            title: plan.title,
            detail: plan.detail,
            totalSeconds: Int(lastTotal.rounded()),
            rounds: rounds > 0 ? rounds : nil,
            typeID: plan.type.rawValue,
            splits: splits.isEmpty ? nil : splits,
            note: plan.blocks.compactMap(\.trimmedNote).joined(separator: "\n").isEmpty
                ? nil
                : plan.blocks.compactMap(\.trimmedNote).joined(separator: "\n")
        )
        WatchSync.shared.send(result)
        display.isFinished = true
        display.totalText = TimeFormat.clock(lastTotal)
        display.roundsText = rounds > 0 ? "\(rounds)" : nil
    }

    private func startHealthSession() {
        #if DEBUG
        // Screenshot automation: skip the Health permission sheet in demo mode.
        if UserDefaults.standard.bool(forKey: "DemoWorkout") { return }
        #endif
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .functionalStrengthTraining
        configuration.locationType = .indoor

        Task {
            try? await healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
            do {
                let session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
                self.session = session
                session.startActivity(with: Date())
                let builder = session.associatedWorkoutBuilder()
                builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
                try? await builder.beginCollection(at: Date())
            } catch {
                // No session — the timer still works while the app is active.
            }
        }
    }

    private func endHealthSession() {
        guard let session else { return }
        self.session = nil
        let builder = session.associatedWorkoutBuilder()
        session.end()
        Task {
            try? await builder.endCollection(at: Date())
            try? await builder.finishWorkout()
        }
    }
}
