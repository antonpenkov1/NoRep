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
        .init(key: "classic", title: String(localized: "Classic beeps"), subtitle: String(localized: "Sharp digital tones — cuts through anything")),
        .init(key: "horn", title: String(localized: "Air horn"), subtitle: String(localized: "Like the box timer on comp day")),
        .init(key: "soft", title: String(localized: "Soft chimes"), subtitle: String(localized: "Gentle plucks for early mornings")),
        .init(key: "whistle", title: String(localized: "Coach whistle"), subtitle: String(localized: "Ref's peep with a full trill on GO")),
        .init(key: "bell", title: String(localized: "Gym bell"), subtitle: String(localized: "Ring it like a fresh PR")),
        .init(key: "arcade", title: String(localized: "Arcade"), subtitle: String(localized: "8-bit bleeps — every round is a level up"))
    ]

    func presentLoad(_ response: SettingsModels.Load.Response) {
        display?.displayLoad(SettingsModels.Load.ViewModel(
            icons: Self.icons,
            selectedIconID: response.selectedIcon ?? "default",
            packs: Self.packs,
            selectedPack: response.selectedPack,
            voiceEnabled: response.voiceEnabled,
            halfwayEnabled: response.halfwayEnabled,
            healthEnabled: response.healthEnabled,
            healthAvailable: response.healthAvailable
        ))
    }
}
