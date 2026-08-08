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
    /// Looped silence that keeps the audio session (and therefore the timer engine
    /// and Live Activity updates) alive while the app is in the background.
    private var keepAlivePlayer: AVAudioPlayer?

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

    /// Call when a workout starts: keeps audio running in background so cues fire
    /// and segment transitions keep updating even with the screen locked.
    func beginWorkoutSession() {
        try? AVAudioSession.sharedInstance().setActive(true)
        if keepAlivePlayer == nil, let url = Bundle.main.url(forResource: "silence", withExtension: "wav") {
            keepAlivePlayer = try? AVAudioPlayer(contentsOf: url)
            keepAlivePlayer?.numberOfLoops = -1
            keepAlivePlayer?.volume = 0.01
        }
        keepAlivePlayer?.play()
    }

    func endWorkoutSession() {
        keepAlivePlayer?.stop()
    }

    private func configureSession() {
        // .mixWithOthers only — no .duckOthers: ducking lowers the user's music and
        // only restores it when the session deactivates, which a timer app never does.
        // The cues are loud enough to cut through music at full volume.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
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
