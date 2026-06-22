import Foundation

// MARK: - GameEngine

public struct GameEngine {

    // MARK: Public entry point

    public static func reduce(
        state: GameState,
        action: GameAction
    ) -> (GameState, [GameEffect]) {
        switch action {
        case .newGame(let config):
            return handleNewGame(config: config)
        case .playCard(let card, let playerID):
            return handlePlayCard(card, playerID: playerID, state: state)
        case .drawCard(let playerID):
            return handleDrawCard(playerID: playerID, state: state)
        case .selectColour(let colour, let playerID):
            return handleSelectColour(colour, playerID: playerID, state: state)
        case .selectTarget(let targetID, let playerID):
            return handleSelectTarget(targetPlayerID: targetID, playerID: playerID, state: state)
        case .callSolo(let playerID):
            return handleCallSolo(playerID: playerID, state: state)
        case .teamPass(let playerID):
            return handleTeamPass(playerID: playerID, state: state)
        case .passTurn(let playerID):
            return handlePassTurn(playerID: playerID, state: state)
        case .pauseGame:
            var s = state; s.phase = .roundEnded; return (s, [.triggerAutosave])
        case .resumeGame:
            var s = state; s.phase = .playing; return (s, [])
        case .beginNewRound:
            return handleBeginNewRound(state: state)
        case .restoreSnapshot(let snap):
            return (snap.state, [.triggerAutosave])
        case .aiMove(let inner, _):
            return reduce(state: state, action: inner)
        case .advancePendingDecision:
            var s = state; s.pendingDecision = nil; return (s, [])
        case .challengeDrawFour:
            return (state, [])   // Phase 4 extension
        case .forceState(let forced):
            return (forced, [])
        }
    }

    // MARK: Public helpers

    public static func isLegalMove(state: GameState, action: GameAction) -> Bool {
        switch action {
        case .playCard(let card, let playerID):
            guard let player = state.players.first(where: { $0.id == playerID }),
                  state.currentPlayer?.id == playerID,
                  player.hand.contains(where: { $0.id == card.id }) else { return false }
            if card.type == .drawFour {
                return GameRules.drawFourIsLegal(hand: player.hand, state: state)
            }
            return GameRules.isLegal(card, in: state)
        case .drawCard(let playerID):
            return state.currentPlayer?.id == playerID
        default:
            return true
        }
    }

    public static func legalPlays(state: GameState, for playerID: UUID) -> [Card] {
        guard let player = state.players.first(where: { $0.id == playerID }) else { return [] }
        return GameRules.legalPlays(hand: player.hand, state: state).filter { card in
            card.type != .drawFour || GameRules.drawFourIsLegal(hand: player.hand, state: state)
        }
    }

    // MARK: - New game

    private static func handleNewGame(config: GameConfig) -> (GameState, [GameEffect]) {
        var rng = config.seed.map { SeededRNG(seed: $0) }
            ?? SeededRNG(seed: SeededRNG.generateSeed())
        let seed = config.seed ?? SeededRNG.generateSeed()
        rng = SeededRNG(seed: seed)

        var deck = Deck.standard(cardSet: config.ruleProfile.cardSet, rng: &rng)

        // Build players
        var players: [Player] = config.players.map { pc in
            Player(
                name: pc.name,
                role: pc.role,
                teamID: pc.teamID,
                difficulty: pc.difficulty,
                seatPosition: pc.seatPosition
            )
        }

        // Deal hands
        for i in players.indices {
            players[i].hand = deck.deal(count: config.ruleProfile.initialHandSize, rng: &rng)
        }

        // Flip starting discard card; skip wild-type cards at start
        var startCard: Card
        repeat {
            guard let drawn = deck.draw(rng: &rng) else { break }
            startCard = drawn
            if startCard.isWild {
                deck.discard(startCard)
                continue
            }
            break
        } while true

        if let top = deck.drawPile.first, !top.isWild {
            startCard = deck.drawPile.removeFirst()
        } else {
            // Fall back: use first non-wild from pile
            if let idx = deck.drawPile.firstIndex(where: { !$0.isWild }) {
                startCard = deck.drawPile.remove(at: idx)
            } else {
                startCard = Card(type: .number(0), colour: .crimson)
            }
        }
        deck.discard(startCard)
        let startColour = startCard.colour ?? .crimson

        let state = GameState(
            schemaVersion: 1,
            players: players,
            currentPlayerIndex: 0,
            turnDirection: .clockwise,
            currentColour: startColour,
            currentCardType: startCard.type,
            pendingDecision: nil,
            deck: deck,
            phase: .playing,
            mode: config.mode,
            ruleProfile: config.ruleProfile,
            roundNumber: 1,
            teamScores: [.teamA: 0, .teamB: 0],
            winState: nil,
            rngSeed: seed,
            actionCount: 0,
            eventLog: []
        )

        let effects: [GameEffect] = [.animateCardShuffle, .triggerAutosave]
        return (state, effects)
    }

