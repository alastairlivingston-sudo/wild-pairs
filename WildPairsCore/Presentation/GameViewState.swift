import Foundation

// MARK: - Presentation view-state
//
// A platform-agnostic projection of `GameState` into exactly what a UI renders.
// It contains no SwiftUI, UIKit, or Combine — so it compiles and is unit-testable on
// any Swift toolchain (Mac, Linux, Windows). The SwiftUI layer is a thin shell that
// renders these values; it never derives display data itself.

// MARK: CardViewModel

public struct CardViewModel: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let card: Card
    /// True when the local player may legally play this card right now.
    public let isPlayable: Bool

    public init(card: Card, isPlayable: Bool) {
        self.id = card.id
        self.card = card
        self.isPlayable = isPlayable
    }
}

// MARK: PlayerSeatViewState

public struct PlayerSeatViewState: Equatable, Sendable, Identifiable {
    public let id: UUID
    public let name: String
    public let teamID: TeamID
    public let seatPosition: Int
    public let handCount: Int
    public let isCurrentPlayer: Bool
    public let hasFinishedRound: Bool
    public let isLocalPlayer: Bool
    /// Holds exactly one card and has not satisfied the Solo! requirement — catchable.
    public let needsSoloCall: Bool
    /// The seat's hand contents, populated only for the local player's partner — partner
    /// hands are open by design (see `docs/game-rules.md` Team Communication Rules).
    /// Nil for the local player's own seat (use `GameViewState.localHand` instead) and for
    /// opponent seats, which remain count-only.
    public let visiblePartnerHand: [Card]?

    public init(
        id: UUID, name: String, teamID: TeamID, seatPosition: Int,
        handCount: Int, isCurrentPlayer: Bool, hasFinishedRound: Bool,
        isLocalPlayer: Bool, needsSoloCall: Bool, visiblePartnerHand: [Card]? = nil
    ) {
        self.id = id; self.name = name; self.teamID = teamID
        self.seatPosition = seatPosition; self.handCount = handCount
        self.isCurrentPlayer = isCurrentPlayer; self.hasFinishedRound = hasFinishedRound
        self.isLocalPlayer = isLocalPlayer; self.needsSoloCall = needsSoloCall
        self.visiblePartnerHand = visiblePartnerHand
    }
}

// MARK: ScoreRow

public struct ScoreRow: Equatable, Sendable, Identifiable {
    public var id: TeamID { teamID }
    public let teamID: TeamID
    public let displayName: String
    public let score: Int

    public init(teamID: TeamID, displayName: String, score: Int) {
        self.teamID = teamID; self.displayName = displayName; self.score = score
    }
}

// MARK: PromptKind

/// The single guidance line shown to the player. The associated strings are already
/// localised-English copy ready to render or feed to VoiceOver.
public enum PromptKind: Equatable, Sendable {
    case yourTurn(hint: String)
    case waitingFor(playerName: String)
    case chooseColour
    case chooseTarget
    case mustDraw
    case roundOver(winningTeamName: String)
    case gameOver(winningTeamName: String)
    case paused
}

// MARK: GameViewState

public struct GameViewState: Equatable, Sendable {

    public let seats: [PlayerSeatViewState]
    /// The local player's hand, sorted for display, each tagged with playability.
    public let localHand: [CardViewModel]
    public let topDiscard: Card?
    public let currentColour: CardColour
    public let turnDirection: TurnDirection
    public let drawPileCount: Int
    public let scoreboard: [ScoreRow]
    public let prompt: PromptKind
    public let phase: GamePhase
    public let roundNumber: Int

    public let isLocalPlayerTurn: Bool
    /// The local player must press "Solo!" (holds one card, not yet called).
    public let soloButtonVisible: Bool
    /// True when the engine is waiting for the local player to pick a colour.
    public let awaitingLocalColourChoice: Bool
    /// Non-empty when the engine is waiting for the local player to pick a target.
    public let localTargetChoices: [UUID]
    /// A seat the local player can legally call out for a missed Solo!, if any.
    public let catchableSoloPlayerID: UUID?

    // MARK: Derivation

