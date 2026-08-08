import SwiftUI

@MainActor
final class BenchmarksViewStore: ObservableObject {
    @Published var viewModel = BenchmarksModels.Load.ViewModel(sections: [])

    var interactor: BenchmarksBusinessLogic!

    func displayLoad(_ viewModel: BenchmarksModels.Load.ViewModel) {
        self.viewModel = viewModel
    }
}

enum BenchmarksSceneFactory {
    @MainActor
    static func make(router appRouter: AppRouter) -> BenchmarksViewStore {
        let store = BenchmarksViewStore()
        let presenter = BenchmarksPresenter()
        presenter.display = store
        store.interactor = BenchmarksInteractor(presenter: presenter) { plan in
            appRouter.push(.workout(plan))
        }
        return store
    }
}

struct BenchmarksView: View {
    @StateObject private var store: BenchmarksViewStore
    @State private var selected: BenchmarksModels.Load.ViewModel.Row?

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: BenchmarksSceneFactory.make(router: router))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            List {
                ForEach(store.viewModel.sections) { section in
                    Section {
                        ForEach(section.rows) { row in
                            Button {
                                selected = row
                            } label: {
                                rowView(row)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Theme.card)
                        }
                    } header: {
                        Text(section.title)
                            .font(.sectionLabel)
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Benchmarks")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selected) { row in
            BenchmarkSheet(row: row) {
                selected = nil
                store.interactor.start(id: row.id)
            }
        }
        .onAppear { store.interactor.load() }
    }

    private func rowView(_ row: BenchmarksModels.Load.ViewModel.Row) -> some View {
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
                } else {
                    Text("Not yet done")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.textSecondary.opacity(0.7))
                }
            }
            Text(row.scheme)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.accent)
            Text(row.movements.replacingOccurrences(of: "\n", with: " · "))
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Start sheet

private struct BenchmarkSheet: View {
    let row: BenchmarksModels.Load.ViewModel.Row
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
                            Text(row.movements)
                                .font(.system(.title3, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.textPrimary)
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
