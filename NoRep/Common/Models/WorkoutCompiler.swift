import Foundation

/// Compiles a workout plan into a flat timeline of segments the timer engine runs through.
enum WorkoutCompiler {

    static func compile(_ plan: WorkoutPlan) -> [WorkoutSegment] {
        var segments: [WorkoutSegment] = []

        if plan.countdown > 0 {
            segments.append(WorkoutSegment(
                blockIndex: -1,
                blockTitle: plan.title.uppercased(),
                kind: .prepare,
                label: "GET READY",
                duration: plan.countdown,
                countsUp: false,
                tracksRounds: false
            ))
        }

        let showBlockNumbers = plan.blocks.count > 1
        for (index, item) in plan.blocks.enumerated() {
            let prefix = showBlockNumbers ? "BLOCK \(index + 1)/\(plan.blocks.count) · " : ""
            var blockSegments = compile(block: item.block, at: index, titlePrefix: prefix)
            if let note = item.trimmedNote {
                for i in blockSegments.indices {
                    blockSegments[i].note = note
                }
            }
            segments.append(contentsOf: blockSegments)
        }
        return segments
    }

    private static func compile(block: WorkoutBlock, at index: Int, titlePrefix: String) -> [WorkoutSegment] {
        let title = titlePrefix + block.typeTitle

        switch block {
        case .emom(let c):
            return (1...max(1, c.rounds)).map { round in
                WorkoutSegment(
                    blockIndex: index,
                    blockTitle: title,
                    kind: .work,
                    label: "ROUND \(round)/\(c.rounds)",
                    duration: c.interval,
                    countsUp: false,
                    tracksRounds: false
                )
            }

        case .amrap(let c):
            return [WorkoutSegment(
                blockIndex: index,
                blockTitle: title,
                kind: .work,
                label: "MAX ROUNDS",
                duration: c.duration,
                countsUp: false,
                tracksRounds: true
            )]

        case .forTime(let c):
            return [WorkoutSegment(
                blockIndex: index,
                blockTitle: title,
                kind: .work,
                label: c.isCapEnabled ? "CAP \(TimeFormat.clock(c.timeCap))" : "NO CAP",
                duration: c.isCapEnabled ? c.timeCap : nil,
                countsUp: true,
                tracksRounds: true
            )]

        case .tabata(let c):
            var result: [WorkoutSegment] = []
            for round in 1...max(1, c.rounds) {
                result.append(WorkoutSegment(
                    blockIndex: index,
                    blockTitle: title,
                    kind: .work,
                    label: "WORK \(round)/\(c.rounds)",
                    duration: c.work,
                    countsUp: false,
                    tracksRounds: false
                ))
                // Classic Tabata skips the rest after the final work interval.
                if round < c.rounds && c.rest > 0 {
                    result.append(WorkoutSegment(
                        blockIndex: index,
                        blockTitle: title,
                        kind: .rest,
                        label: "REST \(round)/\(c.rounds)",
                        duration: c.rest,
                        countsUp: false,
                        tracksRounds: false
                    ))
                }
            }
            return result

        case .rest(let duration):
            return [WorkoutSegment(
                blockIndex: index,
                blockTitle: title,
                kind: .rest,
                label: "BREATHE",
                duration: duration,
                countsUp: false,
                tracksRounds: false
            )]
        }
    }
}