    public init(from state: GameState, localPlayerID: UUID) {
        let local = state.players.first { $0.id == localPlayerID }
        let localTeam = local?.teamID
        let partnerID = state.teamState.partnerID(for: localPlayerID)

        self.seats = state.players
            .sorted { $0.seatPosition < $1.seatPosition }
            .map { p in
                PlayerSeatViewState(
                    id: p.id, name: p.name, teamID: p.teamID, seatPosition: p.seatPosition,
                    handCount: p.hand.count,
                    isCurrentPlayer: state.currentPlayer?.id == p.id,
                    hasFinishedRound: p.hasFinishedRound,
                    isLocalPlayer: p.id == localPlayerID,
                    needsSoloCall: p.hand.count == 1 && !p.hasCalledSolo,
                    visiblePartnerHand: p.id == partnerID ? p.hand : nil
                )
            }

        let isLocalTurn = state.currentPlayer?.id == localPlayerID
            && state.phase == .playing
            && state.pendingDecision == nil

        let legalIDs: Set<UUID> = {
            guard isLocalTurn else { return [] }
            return Set(GameViewState.localLegalPlays(state: state, playerID: localPlayerID).map(\.id))
        }()

        self.localHand = (local?.hand ?? [])
            .sorted(by: GameViewState.cardSortsBefore)
            .map { CardViewModel(card: $0, isPlayable: legalIDs.contains($0.id)) }

        self.topDiscard = state.deck.topDiscard
        self.currentColour = state.currentColour
        self.turnDirection = state.turnDirection
        self.drawPileCount = state.deck.drawPile.count
        self.phase = state.phase
        self.roundNumber = state.roundNumber

        self.scoreboard = [TeamID.teamA, .teamB].map {
            ScoreRow(teamID: $0, displayName: $0.displayName, score: state.teamScores[$0, default: 0])
        }

        self.isLocalPlayerTurn = isLocalTurn
        self.soloButtonVisible = (local?.hand.count == 1) && (local?.hasCalledSolo == false)

        // Pending decisions that belong to the local player
        if case .colourChoice(let pid) = state.pendingDecision, pid == localPlayerID {
            self.awaitingLocalColourChoice = true
        } else {
            self.awaitingLocalColourChoice = false
        }
        if case .targetChoice(let pid, let targets) = state.pendingDecision, pid == localPlayerID {
            self.localTargetChoices = targets
        } else {
            self.localTargetChoices = []
        }

        // A non-local seat the local player could catch for a missed Solo!
        self.catchableSoloPlayerID = state.ruleProfile.soloCallEnabled
            ? state.players.first(where: {
                $0.id != localPlayerID && $0.hand.count == 1 && !$0.hasCalledSolo
              })?.id
            : nil

        // Prompt
        self.prompt = GameViewState.prompt(
            state: state, localPlayerID: localPlayerID, isLocalTurn: isLocalTurn,
            localTeam: localTeam, hasLegalPlay: !legalIDs.isEmpty
        )
    }

    // MARK: Helpers

    /// Legal plays for a player, including the Draw-Four restriction (mirrors GameEngine).
    static func localLegalPlays(state: GameState, playerID: UUID) -> [Card] {
        guard let player = state.players.first(where: { $0.id == playerID }) else { return [] }
        return GameRules.legalPlays(hand: player.hand, state: state).filter { card in
            card.type != .drawFour || GameRules.drawFourIsLegal(hand: player.hand, state: state)
        }
    }

    /// Stable display ordering: by colour (wilds last), then by a type rank, then number.
    static func cardSortsBefore(_ a: Card, _ b: Card) -> Bool {
        let ca = a.colour.map(colourRank) ?? Int.max
        let cb = b.colour.map(colourRank) ?? Int.max
        if ca != cb { return ca < cb }
        let ta = typeRank(a.type), tb = typeRank(b.type)
        if ta != tb { return ta < tb }
        return numberValue(a.type) < numberValue(b.type)
    }

    private static func colourRank(_ c: CardColour) -> Int {
        switch c { case .crimson: return 0; case .cobalt: return 1; case .jade: return 2; case .amber: return 3 }
    }

    private static func numberValue(_ t: CardType) -> Int {
        if case .number(let v) = t { return v }
        return -1
    }

    private static func typeRank(_ t: CardType) -> Int {
        switch t {
        case .number: return 0
        case .skip: return 1
        case .skipTwo: return 2
        case .reverse: return 3
        case .drawTwo: return 4
        case .targetedDraw: return 5
        case .forcedSwap: return 6
        case .teamPlay: return 7
        case .changeColour: return 8
        case .drawFour: return 9
        case .discardAll: return 10
        }
    }

    private static func prompt(
        state: GameState, localPlayerID: UUID, isLocalTurn: Bool,
        localTeam: TeamID?, hasLegalPlay: Bool
    ) -> PromptKind {
        if state.phase == .roundEnded, let win = state.winState {
            return .roundOver(winningTeamName: win.winningTeam.displayName)
        }
        if state.phase == .gameEnded, let win = state.winState {
            return .gameOver(winningTeamName: win.winningTeam.displayName)
        }
        if case .colourChoice(let pid) = state.pendingDecision {
            return pid == localPlayerID ? .chooseColour : .waitingFor(playerName: name(of: pid, in: state))
        }
        if case .targetChoice(let pid, _) = state.pendingDecision {
            return pid == localPlayerID ? .chooseTarget : .waitingFor(playerName: name(of: pid, in: state))
        }
        if isLocalTurn {
            return hasLegalPlay ? .yourTurn(hint: matchHint(state: state)) : .mustDraw
        }
        if let current = state.currentPlayer {
            return .waitingFor(playerName: current.name)
        }
        return .paused
    }

    /// Builds the "play a Crimson card, a 5, or a wild card" hint from the active colour
    /// and top discard.
    public static func matchHint(state: GameState) -> String {
        var parts: [String] = ["a \(state.currentColour.displayName) card"]
        if let top = state.deck.topDiscard, case .number(let v) = top.type {
            parts.append("a \(v)")
        }
        parts.append("or a wild card")
        if parts.count == 2 {
            return "Play \(parts[0]) \(parts[1])."
        }
        return "Play \(parts[0]), \(parts[1]), \(parts[2])."
    }

    private static func name(of id: UUID, in state: GameState) -> String {
        state.players.first { $0.id == id }?.name ?? "Player"
    }
}

// MARK: - Display names for colours

extension CardColour {
    public var displayName: String {
        switch self {
        case .crimson: return "Crimson"
        case .cobalt:  return "Cobalt"
        case .jade:    return "Jade"
        case .amber:   return "Amber"
        }
    }
}
