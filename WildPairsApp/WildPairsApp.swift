import SwiftUI
import UIKit
import WildPairsCore

/// Runtime orientation split (Phase 15): iPad rotates freely, iPhone stays portrait-locked
/// (KI-032). Enforced here because iPadOS 26 ignores the Info.plist `~ipad`/`~iphone`
/// orientation variants — the plist base key is permissive and this delegate is authoritative.
final class OrientationLockDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

@main
struct WildPairsApp: App {
    @UIApplicationDelegateAdaptor(OrientationLockDelegate.self) private var orientationLock

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// Owns the top-level navigation: Home ⇄ a live game. The single PersistenceService is shared
// so autosave, resume, settings, and stats all read/write the same Documents files.

struct RootView: View {
    @StateObject private var settings: AppSettings
    @State private var game: GameViewModel?

    private let persistence = PersistenceService()

    /// Design-capture hooks: jump straight to a live table / the card gallery (skipping
    /// onboarding and home) so unattended screenshot runs don't need scripted taps.
    /// `-2p` starts a two-human pass-and-play table for handoff verification.
    private let autostart = ProcessInfo.processInfo.arguments.contains("--uitest-autostart")
    private let autostartTwoPlayer = ProcessInfo.processInfo.arguments.contains("--uitest-autostart-2p")
    private let showGallery = ProcessInfo.processInfo.arguments.contains("--uitest-cardgallery")
    /// Lands straight on a pending Draw Four challenge for the human (Phase 17 B2), so the
    /// challenge overlay can be verified deterministically.
    private let drawFourChallengeDemo = ProcessInfo.processInfo.arguments.contains("--uitest-drawfour-challenge")

    init() {
        // UI tests pass this to start from a clean slate (no saved game/settings/stats),
        // so onboarding and other first-launch behaviour can be verified deterministically.
        if ProcessInfo.processInfo.arguments.contains("--uitest-reset-state") {
            DataResetService(service: PersistenceService()).resetAll()
        }
        _settings = StateObject(wrappedValue: AppSettings())
    }

    var body: some View {
        Group {
            if showGallery {
                CardGalleryView()
            } else if let game {
                GameTableView(vm: game, settings: settings, onExit: endGame)
                    .transition(.opacity)
            } else {
                HomeView(settings: settings, onStart: startGame, onContinue: continueGame)
            }
        }
        .animation(.easeInOut, value: game == nil)
        .environment(\.reducedVisualEffects, settings.userSettings.reducedVisualEffects)
        .fullScreenCover(isPresented: showOnboardingBinding) {
            OnboardingView(onDismiss: dismissOnboarding)
        }
        .onAppear {
            guard game == nil else { return }
            if autostartTwoPlayer {
                startGame(.twoPlayerPartners(mode: .standardTeams, difficulty: .easy,
                                             cardSet: .standard,
                                             playerOneName: "Alex", playerTwoName: "Beth"))
            } else if autostart {
                startGame(.standardFourPlayer(mode: .standardTeams, difficulty: .medium,
                                              cardSet: .standard))
            } else if drawFourChallengeDemo {
                startGame(fromState: Self.drawFourChallengeDemoState())
            }
        }
    }

    /// Drives a scratch game to a pending Draw Four challenge owned by the human (seat 0), using
    /// only the public engine — seat 3 plays a fresh Draw Four and picks a colour, leaving the
    /// human to challenge or accept. Used only by `--uitest-drawfour-challenge`.
    private static func drawFourChallengeDemoState() -> GameState {
        var profile = RuleProfile.standardTeams()
        profile.drawFourChallengeable = true
        let df = CardFactory.drawFour()
        let base = GameStateBuilder()
            .withPlayers()
            .withRuleProfile(profile)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(7, .crimson))
            .withHand(forPlayer: 0, cards: [CardFactory.number(5, .jade),
                                            CardFactory.number(3, .amber), CardFactory.skip(.cobalt)])
            .withHand(forPlayer: 3, cards: [df, CardFactory.number(2, .amber)])
            .withCurrentPlayer(3)
            .withDrawPile((0..<30).map { CardFactory.number($0 % 10, .amber) })
            .build()
        let p3 = base.players[3].id
        let (afterPlay, _) = GameEngine.reduce(state: base, action: .playCard(df, playerID: p3))
        let (afterColour, _) = GameEngine.reduce(state: afterPlay, action: .selectColour(.jade, playerID: p3))
        return afterColour
    }

    private var showOnboardingBinding: Binding<Bool> {
        Binding(
            get: {
                !settings.userSettings.hasSeenOnboarding && !autostart
                    && !autostartTwoPlayer && !showGallery && !drawFourChallengeDemo
            },
            set: { _ in }
        )
    }

    private func dismissOnboarding() {
        settings.userSettings.hasSeenOnboarding = true
    }

    private func startGame(_ config: GameConfig) {
        let presenter = GamePresenter(config: config, persistence: persistence)
        game = makeViewModel(presenter)
    }

    private func startGame(fromState state: GameState) {
        let humanID = state.players.first { $0.role == .human }?.id ?? state.players.first?.id
        guard let humanID else { return }
        let presenter = GamePresenter(state: state, localPlayerID: humanID, persistence: persistence)
        game = makeViewModel(presenter)
    }

    private func continueGame() {
        guard let snapshot = try? persistence.loadGame() else { return }
        let humanID = snapshot.state.players.first { $0.role == .human }?.id
            ?? snapshot.state.players.first?.id
        guard let humanID else { return }
        let presenter = GamePresenter(state: snapshot.state, localPlayerID: humanID, persistence: persistence)
        game = makeViewModel(presenter)
    }

    private func makeViewModel(_ presenter: GamePresenter) -> GameViewModel {
        GameViewModel(presenter: presenter, settings: settings) { result in
            settings.recordRoundResult(result)
        }
    }

    private func endGame() {
        // Clear the saved game so Home does not offer to continue a finished/abandoned game.
        DataResetService(service: persistence).resetGame()
        game = nil
    }
}
