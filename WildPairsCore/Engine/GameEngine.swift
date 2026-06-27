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
        case .callOutSolo(let targetID, let callerID):
            return handleCallOutSolo(targetPlayerID: targetID, callerID: callerID, state: state)
        case .submitTeamPass(let playerID, let card):
            return handleSubmitTeamPass(playerID: playerID, card: card, state: state)
        case .passTurn(let playerID):
            return handlePassTurn(playerID: playerID, state: state)
        case .pauseGame:
            var s = state; s.phase = .roundEnded; return (s, [.triggerAutosave])
        case .resumeGame:
            var s = state; s.phase = .playing; return (s, [])
        case .beginNewRound:
            return handleBeginNewRound(state: state)
        case .roundTimerExpired:
            return handleRoundTimerExpired(state: state)
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
            return GameRules.isCardLegal(card, hand: player.hand, state: state)
        case .drawCard(let playerID):
            return state.currentPlayer?.id == playerID
        default:
            return true
        }
    }

    public static func legalPlays(state: GameState, for playerID: UUID) -> [Card] {
        guard let player = state.players.first(where: { $0.id == playerID }) else { return [] }
        return GameRules.legalPlaysConsideringDrawFour(hand: player.hand, state: state)
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

        // Flip starting discard card; wild-type cards are set aside and returned to the
        // bottom of the draw pile (per rules: "shuffle it back and flip again"). No card
        // ever leaves the game.
        let startCard = flipStartCard(from: &deck, rng: &rng)
        deck.discard(startCard)
        let startColour = startCard.colour ?? .crimson

        let teamPassEnabled = config.ruleProfile.teamPassEnabled

        let state = GameState(
            schemaVersion: 1,
            players: players,
            currentPlayerIndex: 0,
            turnDirection: .clockwise,
            currentColour: startColour,
            currentCardType: startCard.type,
            pendingDecision: teamPassEnabled ? firstTeamPassDecision(for: players) : nil,
            deck: deck,
            phase: teamPassEnabled ? .teamPass : .playing,
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

        // Win / Solo! check on the FINAL hand (after the card effect, so a Team Play self-draw
        // that pushes back above one card is correctly accounted for).
        if s.players[playerIndex].hand.isEmpty {
            s.players[playerIndex].hasFinishedRound = true
            if let (finalState, winEffects) = checkWin(state: s) {
                effects.append(contentsOf: winEffects)
                effects.append(.triggerAutosave)
                return (finalState, effects)
            }
        } else if s.players[playerIndex].hand.count == 1 {
            // AI auto-calls Solo!; the human must call manually.
            effects.append(contentsOf: applySoloRequirement(toPlayerAt: playerIndex, in: &s))
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
            if s.ruleProfile.stackDrawCards {
                // Accumulate the stack instead of drawing immediately; the next player must
                // answer with another Draw Two/Four or draw the whole pending stack.
                s.pendingDrawCount = (s.pendingDrawCount ?? 0) + 2
                s.pendingDrawType = .drawTwo
                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playedByIndex, direction: s.turnDirection, playerCount: n)
            } else {
                let targetIndex = GameRules.nextIndex(
                    from: playedByIndex, direction: s.turnDirection, playerCount: n)
                let drawn = drawCards(count: 2, into: &s, rng: &rng)
                s.players[targetIndex].hand.append(contentsOf: drawn)
                // Skip the target player
                s.currentPlayerIndex = GameRules.nextIndex(
                    from: playedByIndex, direction: s.turnDirection, playerCount: n, skipCount: 2)
                effects.append(.animateCardDraw(toPlayerID: s.players[targetIndex].id, count: 2))
            }

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
                if s.ruleProfile.stackDrawCards {
                    s.pendingDrawCount = (s.pendingDrawCount ?? 0) + 4
                    s.pendingDrawType = .drawFour
                    s.currentPlayerIndex = GameRules.nextIndex(
                        from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
                } else {
                    let targetIndex = GameRules.nextIndex(
                        from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
                    var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount))
                    let drawn = drawCards(count: 4, into: &s, rng: &rng)
                    s.players[targetIndex].hand.append(contentsOf: drawn)
                    s.currentPlayerIndex = GameRules.nextIndex(
                        from: playerIndex, direction: s.turnDirection,
                        playerCount: s.players.count, skipCount: 2)
                    effects.append(.animateCardDraw(toPlayerID: s.players[targetIndex].id, count: 4))
                }

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
                    effects.append(contentsOf: applySoloRequirement(toPlayerAt: playerIndex, in: &s))
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

            // Re-evaluate Solo! status for both: anyone now at exactly one card
            // re-incurs the requirement (AI auto-calls; human must call).
            for idx in [playerIndex, targetIndex] where s.players[idx].hand.count == 1 {
                effects.append(contentsOf: applySoloRequirement(toPlayerAt: idx, in: &s))
            }

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

        // Draw stacking (Phase 11 F): a pending stack is absorbed in full — no draw-and-play,
        // since these are penalty cards, not a normal turn draw — and the turn ends.
        if let pendingCount = s.pendingDrawCount {
            let drawn = drawCards(count: pendingCount, into: &s, rng: &rng)
            s.players[playerIndex].hand.append(contentsOf: drawn)
            s.pendingDrawCount = nil
            s.pendingDrawType = nil
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
            return (s, [
                .animateCardDraw(toPlayerID: playerID, count: pendingCount),
                .triggerAutosave
            ])
        }

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

        // Draw-and-play (mustPlayAfterDraw): a player only draws when they had no legal
        // play, so the just-drawn card is the only thing that could be playable. If it is,
        // the turn stays with the player so they can play it; otherwise the turn ends.
        let drawnIsPlayable = GameRules.isLegal(drawn, in: s)
            && (drawn.type != .drawFour
                || GameRules.drawFourIsLegal(hand: s.players[playerIndex].hand, state: s))
        if !drawnIsPlayable {
            s.currentPlayerIndex = GameRules.nextIndex(
                from: playerIndex, direction: s.turnDirection, playerCount: s.players.count)
        }

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

    // MARK: - Call out a missed Solo!

    private static func handleCallOutSolo(
        targetPlayerID: UUID,
        callerID: UUID,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard state.ruleProfile.soloCallEnabled,
              callerID != targetPlayerID,
              let targetIndex = state.players.firstIndex(where: { $0.id == targetPlayerID }),
              state.players.contains(where: { $0.id == callerID }),
              state.players[targetIndex].hand.count == 1,
              !state.players[targetIndex].hasCalledSolo else {
            return (state, [])
        }

        var s = state
        var rng = SeededRNG(seed: s.rngSeed &+ UInt64(s.actionCount))
        s.actionCount += 1

        let penalty = s.ruleProfile.soloCallPenaltyCards
        let drawn = drawCards(count: penalty, into: &s, rng: &rng)
        s.players[targetIndex].hand.append(contentsOf: drawn)

        let name = s.players[targetIndex].name
        return (s, [
            .soloCallMissed(playerName: name, penaltyCards: penalty),
            .accessibilityAnnounce("\(name) did not call Solo! — drawing \(penalty) cards."),
            .animateCardDraw(toPlayerID: targetPlayerID, count: penalty),
            .triggerAutosave
        ])
    }

    /// Applies the Solo! requirement to a player who just dropped to one card.
    /// AI players auto-call (matching `game-rules.md` §Solo! Engine Handling); human
    /// players are flagged as needing to call manually. Returns any effects to emit.
    private static func applySoloRequirement(
        toPlayerAt index: Int,
        in state: inout GameState
    ) -> [GameEffect] {
        if state.players[index].role == .ai {
            state.players[index].hasCalledSolo = true
            return [.announceSolo(playerName: state.players[index].name)]
        } else {
            state.players[index].hasCalledSolo = false
            return [.accessibilityAnnounce("Call Solo! You have one card remaining.")]
        }
    }

    // MARK: - Team pass (Side-to-Side pre-round)

    // MARK: - Team pass (Side-to-Side Teams)

    /// Records one player's Team Pass submission (a card to give, or nil to decline). Once
    /// every player has submitted, performs the simultaneous within-team swap for any team
    /// where both members chose a card, then transitions to `.playing`. Players submit in
    /// seat order — this is a sequencing convenience, not a fairness leak: nobody's choice
    /// is revealed to the others (not even their own partner) until the swap itself happens.
    private static func handleSubmitTeamPass(
        playerID: UUID,
        card: Card?,
        state: GameState
    ) -> (GameState, [GameEffect]) {
        guard state.phase == .teamPass,
              case .teamPass(let pendingID) = state.pendingDecision,
              pendingID == playerID,
              let playerIndex = state.players.firstIndex(where: { $0.id == playerID }) else {
            return (state, [.accessibilityAnnounce("Invalid move")])
        }
        if let card, !state.players[playerIndex].hand.contains(where: { $0.id == card.id }) {
            return (state, [.accessibilityAnnounce("Invalid move")])
        }

        var s = state
        if let card {
            s.teamPassSelections = (s.teamPassSelections ?? [:])
            s.teamPassSelections?[playerID] = card
        } else {
            s.teamPassDeclined = (s.teamPassDeclined ?? [])
            s.teamPassDeclined?.insert(playerID)
        }

        let submittedIDs = Set((s.teamPassSelections ?? [:]).keys).union(s.teamPassDeclined ?? [])
        guard let next = s.players
            .sorted(by: { $0.seatPosition < $1.seatPosition })
            .first(where: { !submittedIDs.contains($0.id) })
        else {
            return resolveTeamPass(state: s)
        }

        s.pendingDecision = .teamPass(playerID: next.id)
        return (s, [.triggerAutosave])
    }

    /// Every player has submitted; swap cards within each team that both opted in, then
    /// open play. A unilateral decline cancels that team's swap (you can't exchange with a
    /// partner who isn't exchanging back) but never blocks the other team's swap.
    private static func resolveTeamPass(state: GameState) -> (GameState, [GameEffect]) {
        var s = state
        let selections = s.teamPassSelections ?? [:]

        for team in [TeamID.teamA, .teamB] {
            let teamPlayerIndices = s.players.indices.filter { s.players[$0].teamID == team }
            guard teamPlayerIndices.count == 2,
                  let givingCardA = selections[s.players[teamPlayerIndices[0]].id],
                  let givingCardB = selections[s.players[teamPlayerIndices[1]].id] else {
                continue
            }
            let indexA = teamPlayerIndices[0]
            let indexB = teamPlayerIndices[1]
            s.players[indexA].hand.removeAll { $0.id == givingCardA.id }
            s.players[indexB].hand.removeAll { $0.id == givingCardB.id }
            s.players[indexA].hand.append(givingCardB)
            s.players[indexB].hand.append(givingCardA)
        }

        s.teamPassSelections = nil
        s.teamPassDeclined = nil
        s.pendingDecision = nil
        s.phase = .playing
        return (s, [.accessibilityAnnounce("Team pass complete. Play begins."), .triggerAutosave])
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
        let startCard = flipStartCard(from: &s.deck, rng: &rng)
        s.deck.discard(startCard)
        s.currentColour = startCard.colour ?? .crimson
        s.currentCardType = startCard.type
        s.currentPlayerIndex = 0
        s.turnDirection = .clockwise
        s.winState = nil
        s.teamPassSelections = nil
        s.teamPassDeclined = nil
        s.pendingDrawCount = nil
        s.pendingDrawType = nil
        if s.ruleProfile.teamPassEnabled {
            s.pendingDecision = firstTeamPassDecision(for: s.players)
            s.phase = .teamPass
        } else {
            s.pendingDecision = nil
            s.phase = .playing
        }
        return (s, [.animateCardShuffle, .triggerAutosave])
    }

    /// Seat-ordered first player who must submit a Team Pass choice.
    private static func firstTeamPassDecision(for players: [Player]) -> PendingDecision? {
        guard let first = players.sorted(by: { $0.seatPosition < $1.seatPosition }).first else { return nil }
        return .teamPass(playerID: first.id)
    }

    // MARK: - Win detection

    private static func checkWin(state: GameState) -> (GameState, [GameEffect])? {
        var s = state

        switch s.ruleProfile.winCondition {
        case .bothTeammatesOut:
            for team in [TeamID.teamA, TeamID.teamB] {
                let teamPlayers = s.players.filter { $0.teamID == team }
                if teamPlayers.allSatisfy({ $0.hasFinishedRound }) {
                    return declareWin(team: team, winningPlayerID: nil,
                                       reason: .bothTeammatesEmptiedHands, state: &s)
                }
            }
        case .singleOut:
            for player in s.players where player.hasFinishedRound {
                return declareWin(team: player.teamID, winningPlayerID: player.id,
                                   reason: .singlePlayerEmptiedHand, state: &s)
            }
        }
        return nil
    }

    /// Fallback when nobody emptied their hand within `RuleProfile.roundTimeLimitSeconds`: the
    /// player with the lowest card-point score wins, crediting their team. No-op if the round
    /// already ended before this fires (e.g. a race with a hand-emptying win in the simulator).
    private static func handleRoundTimerExpired(state: GameState) -> (GameState, [GameEffect]) {
        guard state.phase == .playing, !state.players.isEmpty else { return (state, []) }
        var s = state

        let winner = s.players.min { lhs, rhs in
            let lhsPoints = pointValue(for: lhs.hand)
            let rhsPoints = pointValue(for: rhs.hand)
            if lhsPoints != rhsPoints { return lhsPoints < rhsPoints }
            if lhs.hand.count != rhs.hand.count { return lhs.hand.count < rhs.hand.count }
            return lhs.seatPosition < rhs.seatPosition
        }!

        let opponents = s.players.filter { $0.id != winner.id }
        let basePoints = opponents.reduce(0) { $0 + pointValue(for: $1.hand) }
        let multiplier = opponents.map(\.difficulty.scoreMultiplier).max() ?? 1
        s.teamScores[winner.teamID, default: 0] += basePoints * multiplier
        s.winState = WinState(
            winningTeam: winner.teamID,
            winningPlayerID: winner.id,
            reason: .roundTimerExpired,
            finalScores: s.teamScores
        )
        if s.ruleProfile.scoringEnabled && s.ruleProfile.targetScore > 0 {
            let winningScore = s.teamScores[winner.teamID, default: 0]
            if winningScore >= s.ruleProfile.targetScore {
                s.phase = .gameEnded
                return (s, [.playGameEnd(winningTeam: winner.teamID)])
            }
        }
        s.phase = .roundEnded
        return (s, [.playRoundEnd(winningTeam: winner.teamID)])
    }

    private static func declareWin(
        team: TeamID,
        winningPlayerID: UUID?,
        reason: WinReason,
        state: inout GameState
    ) -> (GameState, [GameEffect]) {
        let losingPlayers = state.players.filter { $0.teamID == team.opponent }
        let points = calculatePoints(players: losingPlayers)
        let multiplier = losingPlayers.map(\.difficulty.scoreMultiplier).max() ?? 1
        state.teamScores[team, default: 0] += points * multiplier
        state.winState = WinState(
            winningTeam: team,
            winningPlayerID: winningPlayerID,
            reason: reason,
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

    private static func calculatePoints(players: [Player]) -> Int {
        pointValue(for: players.flatMap(\.hand))
    }

    /// Uno-style point value of a hand: numbers at face value, action/wild cards at fixed
    /// point costs. Used both for the losing-team score on a hand-emptying win and for
    /// determining the lowest-score winner when the round timer expires.
    private static func pointValue(for hand: [Card]) -> Int {
        hand.reduce(0) { $0 + pointValue(for: $1) }
    }

    /// Public per-card point value (game-rules.md scoring table: number = face value, action
    /// = 20, wild = 50). Exposed for the presentation layer's live "points at risk" display —
    /// a raw sum with no difficulty multiplier, since that's just live card values, not a score.
    public static func pointValue(for card: Card) -> Int {
        switch card.type {
        case .number(let v): return v
        case .skip, .reverse, .drawTwo, .skipTwo, .targetedDraw,
             .forcedSwap, .teamPlay: return 20
        case .discardAll: return 20
        case .drawFour, .changeColour: return 50
        }
    }

    // MARK: - Helpers

    /// Draws cards until a non-wild start card is found. Any wild-type cards drawn along the
    /// way are returned to the bottom of the draw pile (rules: "shuffle it back and flip
    /// again") so no card ever leaves the game. Falls back to a Crimson 0 only if the deck
    /// holds no non-wild card at all (effectively impossible for a real deck).
    private static func flipStartCard(from deck: inout Deck, rng: inout SeededRNG) -> Card {
        var buriedWilds: [Card] = []
        var start: Card? = nil
        while let drawn = deck.draw(rng: &rng) {
            if drawn.isWild {
                buriedWilds.append(drawn)
                continue
            }
            start = drawn
            break
        }
        deck.returnToDrawPileBottom(buriedWilds)
        return start ?? Card(type: .number(0), colour: .crimson)
    }

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
