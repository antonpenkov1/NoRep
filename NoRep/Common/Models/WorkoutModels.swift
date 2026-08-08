import Foundation

// MARK: - Workout types

enum WorkoutType: String, Codable, CaseIterable, Identifiable, Hashable {
    case emom
    case amrap
    case forTime
    case tabata
    case mix

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emom: return "EMOM"
        case .amrap: return "AMRAP"
        case .forTime: return "For Time"
        case .tabata: return "Tabata"
        case .mix: return "Mix"
        }
    }

    var subtitle: String {
        switch self {
        case .emom: return "Every minute on the minute"
        case .amrap: return "As many rounds as possible"
        case .forTime: return "Beat the clock"
        case .tabata: return "Work / rest intervals"
        case .mix: return "Chain timers into one WOD"
        }
    }

    var systemImage: String {
        switch self {
        case .emom: return "metronome"
        case .amrap: return "arrow.triangle.2.circlepath"
        case .forTime: return "flag.checkered"
        case .tabata: return "timer"
        case .mix: return "square.stack.3d.up"
        }
    }
}

// MARK: - Block configs

struct EmomConfig: Codable, Hashable {
    var rounds: Int = 10
    var interval: TimeInterval = 60
}

struct AmrapConfig: Codable, Hashable {
    var duration: TimeInterval = 10 * 60
}

struct ForTimeConfig: Codable, Hashable {
    var isCapEnabled: Bool = true
    var timeCap: TimeInterval = 10 * 60
}

struct TabataConfig: Codable, Hashable {
    var rounds: Int = 8
    var work: TimeInterval = 20
    var rest: TimeInterval = 10
}

// MARK: - Blocks & plan

enum WorkoutBlock: Codable, Hashable {
    case emom(EmomConfig)
    case amrap(AmrapConfig)
    case forTime(ForTimeConfig)
    case tabata(TabataConfig)
    case rest(TimeInterval)

    var typeTitle: String {
        switch self {
        case .emom: return "EMOM"
        case .amrap: return "AMRAP"
        case .forTime: return "FOR TIME"
        case .tabata: return "TABATA"
        case .rest: return "REST"
        }
    }

    /// Total duration of the block, nil when open-ended (For Time without a cap).
    var totalDuration: TimeInterval? {
        switch self {
        case .emom(let c): return TimeInterval(c.rounds) * c.interval
        case .amrap(let c): return c.duration
        case .forTime(let c): return c.isCapEnabled ? c.timeCap : nil
        case .tabata(let c):
            guard c.rounds > 0 else { return 0 }
            return TimeInterval(c.rounds) * c.work + TimeInterval(c.rounds - 1) * c.rest
        case .rest(let d): return d
        }
    }

    var summary: String {
        switch self {
        case .emom(let c): return "\(c.rounds) × \(TimeFormat.short(c.interval))"
        case .amrap(let c): return TimeFormat.short(c.duration)
        case .forTime(let c): return c.isCapEnabled ? "cap \(TimeFormat.short(c.timeCap))" : "no cap"
        case .tabata(let c): return "\(c.rounds) × \(Int(c.work))s / \(Int(c.rest))s"
        case .rest(let d): return TimeFormat.short(d)
        }
    }
}

/// A block with identity and an optional movements note ("21-15-9 thrusters / pull-ups").
/// Used both by the Mix builder and as the plan's block unit.
struct MixBlock: Identifiable, Codable, Hashable {
    var id = UUID()
    var block: WorkoutBlock
    var note: String?

    var trimmedNote: String? {
        guard let text = note?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return text
    }
}

struct WorkoutPlan: Hashable {
    var type: WorkoutType
    var blocks: [MixBlock]
    var countdown: TimeInterval
    /// Athlete-given name ("Fran", "Murph") — the key for benchmark/PR tracking.
    var customName: String?

    var title: String {
        if let name = customName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return type.title
    }

    /// Total planned duration, nil if any block is open-ended.
    var totalDuration: TimeInterval? {
        var total: TimeInterval = 0
        for item in blocks {
            guard let d = item.block.totalDuration else { return nil }
            total += d
        }
        return total
    }

    var detail: String {
        blocks.map { "\($0.block.typeTitle) \($0.block.summary)" }.joined(separator: " · ")
    }
}

// MARK: - Segments (compiled timeline)

enum SegmentKind: String, Hashable {
    case prepare
    case work
    case rest
}

struct WorkoutSegment: Hashable {
    /// Index of the source block in the plan, -1 for the get-ready countdown.
    var blockIndex: Int
    var blockTitle: String
    var kind: SegmentKind
    var label: String
    /// nil = open-ended, runs until the athlete stops it.
    var duration: TimeInterval?
    var countsUp: Bool
    /// AMRAP / For Time segments let the athlete tally rounds.
    var tracksRounds: Bool
    /// The block's movements note, shown on the timer screen as a what-to-do hint.
    var note: String?
}

// MARK: - Result

struct WorkoutResult: Codable, Identifiable, Hashable {
    var id = UUID()
    var date: Date
    var title: String
    var detail: String
    var totalSeconds: Int
    var rounds: Int?
    // v1.1 — all optional so v1.0 history decodes untouched.
    /// Workout type raw value; used to decide how to compare scores for PRs.
    var typeID: String?
    /// Cumulative tap times (seconds from workout start) for AMRAP / For Time rounds.
    var splits: [Double]?
    /// What the workout was: "21-15-9 thrusters / pull-ups".
    var note: String?
    /// As prescribed (true) or scaled (false); nil — not set.
    var isRx: Bool?
    /// How it felt, 1 (destroyed) ... 5 (strong); nil — not set.
    var feeling: Int?

    /// Per-round durations derived from cumulative splits.
    var roundDurations: [Double] {
        guard let splits, !splits.isEmpty else { return [] }
        var previous = 0.0
        return splits.map { tap in
            defer { previous = tap }
            return tap - previous
        }
    }

    var scoreText: String {
        if let rounds, rounds > 0 {
            return rounds == 1 ? "1 round" : "\(rounds) rounds"
        }
        return TimeFormat.clock(TimeInterval(totalSeconds))
    }

    /// true if this result beats `other` for the same named workout.
    func beats(_ other: WorkoutResult) -> Bool {
        if typeID == WorkoutType.forTime.rawValue {
            return totalSeconds < other.totalSeconds
        }
        if let mine = rounds, let theirs = other.rounds {
            return mine > theirs
        }
        return false
    }
}

// MARK: - Time formatting

enum TimeFormat {
    /// "12:34" or "1:02:03"
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.down)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }

    /// Ceiling variant for countdowns so "0:01" is shown through the final second.
    static func clockCeil(_ interval: TimeInterval) -> String {
        clock(TimeInterval(max(0, Int(interval.rounded(.up)))))
    }

    /// "10:00", "0:30" → compact "10 min" / "30 sec" style for summaries.
    static func short(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let m = total / 60
        let s = total % 60
        if m > 0 && s == 0 { return "\(m):00" }
        return String(format: "%d:%02d", m, s)
    }
}
