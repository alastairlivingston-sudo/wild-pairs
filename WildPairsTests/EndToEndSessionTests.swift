import Testing
import Foundation
@testable import WildPairsCore

// MARK: - Headless end-to-end session harness
//
// Drives a complete game through GamePresenter exactly as the SwiftUI app would: AI turns
// auto-advance, and on the local player's turn/choices a deterministic "human" policy acts
// (play first playable card, else draw; resolve colour/target prompts; call Solo!). This is
// the closest thing to an end-to-end test achievable without a Mac — it exercises the full
// loop (engine + AI + presentation + persistence) but not the SwiftUI rendering layer.

struct SessionOutcome {
    var winner: TeamID?
    var phase: GamePhase
    var localPlays: Int
    var localDraws: Int
    var soloCalls: Int
    var steps: Int
    var stuck: Bool
}

enum HeadlessSession {

    /// Runs one round to completion. `persistence`, if provided, autosaves each turn.
    static func runRound(
        presenter: GamePresenter,
        stepCap: Int = 1000
    ) -> SessionOutcome {
        var outcome = SessionOutcome(
            winner: nil, phase: presenter.state.phase,
            localPlays: 0, localDraws: 0, soloCalls: 0, steps: 0, stuck: false
        )

        while presenter.state.phase == .playing {
            outcome.steps += 1
            if outcome.steps > stepCap {
                outcome.stuck = true
                break
            }

            // 1. Let AI act if it's an AI turn or an AI-owned pending decision.
            if presenter.advanceAutomatic() != nil { continue }

            // 2. It's the local player's move or a local pending decision.
            let vs = presenter.viewState

            if vs.awaitingLocalColourChoice {
                presenter.chooseColour(humanColourChoice(vs))
                continue
            }
            if let target = vs.localTargetChoices.first {
                presenter.chooseTarget(target)
                continue
            }

            // Call Solo! if we owe it (belated is fine — nobody catches in this harness).
            if vs.soloButtonVisible {
                presenter.callSolo()
                outcome.soloCalls += 1
            }

            if vs.isLocalPlayerTurn {
                if let playable = vs.localHand.first(where: { $0.isPlayable }) {
                    presenter.play(playable.card)
                    outcome.localPlays += 1
                } else {
                    presenter.draw()
                    outcome.localDraws += 1
                }
                continue
            }

            // Defensive: no progress path while still playing.
            outcome.stuck = true
            break
        }

        outcome.phase = presenter.state.phase
        outcome.winner = presenter.state.winState?.winningTeam
        return outcome
    }

    private static func humanColourChoice(_ vs: GameViewState) -> CardColour {
        // Prefer the colour the local player holds most of.
        let counts = Dictionary(grouping: vs.localHand.compactMap { $0.card.colour }, by: { $0 })
            .mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? .crimson
    }

    static func config(
        mode: GameMode,
        cardSet: CardSet,
        difficulty: Difficulty,
        seed: UInt64
    ) -> GameConfig {
        var profile: RuleProfile
        switch mode {
        case .standardTeams: profile = .standardTeams()
        case .allWild: profile = .allWild()
        case .sideToSide: profile = .sideToSide()
        }
        profile.cardSet = cardSet
        return GameConfig(
            mode: mode,
            players: [
                PlayerConfig(name: "You", role: .human, teamID: .teamA, difficulty: difficulty, seatPosition: 0),
                PlayerConfig(name: "Left", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 1),
                PlayerConfig(name: "Partner", role: .ai, teamID: .teamA, difficulty: difficulty, seatPosition: 2),
                PlayerConfig(name: "Right", role: .ai, teamID: .teamB, difficulty: difficulty, seatPosition: 3)
            ],
            ruleProfile: profile,
            seed: seed
        )
    }
}

@Suite("End-to-end headless sessions")
struct EndToEndSessionTests {

