import SwiftUI

@MainActor
final class HomeViewStore: ObservableObject {
    @Published var viewModel = HomeModels.Load.ViewModel(cards: [], historyLine: "")

    var interactor: HomeBusinessLogic!
    var router: HomeRoutingLogic!

    func displayLoad(_ viewModel: HomeModels.Load.ViewModel) {
        self.viewModel = viewModel
    }
}

enum HomeSceneFactory {
    @MainActor
    static func make(router appRouter: AppRouter) -> HomeViewStore {
        let store = HomeViewStore()
        let presenter = HomePresenter()
        presenter.display = store
        store.interactor = HomeInteractor(presenter: presenter)
        store.router = HomeRouter(appRouter: appRouter)
        return store
    }
}

struct HomeView: View {
    @StateObject private var store: HomeViewStore

    init(router: AppRouter) {
        _store = StateObject(wrappedValue: HomeSceneFactory.make(router: router))
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 12) {
                    header
                    ForEach(store.viewModel.cards) { card in
                        Button {
                            if card.type == .mix {
                                store.router.routeToMixBuilder()
                            } else {
                                store.router.routeToSetup(type: card.type)
                            }
                        } label: {
                            TimerCardView(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                    historyButton
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .principal) { EmptyView() } }
        .onAppear { store.interactor.load(.init()) }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NoRep")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
            Text("3… 2… 1… Go!")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var historyButton: some View {
        Button {
            store.router.routeToHistory()
        } label: {
            Card {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                    Text(store.viewModel.historyLine)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(Theme.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Theme.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }
}

private struct TimerCardView: View {
    let card: HomeModels.Load.ViewModel.TimerCard

    var body: some View {
        Card {
            HStack(spacing: 14) {
                Image(systemName: card.systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 44, height: 44)
                    .background(Theme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text(card.title)
                        .font(.system(.title3, design: .rounded).weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(card.subtitle)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
