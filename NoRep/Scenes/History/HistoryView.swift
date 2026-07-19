import SwiftUI

@MainActor
final class HistoryViewStore: ObservableObject {
    @Published var viewModel = HistoryModels.Load.ViewModel(rows: [])

    var interactor: HistoryBusinessLogic!

    func displayLoad(_ viewModel: HistoryModels.Load.ViewModel) {
        self.viewModel = viewModel
    }
}

enum HistorySceneFactory {
    @MainActor
    static func make() -> HistoryViewStore {
        let store = HistoryViewStore()
        let presenter = HistoryPresenter()
        presenter.display = store
        store.interactor = HistoryInteractor(presenter: presenter)
        return store
    }
}

struct HistoryView: View {
    @StateObject private var store: HistoryViewStore

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: HistorySceneFactory.make())
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if store.viewModel.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if !store.viewModel.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Clear", role: .destructive) {
                        store.interactor.clearAll()
                    }
                }
            }
        }
        .onAppear { store.interactor.load() }
    }

    private var list: some View {
        List {
            ForEach(store.viewModel.rows) { row in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(row.title)
                            .font(.system(.body, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text(row.timeText)
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.accent)
                    }
                    Text(row.detail)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                    HStack {
                        Text(row.dateText)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        if let score = row.scoreText {
                            Text(score)
                                .font(.system(.caption, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.work)
                        }
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Theme.card)
            }
            .onDelete { offsets in
                let ids = offsets.map { store.viewModel.rows[$0].id }
                store.interactor.delete(ids: ids)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary)
            Text("No workouts yet")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Finish a WOD and it lands here")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
        }
    }
}
