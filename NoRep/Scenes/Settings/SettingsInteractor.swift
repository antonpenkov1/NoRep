import UIKit

@MainActor
protocol SettingsBusinessLogic {
    func load()
    func selectIcon(key: String?)
    func selectPack(key: String)
    func setVoice(enabled: Bool)
    func setHalfway(enabled: Bool)
    func setHealth(enabled: Bool)
}

@MainActor
final class SettingsInteractor: SettingsBusinessLogic {

    private let presenter: SettingsPresentationLogic
    private let defaultsStore: SetupDefaultsStore
    /// Kept alive so the preview cue finishes playing.
    private var previewSound: SoundService?

    init(presenter: SettingsPresentationLogic, defaultsStore: SetupDefaultsStore = .shared) {
        self.presenter = presenter
        self.defaultsStore = defaultsStore
    }

    func load() {
        present()
    }

    func selectIcon(key: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(key) { [weak self] _ in
            Task { @MainActor in
                self?.present()
            }
        }
        // Optimistic refresh so the checkmark moves immediately.
        present(optimisticIcon: key)
    }

    func selectPack(key: String) {
        defaultsStore.soundPack = key
        let preview = SoundService(isEnabled: true, pack: key)
        preview.play(.go)
        previewSound = preview
        present()
    }

    func setVoice(enabled: Bool) {
        defaultsStore.voiceEnabled = enabled
        if enabled {
            VoiceService(isEnabled: true).speak(String(localized: "Go!", comment: "Voice callout"))
        }
        present()
    }

    func setHalfway(enabled: Bool) {
        defaultsStore.halfwayEnabled = enabled
        present()
    }

    func setHealth(enabled: Bool) {
        guard enabled else {
            defaultsStore.healthEnabled = false
            present()
            return
        }
        Task { [weak self] in
            let granted = await HealthKitService.shared.requestAuthorization()
            await MainActor.run {
                self?.defaultsStore.healthEnabled = granted
                self?.present()
            }
        }
    }

    private func present(optimisticIcon: String?? = nil) {
        presenter.presentLoad(.init(
            selectedIcon: optimisticIcon ?? UIApplication.shared.alternateIconName,
            selectedPack: defaultsStore.soundPack,
            voiceEnabled: defaultsStore.voiceEnabled,
            halfwayEnabled: defaultsStore.halfwayEnabled,
            healthEnabled: defaultsStore.healthEnabled,
            healthAvailable: HealthKitService.shared.isAvailable
        ))
    }
}
