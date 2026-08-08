import Foundation
import SwiftData

/// A saved workout template in the athlete's own library ("My WODs").
/// The plan is stored as encoded JSON — CloudKit-friendly and future-proof
/// against plan shape changes (undecodable rows are simply hidden).
@Model
final class StoredWOD {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var planData: Data = Data()

    init(name: String, plan: WorkoutPlan) {
        id = UUID()
        self.name = name
        createdAt = Date()
        planData = (try? JSONEncoder().encode(plan)) ?? Data()
    }

    var plan: WorkoutPlan? {
        try? JSONDecoder().decode(WorkoutPlan.self, from: planData)
    }
}

/// Value type handed to scenes.
struct SavedWOD: Identifiable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date
    var plan: WorkoutPlan
}

@MainActor
final class WODStore {

    static let shared = WODStore()

    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(container: ModelContainer? = nil) {
        self.container = container ?? Persistence.container
    }

    func load() -> [SavedWOD] {
        let descriptor = FetchDescriptor<StoredWOD>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        let stored = (try? context.fetch(descriptor)) ?? []
        return stored.compactMap { item in
            guard let plan = item.plan else { return nil }
            return SavedWOD(id: item.id, name: item.name, createdAt: item.createdAt, plan: plan)
        }
    }

    func add(name: String, plan: WorkoutPlan) {
        var named = plan
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        named.customName = trimmed.isEmpty ? nil : trimmed
        context.insert(StoredWOD(name: trimmed.isEmpty ? plan.title : trimmed, plan: named))
        try? context.save()
    }

    func delete(ids: Set<UUID>) {
        let descriptor = FetchDescriptor<StoredWOD>()
        for item in (try? context.fetch(descriptor)) ?? [] where ids.contains(item.id) {
            context.delete(item)
        }
        try? context.save()
    }
}
