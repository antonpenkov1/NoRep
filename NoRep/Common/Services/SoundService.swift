import AVFoundation

/// Plays the timer cues. Uses bundled tones through AVAudioPlayer with a playback
/// session so cues are audible even with the ring switch on silent, mixing with music.
final class SoundService {

    enum Cue: String, CaseIterable {
        case tick      // 3-2-1 warning
        case go        // work segment starts
        case rest      // rest segment starts
        case finish    // workout complete
    }

    var isEnabled: Bool

    private var players: [Cue: AVAudioPlayer] = [:]

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
        configureSession()
        preload()
    }

    func play(_ cue: Cue) {
        guard isEnabled, let player = players[cue] else { return }
        player.currentTime = 0
        player.play()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers, .duckOthers])
        try? session.setActive(true)
    }

    private func preload() {
        for cue in Cue.allCases {
            guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav") else { continue }
            let player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            players[cue] = player
        }
    }
}
