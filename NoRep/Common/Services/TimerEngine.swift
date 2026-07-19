import Foundation

/// Drives a compiled segment timeline. All timing is derived from wall-clock anchors,
/// so pauses are exact and time spent in background is accounted for on the next tick.
@MainActor
final class TimerEngine {

    enum State: Equatable {
        case idle
        case running
        case paused
        case finished
    }

    enum Event {
        /// 3-2-1 warning ticks before a timed segment ends.
        case warningTick(secondsLeft: Int)
        case segmentStarted(WorkoutSegment)
        case finished
    }

    struct Snapshot {
        var state: State
        var segmentIndex: Int
        var segment: WorkoutSegment?
        var segmentElapsed: TimeInterval
        var totalElapsed: TimeInterval
    }

    private(set) var state: State = .idle
    private(set) var segments: [WorkoutSegment] = []
    private(set) var segmentIndex: Int = 0

    var onTick: ((Snapshot) -> Void)?
    var onEvent: ((Event) -> Void)?

    private var timer: Timer?
    /// Wall-clock moment the current segment (re)started running.
    private var anchor: Date?
    /// Time accumulated in the current segment before the last pause.
    private var accumulated: TimeInterval = 0
    /// Sum of durations of all completed segments (open-ended use actual elapsed).
    private var completedElapsed: TimeInterval = 0
    private var lastWarningSecond: Int = .max

    var currentSegment: WorkoutSegment? {
        segments.indices.contains(segmentIndex) ? segments[segmentIndex] : nil
    }

    // MARK: - Control

    func start(segments: [WorkoutSegment]) {
        guard !segments.isEmpty else { return }
        self.segments = segments
        segmentIndex = 0
        accumulated = 0
        completedElapsed = 0
        lastWarningSecond = .max
        anchor = Date()
        state = .running
        onEvent?(.segmentStarted(segments[0]))
        startTimer()
        emitTick()
    }

    func pause() {
        guard state == .running else { return }
        accumulated = currentSegmentElapsed()
        anchor = nil
        state = .paused
        stopTimer()
        emitTick()
    }

    func resume() {
        guard state == .paused else { return }
        anchor = Date()
        state = .running
        startTimer()
        emitTick()
    }

    /// Manually complete the current segment (skip, or "done" on an open-ended one).
    func advance() {
        guard state == .running || state == .paused else { return }
        completeCurrentSegment(overshoot: 0)
    }

    func stop() {
        guard state != .finished else { return }
        finish(includeCurrentSegment: true)
    }

    // MARK: - Internals

    private func startTimer() {
        stopTimer()
        let timer = Timer(timeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func currentSegmentElapsed() -> TimeInterval {
        guard let anchor else { return accumulated }
        return accumulated + Date().timeIntervalSince(anchor)
    }

    private func tick() {
        guard state == .running, let segment = currentSegment else { return }
        let elapsed = currentSegmentElapsed()

        if let duration = segment.duration {
            let remaining = duration - elapsed
            if remaining <= 0 {
                completeCurrentSegment(overshoot: -remaining)
                return
            }
            let second = Int(remaining.rounded(.up))
            if second <= 3 && second >= 1 && second < lastWarningSecond {
                lastWarningSecond = second
                onEvent?(.warningTick(secondsLeft: second))
            }
        }
        emitTick()
    }

    private func completeCurrentSegment(overshoot: TimeInterval) {
        guard let segment = currentSegment else { return }
        completedElapsed += segment.duration ?? currentSegmentElapsed()

        if segmentIndex + 1 < segments.count {
            segmentIndex += 1
            // Carry the overshoot into the next segment so long workouts do not drift,
            // and multiple missed segments (after backgrounding) resolve on next ticks.
            accumulated = overshoot
            anchor = state == .running ? Date() : nil
            lastWarningSecond = .max
            onEvent?(.segmentStarted(segments[segmentIndex]))
            emitTick()
        } else {
            // Current segment's time is already in completedElapsed.
            finish(includeCurrentSegment: false)
        }
    }

    private func finish(includeCurrentSegment: Bool) {
        stopTimer()
        if includeCurrentSegment {
            completedElapsed += currentSegmentElapsed()
        }
        accumulated = 0
        anchor = nil
        state = .finished
        onEvent?(.finished)
        emitTick()
    }

    private func totalElapsedNow() -> TimeInterval {
        // completedElapsed already includes finished segments; add the live one.
        completedElapsed + (state == .finished ? 0 : currentSegmentElapsed())
    }

    private func emitTick() {
        onTick?(Snapshot(
            state: state,
            segmentIndex: segmentIndex,
            segment: currentSegment,
            segmentElapsed: state == .finished ? 0 : currentSegmentElapsed(),
            totalElapsed: state == .finished ? completedElapsed : totalElapsedNow()
        ))
    }
}
