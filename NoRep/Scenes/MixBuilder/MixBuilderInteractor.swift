import Foundation

@MainActor
protocol MixBuilderBusinessLogic {
    func load()
    func add(block: WorkoutBlock, note: String?)
    func update(id: UUID, block: WorkoutBlock, note: String?)
    func setName(_ name: String)
    func delete(at offsets: IndexSet)
    func move(from source: IndexSet, to destination: Int)
    func start()
}

@MainActor
final class MixBuilderInteractor: MixBuilderBusinessLogic {

    private let presenter: MixBuilderPresentationLogic
    private let defaultsStore: SetupDefaultsStore
    private let onStart: (WorkoutPlan) -> Void
    private var blocks: [MixBlock]

    init(
        presenter: MixBuilderPresentationLogic,
        defaultsStore: SetupDefaultsStore = .shared,
        onStart: @escaping (WorkoutPlan) -> Void
    ) {
        self.presenter = presenter
        self.defaultsStore = defaultsStore
        self.onStart = onStart
        self.blocks = defaultsStore.mixBlocks
    }

    func load() {
        present()
    }

    func add(block: WorkoutBlock, note: String?) {
        blocks.append(MixBlock(block: block, note: note))
        persist()
    }

    func update(id: UUID, block: WorkoutBlock, note: String?) {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        blocks[index].block = block
        blocks[index].note = note
        persist()
    }

    func setName(_ name: String) {
        defaultsStore.mixName = name
        present()
    }

    func delete(at offsets: IndexSet) {
        blocks.remove(atOffsets: offsets)
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        blocks.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func start() {
        guard blocks.contains(where: { if case .rest = $0.block { return false } else { return true } }) else { return }
        let name = defaultsStore.mixName.trimmingCharacters(in: .whitespacesAndNewlines)
        let plan = WorkoutPlan(
            type: .mix,
            blocks: blocks,
            countdown: defaultsStore.countdown,
            customName: name.isEmpty ? nil : name
        )
        onStart(plan)
    }

    private func persist() {
        defaultsStore.mixBlocks = blocks
        present()
    }

    private func present() {
        presenter.presentRefresh(.init(blocks: blocks, name: defaultsStore.mixName, countdown: defaultsStore.countdown))
    }
}
