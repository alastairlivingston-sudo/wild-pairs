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
    private let autostart = ProcessInfo.processInfo.arguments.contains("--uitest-autostart")
    private let showGallery = ProcessInfo.processInfo.arguments.contains("--uitest-cardgallery")

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
            guard autostart, game == nil else { return }
            startGame(.standardFourPlayer(mode: .standardTeams, difficulty: .medium,
                                          cardSet: .standard))
        }
    }

    private var showOnboardingBinding: Binding<Bool> {
        Binding(
            get: { !settings.userSettings.hasSeenOnboarding && !autostart && !showGallery },
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
