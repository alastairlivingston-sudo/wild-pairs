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
    /// The seat's position relative to the local player's perspective: 0 = bottom (the local
    /// player), 1 = left, 2 = across, 3 = right. Equal to `seatPosition` when the local player
    /// sits at seat 0; rotated for pass-and-play perspectives so the active human always
    /// renders at the bottom of the table.
    public let tablePosition: Int
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
        id: UUID, name: String, teamID: TeamID, seatPosition: Int, tablePosition: Int? = nil,
        handCount: Int, isCurrentPlayer: Bool, hasFinishedRound: Bool,
        isLocalPlayer: Bool, needsSoloCall: Bool, visiblePartnerHand: [Card]? = nil
    ) {
        self.id = id; self.name = name; self.teamID = teamID
        self.seatPosition = seatPosition; self.tablePosition = tablePosition ?? seatPosition
        self.handCount = handCount
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
    /// Side-to-Side Teams only: the local player must submit a card to pass to their
    /// partner, or decline.
    case chooseTeamPass
    /// Draw Four challenge (Phase 17 B2): the local player must challenge the Draw Four or accept it.
    case challengeDrawFour
    case mustDraw
    /// Draw stacking (Phase 11 F): the local player must stack a matching Draw Two/Four or
    /// draw the whole pending stack.
    case stackOrDraw(count: Int)
    /// A pending draw stack the local player cannot answer — no stacking card in hand, so
    /// the penalty is being picked up automatically (no tap required).
    case forcedPickup(count: Int)
    case roundOver(winningTeamName: String)
    /// Round timer fallback fired (`WinReason.roundTimerExpired`) — nobody emptied their
    /// hand, the round was decided by lowest card-point score instead of a normal go-out.
    case roundOverByTimeout(winningTeamName: String)
    case gameOver(winningTeamName: String)
    case paused
}

// MARK: GameViewState

public struct GameViewState: Equatable, Sendable {

    public let seats: [PlayerSeatViewState]
    /// The local player's hand, sorted for display, each tagged with playability.
    public let localHand: [CardViewModel]
    public let topDiscard: Card?
    /// Up to three real discards beneath the top card (oldest→newest), so the pile can be
    /// drawn as a played history rather than blank ghost stock (Phase 16 discard memory).
    public let recentDiscards: [Card]
    public let currentColour: CardColour
    public let turnDirection: TurnDirection
    public let drawPileCount: Int
    /// Draw stacking (Phase 11 F): the pending draw penalty the active player must answer,
    /// surfaced for the draw-pile badge regardless of whose turn it is. Nil if none pending.
    public let pendingDrawCount: Int?
    public let scoreboard: [ScoreRow]
    public let prompt: PromptKind
    public let phase: GamePhase
    public let roundNumber: Int

    public let isLocalPlayerTurn: Bool
    /// True when it's the local player's turn and nothing in their hand is playable — the
    /// only move is the draw pile. Drives the draw-pile attention treatment.
    public let mustDrawNow: Bool
    /// Whether a draw is legal right now — mirrors GameEngine.handleDrawCard's guard so the
    /// draw pile is only tappable when the player must draw (no legal play) or may absorb a
    /// pending draw stack. Prevents the "keep picking up cards" bug (game-rules.md §Draw Procedure).
    public let canDrawNow: Bool
    /// Non-nil when `mustDrawNow` and a draw stack is pending: the number of penalty cards
    /// the local player is forced to pick up (they hold no card that can answer the stack).
    /// The ViewModel auto-draws this — the player is never prompted to tap for a forced pickup.
    public let forcedPickupCount: Int?
    /// The local player may press "Solo!" — on their turn holding two cards (declare before
    /// playing down to one), or at one card within an effect-drop grace window.
    public let soloButtonVisible: Bool
    /// True when the engine is waiting for the local player to pick a colour.
    public let awaitingLocalColourChoice: Bool
    /// True while ANY player still owes a wild its colour choice — the discard's wild face
    /// stays uncoloured until this clears (Phase 13 resolved-wild tint).
    public let colourChoicePending: Bool
    /// Non-empty when the engine is waiting for the local player to pick a target.
    public let localTargetChoices: [UUID]
    /// True when the engine is waiting for the local player to submit their Side-to-Side
    /// Team Pass choice (a card to give their partner, or decline).
    public let awaitingLocalTeamPass: Bool
    /// True when the local player is the target of a fresh, challengeable Draw Four and must
    /// decide whether to challenge it (Phase 17 B2, opt-in). Drives the challenge prompt.
    public let awaitingLocalDrawFourChallenge: Bool
    /// The name of the player who played the Draw Four being challenged, and the colour that was
    /// in force before it — for the challenge prompt copy. Nil unless a challenge is pending.
    public let drawFourChallengedName: String?
    public let drawFourPriorColour: CardColour?
    /// A seat the local player can legally call out for a missed Solo!, if any.
    public let catchableSoloPlayerID: UUID?
    /// Whether the local player's team won, once `winState` is set (nil while still playing).
    /// Lets the UI choose "Your team wins…" vs "Opponents win…" framing (ux-spec.md §10).
    public let localTeamWon: Bool?

