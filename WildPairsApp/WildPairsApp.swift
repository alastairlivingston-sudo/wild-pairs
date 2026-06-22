import SwiftUI
import WildPairsCore

@main
struct WildPairsApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// Owns the top-level navigation: Home ⇄ a live game. The single PersistenceService is shared
// so autosave, resume, settings, and stats all read/write the same Documents files.

struct RootView: View {
    @StateObject private var settings = AppSettings()
    @State private var game: GameViewModel?

    private let persistence = PersistenceService()

    var body: some View {
        Group {
            if let game {
                GameTableView(vm: game, settings: settings, onExit: endGame)
                    .transition(.opacity)
            } else {
                HomeView(settings: settings, onStart: startGame, onContinue: continueGame)
            }
        }
        .animation(.easeInOut, value: game == nil)
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
        GameViewModel(presenter: presenter, settings: settings) { won, difficulty, turns in
            settings.recordRoundResult(localTeamWon: won, difficulty: difficulty, turns: turns)
        }
    }

    private func endGame() {
        // Clear the saved game so Home does not offer to continue a finished/abandoned game.
        DataResetService(service: persistence).resetGame()
        game = nil
    }
}
