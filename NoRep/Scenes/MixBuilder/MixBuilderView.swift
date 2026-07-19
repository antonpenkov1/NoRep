import SwiftUI

@MainActor
final class MixBuilderViewStore: ObservableObject {
    @Published var viewModel = MixBuilderModels.Refresh.ViewModel(rows: [], totalLine: "", canStart: false)

    var interactor: MixBuilderBusinessLogic!

    func displayRefresh(_ viewModel: MixBuilderModels.Refresh.ViewModel) {
        self.viewModel = viewModel
    }
}

enum MixBuilderSceneFactory {
    @MainActor
    static func make(router appRouter: AppRouter) -> MixBuilderViewStore {
        let store = MixBuilderViewStore()
        let presenter = MixBuilderPresenter()
        presenter.display = store
        let router = MixBuilderRouter(appRouter: appRouter)
        store.interactor = MixBuilderInteractor(presenter: presenter) { plan in
            router.routeToWorkout(plan: plan)
        }
        return store
    }
}

private struct EditingBlock: Identifiable {
    var id: UUID?
    var block: WorkoutBlock

    var listID: String { id?.uuidString ?? "new" }
}

extension EditingBlock {
    static var new: EditingBlock { EditingBlock(id: nil, block: .amrap(AmrapConfig())) }
}

struct MixBuilderView: View {
    @StateObject private var store: MixBuilderViewStore
    @State private var editing: EditingBlock?

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: MixBuilderSceneFactory.make(router: router))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                if store.viewModel.rows.isEmpty {
                    emptyState
                } else {
                    blockList
                }
                footer
            }
        }
        .navigationTitle("Mix")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $editing) { item in
            BlockEditorView(initial: item.block) { block in
                if let id = item.id {
                    store.interactor.update(id: id, block: block)
                } else {
                    store.interactor.add(block: block)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .onAppear { store.interactor.load() }
    }

    private var blockList: some View {
        List {
            ForEach(store.viewModel.rows) { row in
                Button {
                    editing = EditingBlock(id: row.id, block: row.block)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: row.systemImage)
                            .foregroundStyle(row.isRest ? Theme.rest : Theme.accent)
                            .frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(row.title)
                                .font(.system(.body, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(row.summary)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "line.3.horizontal")
                            .foregroundStyle(Theme.textSecondary.opacity(0.5))
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.card)
            }
            .onDelete { store.interactor.delete(at: $0) }
            .onMove { store.interactor.move(from: $0, to: $1) }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary)
            Text("Stack timers into one WOD")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Example: AMRAP 10 → Rest 2:00 → EMOM 10×1:00")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            Text(store.viewModel.totalLine)
                .font(.system(.footnote, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            HStack(spacing: 12) {
                BigButton(
                    title: "ADD BLOCK",
                    systemImage: "plus",
                    color: Theme.accent.opacity(0.15),
                    textColor: Theme.accent,
                    borderColor: Theme.accent.opacity(0.6)
                ) {
                    editing = .new
                }
                if store.viewModel.canStart {
                    BigButton(title: "START", systemImage: "play.fill") {
                        store.interactor.start()
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.background)
    }
}

// MARK: - Block editor sheet

private struct BlockEditorView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var kind: Kind
    @State private var emom: EmomConfig
    @State private var amrap: AmrapConfig
    @State private var forTime: ForTimeConfig
    @State private var tabata: TabataConfig
    @State private var restDuration: TimeInterval

    private let onSave: (WorkoutBlock) -> Void

    enum Kind: String, CaseIterable, Identifiable {
        case emom = "EMOM"
        case amrap = "AMRAP"
        case forTime = "For Time"
        case tabata = "Tabata"
        case rest = "Rest"
        var id: String { rawValue }
    }

    init(initial: WorkoutBlock, onSave: @escaping (WorkoutBlock) -> Void) {
        self.onSave = onSave
        var kind = Kind.amrap
        var emom = EmomConfig()
        var amrap = AmrapConfig()
        var forTime = ForTimeConfig()
        var tabata = TabataConfig()
        var rest: TimeInterval = 120
        switch initial {
        case .emom(let c): kind = .emom; emom = c
        case .amrap(let c): kind = .amrap; amrap = c
        case .forTime(let c): kind = .forTime; forTime = c
        case .tabata(let c): kind = .tabata; tabata = c
        case .rest(let d): kind = .rest; rest = d
        }
        _kind = State(initialValue: kind)
        _emom = State(initialValue: emom)
        _amrap = State(initialValue: amrap)
        _forTime = State(initialValue: forTime)
        _tabata = State(initialValue: tabata)
        _restDuration = State(initialValue: rest)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Picker("Type", selection: $kind) {
                            ForEach(Kind.allCases) { k in
                                Text(k.rawValue).tag(k)
                            }
                        }
                        .pickerStyle(.segmented)

                        Card { editor }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(currentBlock)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var currentBlock: WorkoutBlock {
        switch kind {
        case .emom: return .emom(emom)
        case .amrap: return .amrap(amrap)
        case .forTime: return .forTime(forTime)
        case .tabata: return .tabata(tabata)
        case .rest: return .rest(restDuration)
        }
    }

    @ViewBuilder
    private var editor: some View {
        switch kind {
        case .emom:
            VStack(spacing: 8) {
                StepperRow(title: "Rounds", value: $emom.rounds, range: 1...99)
                Divider().overlay(Theme.cardBorder)
                DurationPicker(duration: $emom.interval, maxMinutes: 10)
            }
        case .amrap:
            DurationPicker(duration: $amrap.duration)
        case .forTime:
            VStack(spacing: 8) {
                Toggle("Time cap", isOn: $forTime.isCapEnabled)
                    .tint(Theme.accent)
                    .foregroundStyle(Theme.textPrimary)
                if forTime.isCapEnabled {
                    DurationPicker(duration: $forTime.timeCap)
                }
            }
        case .tabata:
            VStack(spacing: 8) {
                StepperRow(title: "Rounds", value: $tabata.rounds, range: 1...30)
                Divider().overlay(Theme.cardBorder)
                StepperRow(title: "Work (sec)", value: Binding(
                    get: { Int(tabata.work) },
                    set: { tabata.work = TimeInterval($0) }
                ), range: 5...120)
                Divider().overlay(Theme.cardBorder)
                StepperRow(title: "Rest (sec)", value: Binding(
                    get: { Int(tabata.rest) },
                    set: { tabata.rest = TimeInterval($0) }
                ), range: 0...120)
            }
        case .rest:
            DurationPicker(duration: $restDuration, maxMinutes: 30)
        }
    }
}
