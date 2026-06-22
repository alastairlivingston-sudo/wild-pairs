import SwiftUI
import UIKit
import WildPairsCore

// Wraps UIKit feedback generators (§13). Every call checks the user's haptics setting and
// suppresses haptics under Switch Control. No game-critical information is conveyed only by
// haptics — each has a visual/VoiceOver equivalent elsewhere.

@MainActor
final class HapticEngine {

    private let settings: AppSettings

    init(settings: AppSettings) { self.settings = settings }

    private var enabled: Bool {
        settings.userSettings.hapticsEnabled && !UIAccessibility.isSwitchControlRunning
    }

    func cardSelect()     { impact(.light) }
    func cardPlay()       { impact(.medium) }
    func cardDrawn()      { impact(.light) }
    func soloCall()       { impact(.heavy) }
    func colourSelected() { impact(.light) }
    func targetChosen()   { impact(.medium) }
    func illegalCard()    { notify(.error) }
    func roundWin()       { notify(.success) }
    func roundLoss()      { notify(.warning) }
    func drawPenalty()    { notify(.warning) }

    private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard enabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}