    /// Points credited to the winning team for the just-ended round (losing team's remaining
    /// card points × the toughest opponent's score multiplier), or nil while still playing.
    /// Surfaced so the round-end screen can show the award and scoring reads as legible rather
    /// than an opaque jump in the running total (Phase 17 scoring-display fix).
    public let roundScoreAwarded: Int?

    /// Live raw card-value sum (game-rules.md scoring table, no difficulty multiplier) across
    /// the local player's own team's hands — "what we'd lose if the round ended now." Only ever
    /// derived from the local team's own hands (one of which is the local player's own, fully
    /// known hand; the other is the open partner hand already visible in the UI), so it never
    /// leaks hidden opponent-hand information.
    public let localTeamPointsAtRisk: Int

    // MARK: Derivation

    public init(from state: GameState, localPlayerID: UUID) {
        let local = state.players.first { $0.id == localPlayerID }
        let localTeam = local?.teamID
        let partnerID = state.teamState.partnerID(for: localPlayerID)
        let localSeat = local?.seatPosition ?? 0
        let seatCount = max(state.players.count, 1)

        // Table position: the perspective player sits at the bottom (0) and the table rotates so
        // opponents keep their spatial arrangement (pass-and-play). On top of that, the partner is
        // always pinned across the top (2) — needed because Side-to-Side now seats the partner
        // adjacent to you (Phase 17 B3) rather than directly across. When the partner already
        // rotates to the top (canonical alternating seating) this is a no-op, so existing layouts
        // are unchanged; otherwise the partner takes slot 2 and the seat naturally across the top
        // takes the partner's rotational slot.
        func rotational(_ seat: Int) -> Int { ((seat - localSeat) % seatCount + seatCount) % seatCount }
        let partnerRotational = partnerID
            .flatMap { pid in state.players.first { $0.id == pid }?.seatPosition }
            .map(rotational)
        func tablePosition(for p: Player) -> Int {
            let r = rotational(p.seatPosition)
            guard let partnerR = partnerRotational, partnerR != 2 else { return r }
            if p.id == partnerID { return 2 }
            if r == 2 { return partnerR }
            return r
        }

        self.seats = state.players
            .sorted { $0.seatPosition < $1.seatPosition }
            .map { p in
                PlayerSeatViewState(
                    id: p.id, name: p.name, teamID: p.teamID, seatPosition: p.seatPosition,
                    tablePosition: tablePosition(for: p),
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
        self.recentDiscards = state.deck.discardPile.count > 1
            ? Array(state.deck.discardPile.dropLast().suffix(3)) : []
        self.currentColour = state.currentColour
        self.turnDirection = state.turnDirection
        self.drawPileCount = state.deck.drawPile.count
        // Display total for the pending draw stack. The engine deliberately holds a Draw Four's
        // +4 until its colour is chosen ("stack must not grow until colour is chosen"), but the
        // badge should reflect the true total the instant the +4 is committed — otherwise it
        // reads inconsistently depending on whether the stack started with a +2 (immediate) or a
        // +4 (deferred until colour choice). While a Draw Four awaits its colour choice, add its
        // +4 here for display only (Phase 17 A1); the engine's resolution timing is unchanged.
        self.pendingDrawCount = {
            guard state.ruleProfile.stackDrawCards else { return nil }
            if case .colourChoice = state.pendingDecision, state.currentCardType == .drawFour {
                return (state.pendingDrawCount ?? 0) + 4
            }
            return state.pendingDrawCount
        }()
        self.phase = state.phase
        self.roundNumber = state.roundNumber

        self.scoreboard = [TeamID.teamA, .teamB].map {
            ScoreRow(teamID: $0, displayName: $0.displayName, score: state.teamScores[$0, default: 0])
        }

        self.isLocalPlayerTurn = isLocalTurn
        self.mustDrawNow = isLocalTurn && legalIDs.isEmpty && !(local?.hand.isEmpty ?? true)
        self.canDrawNow = isLocalTurn && !(local?.hand.isEmpty ?? true)
            && (state.pendingDrawCount != nil || legalIDs.isEmpty)
        self.forcedPickupCount = (isLocalTurn && legalIDs.isEmpty && state.ruleProfile.stackDrawCards)
            ? state.pendingDrawCount : nil
        self.soloButtonVisible = {
            guard let local, !local.hasCalledSolo else { return false }
            if local.hand.count == 2 && isLocalTurn { return true }
            return local.hand.count == 1 && local.soloGraceAtOne == true
        }()
        if case .colourChoice = state.pendingDecision {
            self.colourChoicePending = true
        } else {
            self.colourChoicePending = false
        }

        // Pending decisions that belong to the local player. Only live while the round is in
        // play (or the pre-round team pass) — once it has ended, a decision overlay must never
        // linger on top of the round-end screen with dead buttons (Tier 0c).
        let decisionsLive = state.phase == .playing || state.phase == .teamPass
        if decisionsLive, case .colourChoice(let pid) = state.pendingDecision, pid == localPlayerID {
            self.awaitingLocalColourChoice = true
        } else {
            self.awaitingLocalColourChoice = false
        }
        if decisionsLive, case .targetChoice(let pid, let targets) = state.pendingDecision, pid == localPlayerID {
            self.localTargetChoices = targets
        } else {
            self.localTargetChoices = []
        }
        if decisionsLive, case .teamPass(let pid) = state.pendingDecision, pid == localPlayerID {
            self.awaitingLocalTeamPass = true
        } else {
            self.awaitingLocalTeamPass = false
        }
        if decisionsLive,
           case .drawFourChallenge(let challengerID, let challengedID, let priorColour, _) = state.pendingDecision,
           challengerID == localPlayerID {
            self.awaitingLocalDrawFourChallenge = true
            self.drawFourChallengedName = state.players.first { $0.id == challengedID }?.name
            self.drawFourPriorColour = priorColour
        } else {
            self.awaitingLocalDrawFourChallenge = false
            self.drawFourChallengedName = nil
            self.drawFourPriorColour = nil
        }

        // A non-local seat the local player could catch for a missed Solo!
        self.catchableSoloPlayerID = state.ruleProfile.soloCallEnabled
            ? state.players.first(where: {
                $0.id != localPlayerID && $0.hand.count == 1 && !$0.hasCalledSolo
              })?.id
            : nil

        self.localTeamWon = state.winState.map { $0.winningTeam == localTeam }
        self.roundScoreAwarded = state.winState.flatMap { win in
            win.roundPoints.map { $0 * (win.scoreMultiplier ?? 1) }
        }

        self.localTeamPointsAtRisk = state.players
            .filter { $0.teamID == localTeam }
            .flatMap(\.hand)
            .reduce(0) { $0 + GameEngine.pointValue(for: $1) }

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
        return GameRules.legalPlaysConsideringDrawFour(hand: player.hand, state: state)
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
        case .drawEight: return 5
        case .targetedDraw: return 6
        case .forcedSwap: return 7
        case .teamPlay: return 8
        case .discardColour: return 9
        case .changeColour: return 10
        case .drawFour: return 11
        case .discardAll: return 12
        }
    }

    private static func prompt(
        state: GameState, localPlayerID: UUID, isLocalTurn: Bool,
        localTeam: TeamID?, hasLegalPlay: Bool
    ) -> PromptKind {
        if state.phase == .roundEnded, let win = state.winState {
            if win.reason == .roundTimerExpired {
                return .roundOverByTimeout(winningTeamName: win.winningTeam.displayName)
            }
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
        if case .teamPass(let pid) = state.pendingDecision {
            return pid == localPlayerID ? .chooseTeamPass : .waitingFor(playerName: name(of: pid, in: state))
        }
        if case .drawFourChallenge(let challengerID, _, _, _) = state.pendingDecision {
            return challengerID == localPlayerID ? .challengeDrawFour
                                                 : .waitingFor(playerName: name(of: challengerID, in: state))
        }
        if isLocalTurn {
            if let pendingCount = state.pendingDrawCount, state.ruleProfile.stackDrawCards {
                return hasLegalPlay ? .stackOrDraw(count: pendingCount)
                                    : .forcedPickup(count: pendingCount)
            }
            return hasLegalPlay ? .yourTurn(hint: matchHint(state: state)) : .mustDraw
        }
        if let current = state.currentPlayer {
            return .waitingFor(playerName: current.name)
        }
        return .paused
    }

    /// Builds the "play a Lava card, a 5, or a wild card" hint from the active colour
    /// and top discard.
    public static func matchHint(state: GameState) -> String {
        let colour = state.currentColour.displayName
        var parts: [String] = ["\(article(for: colour)) \(colour) card"]
        if let top = state.deck.topDiscard, case .number(let v) = top.type {
            parts.append("\(article(for: "\(v)")) \(v)")
        }
        parts.append("or a wild card")
        if parts.count == 2 {
            return "Play \(parts[0]) \(parts[1])."
        }
        return "Play \(parts[0]), \(parts[1]), \(parts[2])."
    }

    /// "a"/"an" by sound, for our vocabulary: vowel-initial words and the digit 8
    /// ("eight") take "an"; everything else takes "a".
    private static func article(for word: String) -> String {
        let vowelInitial = "aeiouAEIOU".contains(word.first ?? " ")
        return (vowelInitial || word == "8") ? "an" : "a"
    }

    private static func name(of id: UUID, in state: GameState) -> String {
        state.players.first { $0.id == id }?.name ?? "Player"
    }
}

// MARK: - Display names for colours

// Display-only retheme (Phase 11 D): the engine's internal vocabulary — case names, Codable
// raw values, CLAUDE.md "Canonical Design Vocabulary" — stays crimson/cobalt/jade/amber for
// save/test stability. Only what players see (and VoiceOver reads, since it reads
// `displayName`) changes to the player-facing names: crimson→Lava, cobalt→Sky,
// jade→Grass, amber→Sun.
extension CardColour {
    public var displayName: String {
        switch self {
        case .crimson: return "Lava"
        case .cobalt:  return "Sky"
        case .jade:    return "Grass"
        case .amber:   return "Sun"
        }
    }
}
