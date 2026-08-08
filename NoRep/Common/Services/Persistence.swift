import Foundation
import SwiftData

/// One container for the whole app: journal + saved WODs.
/// CloudKit-backed when the entitlement and an iCloud account are present;
/// falls back to a local store, then to memory — the app never fails to boot.
@MainActor
enum Persistence {

    static let container: ModelContainer = {
        let schema = Schema([StoredWorkout.self, StoredWOD.self])

        let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .private("iCloud.com.norep.app"))
        if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
            return container
        }

        let local = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
        if let container = try? ModelContainer(for: schema, configurations: [local]) {
            return container
        }

        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try! ModelContainer(for: schema, configurations: [memory])
    }()
}
