import Foundation

@MainActor
protocol MyWODsPresentationLogic {
    func presentLoad(_ response: MyWODsModels.Load.Response)
}

@MainActor
final class MyWODsPresenter: MyWODsPresentationLogic {

    weak var display: MyWODsViewStore?

    func presentLoad(_ response: MyWODsModels.Load.Response) {
        let rows = response.wods.map { wod in
            let movements = wod.plan.blocks.compactMap(\.trimmedNote).joined(separator: " · ")
            return MyWODsModels.Load.ViewModel.Row(
                id: wod.id,
                name: wod.name,
                scheme: wod.plan.detail,
                movements: movements.isEmpty ? nil : movements,
                bestText: response.bestByName[wod.name].map {
                    String(localized: "Best \($0.scoreText)")
                }
            )
        }
        display?.displayLoad(MyWODsModels.Load.ViewModel(rows: rows))
    }
}
