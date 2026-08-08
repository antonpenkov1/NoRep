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

    func update(_ result: WorkoutResult) {
        var all = load()
        guard let index = all.firstIndex(where: { $0.id == result.id }) else { return }
        all[index] = result
        save(all)
    }

    /// Earlier results sharing the same (case-insensitive) name — the benchmark series.
    func results(named title: String, excluding id: UUID? = nil) -> [WorkoutResult] {
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return [] }
        return load().filter {
            $0.id != id && $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key
        }
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