    // MARK: - Play card

    private static func handlePlayCard(
        _ card: Card,
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard let playerIndex = state.players.firstIndex(where: { $0.id == playerID }),
              state.currentPlayerIndex == playerIndex,
              state.phase == .playing,
              state.pendingDecision == nil else {
            return (state, [.accessibilityAnnounce("Invalid move")])
        }

        guard state.players[playerIndex].hand.contains(where: { $0.id == card.id }),
              isLegalMove(state: state, action: .playCard(card, playerID: playerID)) else {
            return (state, [.accessibilityAnnounce("Invalid move")])
        }

        var s = state
        var effects: [GameEffect] = []

        // Remove card from hand
        s.players[playerIndex].hand.removeAll { $0.id == card.id }
        s.deck.discard(card)
        s.currentColour = card.colour ?? s.currentColour
        s.currentCardType = card.type
        s.actionCount += 1

        effects.append(.animateCardPlay(card: card, fromPlayerID: playerID))

        // Solo! check: player now has 1 card
        if s.players[playerIndex].hand.count == 1 {
            s.players[playerIndex].hasCalledSolo = false
        }

        // Apply card effect
        var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount))
        let (withEffect, effectEffects) = applyCardEffect(
            card: card,
            playedByIndex: playerIndex,
            state: s,
            rng: &rng
        )
        s = withEffect
        effects.append(contentsOf: effectEffects)

        // Win check: if hand is now empty
        if s.players[playerIndex].hand.isEmpty {
            s.players[playerIndex].hasFinishedRound = true
            if let (finalState, winEffects) = checkWin(state: s) {
                effects.append(contentsOf: winEffects)
                effects.append(.triggerAutosave)
                return (finalState, effects)
            }
        }

        effects.append(.triggerAutosave)
        return (s, effects)
    }

    // MARK: - Apply card effects

    private static func applyCardEffect(
        card: Card,
        playedByIndex: Int,
        state: GameState,
        rng: inout SeededRNG
    ) -> (GameState, [GameEffect]) {
        var s = state
        var effects: [GameEffect] = []
        let n = s.players.count

        switch card.type {

        case .number:
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n)

        case .skip:
            let skipped = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n)
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n, skipCount: 2)
            effects.append(.animateSkip(playerID: s.players[skipped].id))

        case .skipTwo:
            let skip1 = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n, skipCount: 1)
            let skip2 = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n, skipCount: 2)
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n, skipCount: 3)
            effects.append(.animateSkipTwo(firstPlayerID: s.players[skip1].id,
                                           secondPlayerID: s.players[skip2].id))

        case .reverse:
            s.turnDirection = s.turnDirection == .clockwise ? .counterClockwise : .clockwise
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n)
            effects.append(.animateReverse)

        case .drawTwo:
            let targetIndex = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n)
            let drawn = drawCards(count: 2, into: &s, rng: &rng)
            s.players[targetIndex].hand.append(contentsOf: drawn)
            // Skip the target player
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playedByIndex, direction: s.turnDirection, playerCount: n, skipCount: 2)
            effects.append(.animateCardDraw(toPlayerID: s.players[targetIndex].id, count: 2))

        case .drawFour:
            // Colour selection required — set pending decision
            s.pendingDecision = .colourChoice(playerID: s.players[playedByIndex].id)
            effects.append(.promptColourChoice(playerID: s.players[playedByIndex].id))
            // Turn does NOT advance until colour chosen; drawFour penalty applied in selectColour

        case .changeColour:
            s.pendingDecision = .colourChoice(playerID: s.players[playedByIndex].id)
            effects.append(.promptColourChoice(playerID: s.players[playedByIndex].id))

        case .discardAll:
            // Wild card: colour selection determines which colour to discard
            s.pendingDecision = .colourChoice(playerID: s.players[playedByIndex].id)
            effects.append(.promptColourChoice(playerID: s.players[playedByIndex].id))

        case .targetedDraw:
            let validTargets = opponents(of: playedByIndex, in: s)
            s.pendingDecision = .targetChoice(
                playerID: s.players[playedByIndex].id,
                validTargets: validTargets.map { s.players[$0].id }
            )
            effects.append(.promptTargetChoice(
                playerID: s.players[playedByIndex].id,
                validTargets: validTargets.map { s.players[$0].id }
            ))

        case .forcedSwap:
            let allOthers = (0..<n).filter { $0 != playedByIndex }
            s.pendingDecision = .targetChoice(
                playerID: s.players[playedByIndex].id,
                validTargets: allOthers.map { s.players[$0].id }
            )
            effects.append(.promptTargetChoice(
                playerID: s.players[playedByIndex].id,
                validTargets: allOthers.map { s.players[$0].id }
            ))

        case .teamPlay:
            let teamIndex = s.players[playedByIndex].teamID
            let partnerIndices = (0..<n).filter {
                $0 != playedByIndex && s.players[$0].teamID == teamIndex
            }
            if s.ruleProfile.partnerPlaysImmediately {
                // House rule: partner plays — set pending (skipping for Phase 2)
                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playedByIndex, direction: s.turnDirection, playerCount: n)
            } else {
                // Default: both partners draw 1 card
                for idx in partnerIndices + [playedByIndex] {
                    if let drawn = drawCards(count: 1, into: &s, rng: &rng).first {
                        s.players[idx].hand.append(drawn)
                        effects.append(.animateCardDraw(toPlayerID: s.players[idx].id, count: 1))
                    }
                }
                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playedByIndex, direction: s.turnDirection, playerCount: n)
            }
        }

        return (s, effects)
    }

    // MARK: - Select colour

    private static func handleSelectColour(
        _ colour: CardColour,
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard case .colourChoice(let pid) = state.pendingDecision,
              pid == playerID else {
            return (state, [])
        }

        var s = state
        var effects: [GameEffect] = []
        s.currentColour = colour
        s.pendingDecision = nil
        s.actionCount += 1

        guard let playerIndex = s.players.firstIndex(where: { $0.id == playerID }) else {
            return (s, [])
        }

        // Determine what triggered the colour choice
        if let topCard = s.deck.topDiscard {
            switch topCard.type {

            case .drawFour:
                let targetIndex = GameRules.nextIndex(
                    from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
                var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount))
                let drawn = drawCards(count: 4, into: &s, rng: &rng)
                s.players[targetIndex].hand.append(contentsOf: drawn)
                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playerIndex, direction: s.turnDirection,
                    playerCount: s.players.count, skipCount: 2)
                effects.append(.animateCardDraw(toPlayerID: s.players[targetIndex].id, count: 4))

            case .discardAll:
                // Discard all cards of chosen colour from the player's hand
                let removed = s.players[playerIndex].hand.filter { $0.colour == colour }
                s.players[playerIndex].hand.removeAll { $0.colour == colour }
                for card in removed { s.deck.discard(card) }
                effects.append(.animateDiscardAll(playerID: playerID, colour: colour))

                if s.players[playerIndex].hand.isEmpty {
                    s.players[playerIndex].hasFinishedRound = true
                    if let (finalState, winEffects) = checkWin(state: s) {
                        effects.append(contentsOf: winEffects)
                        effects.append(.triggerAutosave)
                        return (finalState, effects)
                    }
                } else if s.players[playerIndex].hand.count == 1 {
                    s.players[playerIndex].hasCalledSolo = false
                }

                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)

            default:
                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
            }
        }

        effects.append(.triggerAutosave)
        return (s, effects)
    }

    // MARK: - Select target

    private static func handleSelectTarget(
        targetPlayerID: UUID,
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard case .targetChoice(let pid, let valid) = state.pendingDecision,
              pid == playerID,
              valid.contains(targetPlayerID) else {
            return (state, [])
        }

        var s = state
        var effects: [GameEffect] = []
        s.pendingDecision = nil
        s.actionCount += 1

        guard let playerIndex = s.players.firstIndex(where: { $0.id == playerID }),
              let targetIndex = s.players.firstIndex(where: { $0.id == targetPlayerID }),
              let topCard = s.deck.topDiscard else {
            return (s, [])
        }

        switch topCard.type {

        case .targetedDraw:
            // Target draws 2; their turn is NOT skipped
            var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount))
            let drawn = drawCards(count: 2, into: &s, rng: &rng)
            s.players[targetIndex].hand.append(contentsOf: drawn)
            effects.append(.animateCardDraw(toPlayerID: targetPlayerID, count: 2))
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)

        case .forcedSwap:
            let myHand = s.players[playerIndex].hand
            let theirHand = s.players[targetIndex].hand
            s.players[playerIndex].hand = theirHand
            s.players[targetIndex].hand = myHand

            // Re-evaluate Solo! status for both
            s.players[playerIndex].hasCalledSolo =
                s.players[playerIndex].hand.count != 1
                    ? s.players[playerIndex].hasCalledSolo : false
            s.players[targetIndex].hasCalledSolo =
                s.players[targetIndex].hand.count != 1
                    ? s.players[targetIndex].hasCalledSolo : false

            effects.append(.animateHandSwap(
                fromPlayerID: playerID, toPlayerID: targetPlayerID))

            // Check win for player who received a new hand
            for idx in [playerIndex, targetIndex] {
                if s.players[idx].hand.isEmpty {
                    s.players[idx].hasFinishedRound = true
                    if let (finalState, winEffects) = checkWin(state: s) {
                        effects.append(contentsOf: winEffects)
                        effects.append(.triggerAutosave)
                        return (finalState, effects)
                    }
                }
            }
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)

        default:
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
        }

        effects.append(.triggerAutosave)
        return (s, effects)
    }

    // MARK: - Draw card

    private static func handleDrawCard(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard let playerIndex = state.players.firstIndex(where: { $0.id == playerID }),
              state.currentPlayerIndex == playerIndex,
              state.phase == .playing,
              state.pendingDecision == nil else {
            return (state, [])
        }

        var s = state
        var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount))
        s.actionCount += 1

        guard let drawn = s.deck.draw(rng: &rng) else {
            // Nothing to draw — pass turn
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
            return (s, [])
        }

        s.players[playerIndex].hand.append(drawn)
        var effects: [GameEffect] = [
            .animateCardDraw(toPlayerID: playerID, count: 1)
        ]

        // If drawn card is playable and mustPlayAfterDraw, we let the view decide
        // (no auto-play: human/AI must explicitly play it)

        // If no other legal play existed, turn ends
        let otherLegals = GameRules.legalPlays(hand: s.players[playerIndex].hand.dropLast().map { $0 },
                                                state: s)
        if otherLegals.isEmpty {
            // Advance turn: player had no card before drawing
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
        }
        // If other cards were already playable, the human chose to draw — turn still advances
        // (simplified: turn always ends after draw in Phase 2)
        s.currentPlayerIndex = GameRules.nextIndex(
            from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)

        effects.append(.triggerAutosave)
        return (s, effects)
    }

    // MARK: - Call Solo

    private static func handleCallSolo(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard let playerIndex = state.players.firstIndex(where: { $0.id == playerID }),
              state.players[playerIndex].hand.count == 1 else {
            return (state, [])
        }
        var s = state
        s.players[playerIndex].hasCalledSolo = true
        let name = s.players[playerIndex].name
        return (s, [.announceSolo(playerName: name)])
    }

    // MARK: - Team pass (Side-to-Side pre-round)

    private static func handleTeamPass(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        // Team pass is a pre-round swap; the card to pass is carried in the action
        // For Phase 2 we accept the action and do nothing — full logic in Phase 3
        return (state, [])
    }

    // MARK: - Pass turn

    private static func handlePassTurn(
        playerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard let playerIndex = state.players.firstIndex(where: { $0.id == playerID }),
              state.currentPlayerIndex == playerIndex else {
            return (state, [])
        }
        var s = state
        s.currentPlayerIndex = GameRules.nextIndex(
            from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
        s.actionCount += 1
        return (s, [.triggerAutosave])
    }

    // MARK: - Begin new round

    private static func handleBeginNewRound(state: GameState) -> (GameState, [GameEffect]) {
        var s = state
        var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount + 1))
        s.roundNumber += 1
        s.actionCount += 1

        // Reset player state
        for i in s.players.indices {
            s.players[i].hand = []
            s.players[i].hasCalledSolo = false
            s.players[i].hasFinishedRound = false
        }

        // New deck, deal, flip start
        s.deck = Deck.standard(cardSet: s.ruleProfile.cardSet, rng: &rng)
        for i in s.players.indices {
            s.players[i].hand = s.deck.deal(count: s.ruleProfile.initialHandSize, rng: &rng)
        }
        var startCard: Card
        repeat {
            guard let drawn = s.deck.draw(rng: &rng) else { break }
            startCard = drawn
            if !startCard.isWild { break }
            s.deck.discard(startCard)
        } while true
        if let top = s.deck.drawPile.first(where: { !$0.isWild }) {
            s.deck.drawPile.removeAll { $0.id == top.id }
            startCard = top
        } else {
            startCard = Card(type: .number(0), colour: .crimson)
        }
        s.deck.discard(startCard)
        s.currentColour = startCard.colour ?? .crimson
        s.currentCardType = startCard.type
        s.currentPlayerIndex = 0
        s.turnDirection = .clockwise
        s.pendingDecision = nil
        s.winState = nil
        s.phase = .playing
        return (s, [.animateCardShuffle, .triggerAutosave])
    }

    // MARK: - Win detection

    private static func checkWin(state: GameState) -> (GameState, [GameEffect])? {
        var s = state

        switch s.ruleProfile.winCondition {
        case .bothTeammatesOut:
            for team in [TeamID.teamA, TeamID.teamB] {
                let teamPlayers = s.players.filter { $0.teamID == team }
                if teamPlayers.allSatisfy({ $0.hasFinishedRound }) {
                    return declareWin(team: team, state: &s)
                }
            }
        case .singleOut:
            for player in s.players where player.hasFinishedRound {
                return declareWin(team: player.teamID, state: &s)
            }
        }
        return nil
    }

    private static func declareWin(
        team: TeamID,
        state: inout GameState
    ) -> (GameState, [GameEffect]) {
        let points = calculatePoints(losingTeam: team.opponent, players: state.players)
        state.teamScores[team, default: 0] += points
        state.winState = WinState(
            winningTeam: team,
            winningPlayerID: nil,
            reason: .bothTeammatesEmptiedHands,
            finalScores: state.teamScores
        )
        if state.ruleProfile.scoringEnabled && state.ruleProfile.targetScore > 0 {
            let winningScore = state.teamScores[team, default: 0]
            if winningScore >= state.ruleProfile.targetScore {
                state.phase = .gameEnded
                return (state, [.playGameEnd(winningTeam: team)])
            }
        }
        state.phase = .roundEnded
        return (state, [.playRoundEnd(winningTeam: team)])
    }

    private static func calculatePoints(losingTeam: TeamID, players: [Player]) -> Int {
        players
            .filter { $0.teamID == losingTeam }
            .flatMap { $0.hand }
            .reduce(0) { total, card in
                switch card.type {
                case .number(let v): return total + v
                case .skip, .reverse, .drawTwo, .skipTwo, .targetedDraw,
                     .forcedSwap, .teamPlay: return total + 20
                case .discardAll: return total + 20
                case .drawFour, .changeColour: return total + 50
                }
            }
    }

    // MARK: - Helpers

    private static func drawCards(count: Int, into state: inout GameState, rng: inout SeededRNG) -> [Card] {
        (0..<count).compactMap { _ in state.deck.draw(rng: &rng) }
    }

    private static func opponents(of playerIndex: Int, in state: GameState) -> [Int] {
        let myTeam = state.players[playerIndex].teamID
        return state.players.indices.filter {
            $0 != playerIndex && state.players[$0].teamID != myTeam
        }
    }
}
