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
        case 0: historyLine = "No workouts yet"
        case 1: historyLine = "1 workout logged"
        default: historyLine = "\(response.completedCount) workouts logged"
        }
        display?.displayLoad(HomeModels.Load.ViewModel(cards: cards, historyLine: historyLine))
    }
}
