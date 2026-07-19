import Foundation

/// Persists finished workouts as JSON in UserDefaults. Newest first.
final class HistoryStore {

    static let shared = HistoryStore()

    private let key = "norep.history.v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> [WorkoutResult] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([WorkoutResult].self, from: data)) ?? []
    }

    func add(_ result: WorkoutResult) {
        var all = load()
        all.insert(result, at: 0)
        save(all)
    }

    func delete(ids: Set<UUID>) {
        save(load().filter { !ids.contains($0.id) })
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }

    private func save(_ results: [WorkoutResult]) {
        if let data = try? JSONEncoder().encode(results) {
            defaults.set(data, forKey: key)
        }
    }
}
