import Foundation

/// Aggregates workout history into journal numbers: streak, period counters,
/// time under the clock, and a weeks × weekdays heatmap grid.
struct JournalStats {

    struct HeatDay: Identifiable, Hashable {
        var id: Date { date }
        var date: Date
        var count: Int
        var isFuture: Bool
        var isToday: Bool
    }

    var totalWorkouts: Int
    var totalSeconds: Int
    var thisWeek: Int
    var thisMonth: Int
    var streakDays: Int
    /// Column-major: `weeks[w][d]` — week w (oldest first), weekday d (week start first).
    var weeks: [[HeatDay]]

    static func compute(
        from results: [WorkoutResult],
        weeksBack: Int = 12,
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> JournalStats {
        let today = calendar.startOfDay(for: now)

        var countsByDay: [Date: Int] = [:]
        for result in results {
            let day = calendar.startOfDay(for: result.date)
            countsByDay[day, default: 0] += 1
        }

        // Streak: consecutive days with a workout, counting back from today
        // (an empty today doesn't break it — the athlete may train tonight).
        var streak = 0
        var cursor = today
        if countsByDay[cursor] == nil {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        while countsByDay[cursor] != nil {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now)
        let monthInterval = calendar.dateInterval(of: .month, for: now)
        let thisWeek = results.filter { weekInterval?.contains($0.date) == true }.count
        let thisMonth = results.filter { monthInterval?.contains($0.date) == true }.count

        // Heatmap: `weeksBack` full weeks ending with the current week.
        var weeks: [[HeatDay]] = []
        if let currentWeekStart = weekInterval?.start {
            for weekOffset in stride(from: weeksBack - 1, through: 0, by: -1) {
                guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: currentWeekStart) else { continue }
                var days: [HeatDay] = []
                for dayOffset in 0..<7 {
                    guard let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }
                    days.append(HeatDay(
                        date: day,
                        count: countsByDay[day] ?? 0,
                        isFuture: day > today,
                        isToday: day == today
                    ))
                }
                weeks.append(days)
            }
        }

        return JournalStats(
            totalWorkouts: results.count,
            totalSeconds: results.reduce(0) { $0 + $1.totalSeconds },
            thisWeek: thisWeek,
            thisMonth: thisMonth,
            streakDays: streak,
            weeks: weeks
        )
    }

    var totalTimeText: String {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }
}
