import Foundation
import Testing
@testable import WildPairsCore

/// Phase 17 B3: Side-to-Side seats the human's partner immediately after them (teams A,A,B,B),
/// so the partner takes the very next turn. The table layout is role-based, so the partner still
/// renders across the top even though they now sit at seat index 1.
@Suite("Side-to-Side seating (Phase 17 B3)")
struct SideToSideSeatingTests {

    private func sideToSideState() -> (GameState, you: Player, partner: Player, oppL: Player, oppR: Player) {
        let you = Player(name: "You", role: .human, teamID: .teamA, difficulty: .easy, seatPosition: 0)
        let partner = Player(name: "Partner", role: .ai, teamID: .teamA, difficulty: .easy, seatPosition: 1)
        let oppL = Player(name: "Left Opponent", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 2)
        let oppR = Player(name: "Right Opponent", role: .ai, teamID: .teamB, difficulty: .easy, seatPosition: 3)
        let state = GameStateBuilder()
            .withCustomPlayers([you, partner, oppL, oppR])
            .withMode(.sideToSide)
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .build()
        return (state, you, partner, oppL, oppR)
    }

    @Test("The seat after the human is their partner on the same team")
    func testPartnerPlaysAfterHuman() {
        let (state, you, partner, _, _) = sideToSideState()
        // Human sits at seat 0; the next seat in turn order is the partner (seat 1, Team A).
        let nextIndex = GameRules.nextIndex(from: 0, direction: state.turnDirection,
                                            playerCount: state.players.count)
        #expect(nextIndex == 1)
        #expect(state.players[nextIndex].id == partner.id)
        #expect(state.players[nextIndex].teamID == state.players.first { $0.id == you.id }?.teamID)
    }

    @Test("Partner still renders across the top; opponents on the sides (role-based layout)")
    func testRoleBasedTableLayout() {
        let (state, you, partner, oppL, oppR) = sideToSideState()
        let vs = GameViewState(from: state, localPlayerID: you.id)
        func pos(_ id: UUID) -> Int? { vs.seats.first { $0.id == id }?.tablePosition }
        #expect(pos(you.id) == 0)       // bottom — the local player
        #expect(pos(partner.id) == 2)   // top — even though the partner sits at seat index 1
        #expect(pos(oppL.id) == 1)      // left side
        #expect(pos(oppR.id) == 3)      // right side
    }

    @Test("Canonical alternating seating is unchanged by the role-based layout (regression)")
    func testCanonicalLayoutUnchanged() {
        // Standard seating: You(0,A), Left(1,B), Partner(2,A), Right(3,B).
        let state = GameStateBuilder()
            .withPlayers()
            .withCurrentColour(.crimson)
            .withTopDiscard(CardFactory.number(5, .crimson))
            .build()
        let vs = GameViewState(from: state, localPlayerID: state.players[0].id)
        func pos(_ seat: Int) -> Int? { vs.seats.first { $0.seatPosition == seat }?.tablePosition }
        #expect(pos(0) == 0)   // you — bottom
        #expect(pos(1) == 1)   // left opponent
        #expect(pos(2) == 2)   // partner — top
        #expect(pos(3) == 3)   // right opponent
    }
}
