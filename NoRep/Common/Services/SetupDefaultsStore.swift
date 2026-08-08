import Foundation

/// Remembers the athlete's last-used settings for every timer type
/// plus global preferences (countdown length, sound on/off).
final class SetupDefaultsStore {

    static let shared = SetupDefaultsStore()

    private struct Stored: Codable {
        var emom = EmomConfig()
        var amrap = AmrapConfig()
        var forTime = ForTimeConfig()
        var tabata = TabataConfig()
        var mixBlocks: [MixBlock] = []
        var mixName: String? = nil
        var countdown: TimeInterval = 10
        var soundEnabled = true
    }

    private let key = "norep.setup.v1"
    private let defaults: UserDefaults
    private var stored: Stored

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Stored.self, from: data) {
            stored = decoded
        } else {
            stored = Stored()
        }
    }

    var emom: EmomConfig {
        get { stored.emom }
        set { stored.emom = newValue; persist() }
    }

    var amrap: AmrapConfig {
        get { stored.amrap }
        set { stored.amrap = newValue; persist() }
    }

    var forTime: ForTimeConfig {
        get { stored.forTime }
        set { stored.forTime = newValue; persist() }
    }

    var tabata: TabataConfig {
        get { stored.tabata }
        set { stored.tabata = newValue; persist() }
    }

    var mixBlocks: [MixBlock] {
        get { stored.mixBlocks }
        set { stored.mixBlocks = newValue; persist() }
    }

    var mixName: String {
        get { stored.mixName ?? "" }
        set { stored.mixName = newValue; persist() }
    }

    var countdown: TimeInterval {
        get { stored.countdown }
        set { stored.countdown = newValue; persist() }
    }

    var soundEnabled: Bool {
        get { stored.soundEnabled }
        set { stored.soundEnabled = newValue; persist() }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(stored) {
            defaults.set(data, forKey: key)
        }
    }
}
