import SwiftUI

@MainActor
final class HomeViewStore: ObservableObject {
    @Published var viewModel = HomeModels.Load.ViewModel(cards: [], historyLine: "", repeatLast: nil)

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
        store.interactor = HomeInteractor(presenter: presenter) { [weak appRouter] plan in
            appRouter?.push(.workout(plan))
        }
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
                    quickStartSection
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
                    benchmarksButton
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NoRep")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                Text("3… 2… 1… Go!")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            Spacer()
            Button {
                store.router.routeToSettings()
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(Theme.card, in: Circle())
                    .overlay(Circle().strokeBorder(Theme.cardBorder))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var quickStartSection: some View {
        VStack(spacing: 8) {
            if let repeatLast = store.viewModel.repeatLast {
                Button {
                    store.interactor.repeatLast()
                } label: {
                    Card {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Theme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("REPEAT LAST")
                                    .font(.sectionLabel)
                                    .foregroundStyle(Theme.textSecondary)
                                Text("\(repeatLast.title) · \(repeatLast.detail)")
                                    .font(.system(.footnote, design: .rounded).weight(.bold))
                                    .foregroundStyle(Theme.textPrimary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Image(systemName: "play.fill")
                                .foregroundStyle(Theme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 8) {
                ForEach(HomeModels.Preset.allCases, id: \.self) { preset in
                    Button {
                        store.interactor.startPreset(preset)
                    } label: {
                        Text(preset.title)
                            .font(.system(.caption, design: .rounded).weight(.black))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Theme.card, in: Capsule())
                            .overlay(Capsule().strokeBorder(Theme.cardBorder))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 4)
    }

    private var benchmarksButton: some View {
        Button {
            store.router.routeToBenchmarks()
        } label: {
            Card {
                HStack(spacing: 14) {
                    Image(systemName: "trophy.fill")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Theme.prepare)
                        .frame(width: 44, height: 44)
                        .background(Theme.prepare.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Benchmarks")
                            .font(.system(.title3, design: .rounded).weight(.heavy))
                            .foregroundStyle(Theme.textPrimary)
                        Text("The Girls & Hero WODs — chase your PRs")
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
        .buttonStyle(.plain)
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
