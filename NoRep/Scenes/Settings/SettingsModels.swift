import Foundation

enum SettingsModels {

    /// Alternate icon key = asset name; nil means the primary icon.
    struct IconOption: Equatable, Identifiable {
        var id: String { key ?? "default" }
        var key: String?
        var title: String
        var previewAsset: String
    }

    struct PackOption: Equatable, Identifiable {
        var id: String { key }
        var key: String
        var title: String
        var subtitle: String
    }

    enum Load {
        struct Response {
            var selectedIcon: String?
            var selectedPack: String
            var voiceEnabled: Bool
            var halfwayEnabled: Bool
            var healthEnabled: Bool
            var healthAvailable: Bool
        }

        struct ViewModel: Equatable {
            var icons: [IconOption]
            var selectedIconID: String
            var packs: [PackOption]
            var selectedPack: String
            var voiceEnabled: Bool
            var halfwayEnabled: Bool
            var healthEnabled: Bool
            var healthAvailable: Bool
        }
    }
}
