import AVFoundation
import WildPairsCore

// Plays bundled SFX named after `SoundEffect.rawValue` (e.g. "cardPlay.caf"). Uses the
// `.ambient` audio session category so playback is silenced by the ringer/silent switch and
// mixes with whatever else is already playing — never interrupts other audio, no mic/capture.

@MainActor
final class SoundCoordinator {

    private let settings: AppSettings
    private var players: [SoundEffect: AVAudioPlayer] = [:]

    init(settings: AppSettings) {
        self.settings = settings
        configureAudioSession()
        preloadPlayers()
    }

    private var enabled: Bool { settings.userSettings.soundEnabled }

    func play(_ effect: SoundEffect) {
        guard enabled, let player = players[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    private func configureAudioSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func preloadPlayers() {
        for effect in SoundEffect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            players[effect] = player
        }
    }
}
