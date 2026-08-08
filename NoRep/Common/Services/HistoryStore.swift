import Foundation
import SwiftData

/// Journal persistence on SwiftData. Keeps the same value-type API the scenes
/// have always used; migrates v1.0/v1.1 UserDefaults JSON on first launch.
@MainActor
final class HistoryStore {

    static let shared = HistoryStore()

    private static let legacyKey = "norep.history.v1"

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false, defaults: UserDefaults = .standard) {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        do {
            container = try ModelContainer(for: StoredWorkout.self, configurations: configuration)
        } catch {
            // Never brick the app over a store issue — fall back to memory.
            container = try! ModelContainer(
                for: StoredWorkout.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        }
        migrateLegacyDefaults(defaults)
    }

    func load() -> [WorkoutResult] {
        let descriptor = FetchDescriptor<StoredWorkout>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        let stored = (try? context.fetch(descriptor)) ?? []
        return stored.map(\.result)
    }

    func add(_ result: WorkoutResult) {
        context.insert(StoredWorkout(from: result))
        save()
    }

    func update(_ result: WorkoutResult) {
        guard let stored = fetch(id: result.id) else { return }
        stored.apply(result)
        save()
    }

    func delete(ids: Set<UUID>) {
        for id in ids {
            if let stored = fetch(id: id) {
                context.delete(stored)
            }
        }
        save()
    }

    func clear() {
        try? context.delete(model: StoredWorkout.self)
        save()
    }

    /// Earlier results sharing the same (case-insensitive) name — the benchmark series.
    func results(named title: String, excluding id: UUID? = nil) -> [WorkoutResult] {
        let key = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !key.isEmpty else { return [] }
        return load().filter {
            $0.id != id && $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == key
        }
    }

    /// Best result for a named workout, using the same rules as PR detection.
    func best(named title: String) -> WorkoutResult? {
        let series = results(named: title)
        guard !series.isEmpty else { return nil }
        return series.min { $0.beats($1) }
    }

    // MARK: - Internals

    private func fetch(id: UUID) -> StoredWorkout? {
        var descriptor = FetchDescriptor<StoredWorkout>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func save() {
        try? context.save()
    }

    private func migrateLegacyDefaults(_ defaults: UserDefaults) {
        guard let data = defaults.data(forKey: Self.legacyKey),
              let legacy = try? JSONDecoder().decode([WorkoutResult].self, from: data) else { return }
        for result in legacy {
            context.insert(StoredWorkout(from: result))
        }
        save()
        defaults.removeObject(forKey: Self.legacyKey)
    }
}
