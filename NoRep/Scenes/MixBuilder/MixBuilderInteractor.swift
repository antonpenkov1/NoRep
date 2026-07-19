import Foundation

@MainActor
protocol MixBuilderBusinessLogic {
    func load()
    func add(block: WorkoutBlock)
    func update(id: UUID, block: WorkoutBlock)
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

    func add(block: WorkoutBlock) {
        blocks.append(MixBlock(block: block))
        persist()
    }

    func update(id: UUID, block: WorkoutBlock) {
        guard let index = blocks.firstIndex(where: { $0.id == id }) else { return }
        blocks[index].block = block
        persist()
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
        let workBlocks = blocks.map(\.block)
        guard workBlocks.contains(where: { if case .rest = $0 { return false } else { return true } }) else { return }
        let plan = WorkoutPlan(type: .mix, blocks: workBlocks, countdown: defaultsStore.countdown)
        onStart(plan)
    }

    private func persist() {
        defaultsStore.mixBlocks = blocks
        present()
    }

    private func present() {
        presenter.presentRefresh(.init(blocks: blocks, countdown: defaultsStore.countdown))
    }
}
