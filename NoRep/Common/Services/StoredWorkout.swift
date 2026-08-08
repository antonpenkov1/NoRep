import Foundation
import SwiftData

/// SwiftData row for a finished workout. `WorkoutResult` stays the value type
/// used across the VIP scenes; this model is the persistence shape.
@Model
final class StoredWorkout {
    @Attribute(.unique) var id: UUID
    var date: Date
    var title: String
    var detail: String
    var totalSeconds: Int
    var rounds: Int?
    var typeID: String?
    var splits: [Double]?
    var note: String?
    var isRx: Bool?
    var feeling: Int?

    init(from result: WorkoutResult) {
        id = result.id
        date = result.date
        title = result.title
        detail = result.detail
        totalSeconds = result.totalSeconds
        rounds = result.rounds
        typeID = result.typeID
        splits = result.splits
        note = result.note
        isRx = result.isRx
        feeling = result.feeling
    }

    func apply(_ result: WorkoutResult) {
        date = result.date
        title = result.title
        detail = result.detail
        totalSeconds = result.totalSeconds
        rounds = result.rounds
        typeID = result.typeID
        splits = result.splits
        note = result.note
        isRx = result.isRx
        feeling = result.feeling
    }

    var result: WorkoutResult {
        WorkoutResult(
            id: id,
            date: date,
            title: title,
            detail: detail,
            totalSeconds: totalSeconds,
            rounds: rounds,
            typeID: typeID,
            splits: splits,
            note: note,
            isRx: isRx,
            feeling: feeling
        )
    }
}
