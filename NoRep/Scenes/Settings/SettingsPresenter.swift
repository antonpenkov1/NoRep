import Foundation

@MainActor
protocol SettingsPresentationLogic {
    func presentLoad(_ response: SettingsModels.Load.Response)
}

@MainActor
final class SettingsPresenter: SettingsPresentationLogic {

    weak var display: SettingsViewStore?

    private static let icons: [SettingsModels.IconOption] = [
        .init(key: nil, title: "Classic", previewAsset: "IconPreview-Default"),
        .init(key: "AppIcon-Blaze", title: "Blaze", previewAsset: "IconPreview-Blaze"),
        .init(key: "AppIcon-Chalk", title: "Chalk", previewAsset: "IconPreview-Chalk"),
        .init(key: "AppIcon-Blackout", title: "Blackout", previewAsset: "IconPreview-Blackout"),
        .init(key: "AppIcon-Gold", title: "Gold", previewAsset: "IconPreview-Gold")
    ]

    private static let packs: [SettingsModels.PackOption] = [
        .init(key: "classic", title: "Classic beeps", subtitle: "Sharp digital tones — cuts through anything"),
        .init(key: "horn", title: "Air horn", subtitle: "Like the box timer on comp day"),
        .init(key: "soft", title: "Soft chimes", subtitle: "Gentle plucks for early mornings")
    ]

    func presentLoad(_ response: SettingsModels.Load.Response) {
        display?.displayLoad(SettingsModels.Load.ViewModel(
            icons: Self.icons,
            selectedIconID: response.selectedIcon ?? "default",
            packs: Self.packs,
            selectedPack: response.selectedPack
        ))
    }
}
