import AVFoundation

/// Speaks workout callouts via the system synthesizer. Mixes over the cue
/// sounds and the athlete's music through the shared audio session.
final class VoiceService {

    var isEnabled: Bool

    private let synthesizer = AVSpeechSynthesizer()

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func speak(_ text: String) {
        guard isEnabled else { return }
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.52
        utterance.volume = 1.0
        if let code = Locale.current.language.languageCode?.identifier {
            utterance.voice = AVSpeechSynthesisVoice(language: code)
        }
        synthesizer.speak(utterance)
    }
}
