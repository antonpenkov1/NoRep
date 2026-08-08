import SwiftUI

@MainActor
final class MyWODsViewStore: ObservableObject {
    @Published var viewModel = MyWODsModels.Load.ViewModel(rows: [])

    var interactor: MyWODsBusinessLogic!

    func displayLoad(_ viewModel: MyWODsModels.Load.ViewModel) {
        self.viewModel = viewModel
    }
}

enum MyWODsSceneFactory {
    @MainActor
    static func make(router appRouter: AppRouter) -> MyWODsViewStore {
        let store = MyWODsViewStore()
        let presenter = MyWODsPresenter()
        presenter.display = store
        store.interactor = MyWODsInteractor(presenter: presenter) { [weak appRouter] plan in
            appRouter?.push(.workout(plan))
        }
        return store
    }
}

struct MyWODsView: View {
    @StateObject private var store: MyWODsViewStore
    @State private var selected: MyWODsModels.Load.ViewModel.Row?

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: MyWODsSceneFactory.make(router: router))
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
        .navigationTitle("My WODs")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selected) { row in
            StartWODSheet(row: row) {
                selected = nil
                store.interactor.start(id: row.id)
            }
        }
        .onAppear { store.interactor.load() }
    }

    private var list: some View {
        List {
            ForEach(store.viewModel.rows) { row in
                Button {
                    selected = row
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(row.name)
                                .font(.system(.body, design: .rounded).weight(.heavy))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if let best = row.bestText {
                                Text(best)
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.work)
                            }
                        }
                        Text(row.scheme)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.accent)
                        if let movements = row.movements {
                            Text(movements)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(Theme.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
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
            Image(systemName: "bookmark.slash")
                .font(.system(size: 44))
                .foregroundStyle(Theme.textSecondary)
            Text("No saved WODs yet")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("Save a workout from the setup screen or after finishing one")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

private struct StartWODSheet: View {
    let row: MyWODsModels.Load.ViewModel.Row
    let onStart: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 16) {
                    Card {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(row.scheme)
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.accent)
                            if let movements = row.movements {
                                Text(movements.replacingOccurrences(of: " · ", with: "\n"))
                                    .font(.system(.title3, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Theme.textPrimary)
                            }
                            if let best = row.bestText {
                                Divider().overlay(Theme.cardBorder)
                                Text(best)
                                    .font(.system(.footnote, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.work)
                            }
                        }
                    }
                    Spacer()
                    BigButton(title: "START", systemImage: "play.fill") {
                        onStart()
                    }
                }
                .padding(16)
            }
            .navigationTitle(row.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}