    @Test("A full Standard Teams round completes with a winner and no stuck state")
    func testStandardRoundCompletes() {
        let presenter = GamePresenter(config: HeadlessSession.config(
            mode: .standardTeams, cardSet: .standard, difficulty: .easy, seed: 12345))
        let outcome = HeadlessSession.runRound(presenter: presenter)
        #expect(!outcome.stuck)
        #expect(outcome.phase == .roundEnded)
        #expect(outcome.winner != nil)
    }

    @Test("A full Advanced (all card types) round completes")
    func testAdvancedRoundCompletes() {
        let presenter = GamePresenter(config: HeadlessSession.config(
            mode: .standardTeams, cardSet: .advanced, difficulty: .hard, seed: 24680))
        let outcome = HeadlessSession.runRound(presenter: presenter)
        #expect(!outcome.stuck)
        #expect(outcome.phase == .roundEnded)
        #expect(outcome.winner != nil)
    }

    @Test("An All-Wild round completes")
    func testAllWildRoundCompletes() {
        let presenter = GamePresenter(config: HeadlessSession.config(
            mode: .allWild, cardSet: .standard, difficulty: .medium, seed: 555))
        let outcome = HeadlessSession.runRound(presenter: presenter)
        #expect(!outcome.stuck)
        #expect(outcome.phase == .roundEnded)
        #expect(outcome.winner != nil)
    }

    @Test("Sessions are deterministic: same seed yields the same winner and step count")
    func testSessionDeterminism() {
        let p1 = GamePresenter(config: HeadlessSession.config(
            mode: .standardTeams, cardSet: .advanced, difficulty: .expert, seed: 4242))
        let p2 = GamePresenter(config: HeadlessSession.config(
            mode: .standardTeams, cardSet: .advanced, difficulty: .expert, seed: 4242))
        let o1 = HeadlessSession.runRound(presenter: p1)
        let o2 = HeadlessSession.runRound(presenter: p2)
        #expect(o1.winner == o2.winner)
        #expect(o1.steps == o2.steps)
    }

    @Test("Save mid-game, resume from the snapshot, and finish — state survives the round-trip")
    func testSaveResumeMidGameContinues() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("WP-e2e-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let service = PersistenceService(directory: dir)

        // Play part of a game with autosave on.
        let config = HeadlessSession.config(mode: .standardTeams, cardSet: .standard, difficulty: .easy, seed: 808)
        let presenter = GamePresenter(config: config, persistence: service)

        // Advance ~30 steps, then stop mid-game (don't run to completion).
        var steps = 0
        while presenter.state.phase == .playing && steps < 30 {
            steps += 1
            if presenter.advanceAutomatic() != nil { continue }
            let vs = presenter.viewState
            if vs.awaitingLocalColourChoice { presenter.chooseColour(.crimson); continue }
            if let t = vs.localTargetChoices.first { presenter.chooseTarget(t); continue }
            if vs.soloButtonVisible { presenter.callSolo() }
            if vs.isLocalPlayerTurn {
                if let p = vs.localHand.first(where: { $0.isPlayable }) { presenter.play(p.card) }
                else { presenter.draw() }
            }
        }

        // Snapshot was autosaved each turn; load it into a fresh presenter.
        let snapshot = try service.loadGame()
        #expect(snapshot.state == presenter.state)

        let resumed = GamePresenter(state: snapshot.state, localPlayerID: presenter.localPlayerID)
        // Continue to completion from the resumed state.
        if resumed.state.phase == .playing {
            let outcome = HeadlessSession.runRound(presenter: resumed)
            #expect(!outcome.stuck)
            #expect(outcome.phase == .roundEnded)
            #expect(outcome.winner != nil)
        }
    }

    @Test("The local human actually takes turns (plays or draws) during a session")
    func testLocalPlayerParticipates() {
        let presenter = GamePresenter(config: HeadlessSession.config(
            mode: .standardTeams, cardSet: .standard, difficulty: .easy, seed: 31337))
        let outcome = HeadlessSession.runRound(presenter: presenter)
        #expect(outcome.localPlays + outcome.localDraws > 0)
    }
}
