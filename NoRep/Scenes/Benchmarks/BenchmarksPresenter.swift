import Foundation

@MainActor
protocol BenchmarksPresentationLogic {
    func presentLoad(_ response: BenchmarksModels.Load.Response)
}

@MainActor
final class BenchmarksPresenter: BenchmarksPresentationLogic {

    weak var display: BenchmarksViewStore?

    func presentLoad(_ response: BenchmarksModels.Load.Response) {
        let sections = BenchmarkWOD.Category.allCases.map { category in
            BenchmarksModels.Load.ViewModel.Section(
                id: category.rawValue,
                title: category.rawValue,
                rows: response.benchmarks
                    .filter { $0.category == category }
                    .map { wod in
                        BenchmarksModels.Load.ViewModel.Row(
                            id: wod.id,
                            name: wod.name,
                            scheme: wod.schemeText,
                            movements: wod.movements,
                            bestText: response.bestByName[wod.name].map {
                                String(localized: "Best \($0.scoreText)")
                            }
                        )
                    }
            )
        }
        display?.displayLoad(BenchmarksModels.Load.ViewModel(sections: sections))
    }
}
