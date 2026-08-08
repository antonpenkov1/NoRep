import Foundation

@MainActor
protocol HomePresentationLogic {
    func presentLoad(_ response: HomeModels.Load.Response)
}

@MainActor
final class HomePresenter: HomePresentationLogic {

    weak var display: HomeViewStore?

    func presentLoad(_ response: HomeModels.Load.Response) {
        let cards = response.types.map { type in
            HomeModels.Load.ViewModel.TimerCard(
                id: type.id,
                type: type,
                title: type.title,
                subtitle: type.subtitle,
                systemImage: type.systemImage
            )
        }
        let historyLine: String
        switch response.completedCount {
        case 0: historyLine = String(localized: "No workouts yet")
        case 1: historyLine = String(localized: "1 workout logged")
        default: historyLine = String(localized: "\(response.completedCount) workouts logged")
        }

        let repeatLast = response.lastPlan.map { plan in
            HomeModels.Load.ViewModel.QuickStart(
                title: plan.title,
                detail: plan.detail
            )
        }

        display?.displayLoad(HomeModels.Load.ViewModel(
            cards: cards,
            historyLine: historyLine,
            repeatLast: repeatLast
        ))
    }
}
