import Foundation

@MainActor
protocol MixBuilderPresentationLogic {
    func presentRefresh(_ response: MixBuilderModels.Refresh.Response)
}

@MainActor
final class MixBuilderPresenter: MixBuilderPresentationLogic {

    weak var display: MixBuilderViewStore?

    func presentRefresh(_ response: MixBuilderModels.Refresh.Response) {
        let rows = response.blocks.map { item -> MixBuilderModels.Refresh.ViewModel.Row in
            let isRest: Bool
            let icon: String
            switch item.block {
            case .emom: isRest = false; icon = "metronome"
            case .amrap: isRest = false; icon = "arrow.triangle.2.circlepath"
            case .forTime: isRest = false; icon = "flag.checkered"
            case .tabata: isRest = false; icon = "timer"
            case .rest: isRest = true; icon = "pause.circle"
            }
            return MixBuilderModels.Refresh.ViewModel.Row(
                id: item.id,
                title: item.block.typeTitle,
                summary: item.block.summary,
                note: item.trimmedNote,
                systemImage: icon,
                isRest: isRest,
                block: item.block
            )
        }

        let hasWork = response.blocks.contains { if case .rest = $0.block { return false } else { return true } }

        let totalLine: String
        if response.blocks.isEmpty {
            totalLine = "Add blocks to build your WOD"
        } else {
            let durations = response.blocks.map(\.block.totalDuration)
            if durations.contains(where: { $0 == nil }) {
                totalLine = "\(response.blocks.count) blocks · open-ended"
            } else {
                let total = durations.compactMap { $0 }.reduce(0, +)
                totalLine = "\(response.blocks.count) blocks · total \(TimeFormat.clock(total))"
            }
        }

        display?.displayRefresh(MixBuilderModels.Refresh.ViewModel(
            rows: rows,
            name: response.name,
            totalLine: totalLine,
            canStart: hasWork
        ))
    }
}
