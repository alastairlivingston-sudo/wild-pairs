import Foundation

// MARK: - AIPlayer

public enum AIPlayer {

    // MARK: Public entry point

    public static func chooseMove(
        observation: AIObservation,
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> GameAction {
        switch difficulty {
        case .easy:   return EasyAI.chooseMove(observation: observation, rng: &rng)
        case .medium: return MediumAI.chooseMove(observation: observation, rng: &rng)
        case .hard:   return HardAI.chooseMove(observation: observation, rng: &rng)
        case .expert, .master: return ExpertAI.chooseMove(observation: observation, rng: &rng)
        }
    }

    public static func selectColour(
        observation: AIObservation,
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> CardColour {
        switch difficulty {
        case .easy:
            return EasyAI.selectColour(observation: observation, rng: &rng)
        case .medium, .hard, .expert, .master:
            return MediumAI.selectColour(observation: observation, rng: &rng)
        }
    }

    public static func selectTarget(
        observation: AIObservation,
        validTargets: [UUID],
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> UUID {
        switch difficulty {
        case .easy:
            return EasyAI.selectTarget(observation: observation, validTargets: validTargets, rng: &rng)
        case .medium, .hard, .expert, .master:
            return MediumAI.selectTarget(observation: observation, validTargets: validTargets, rng: &rng)
        }
    }

    /// Side-to-Side Teams only: picks a card from `myHand` to pass to the partner, or nil
    /// to decline. Easy mimics its "random valid move" philosophy (a coin flip on whether
    /// to pass at all, then a random card). Medium and up always attempt to pass, choosing
    /// the card whose colour is least represented in their own hand — i.e. their hardest
    /// card to use themselves, since giving it up costs the least optionality. Wild cards
    /// are never offered: they're too flexible to give away if any colour card is available.
    public static func selectTeamPassCard(
        observation: AIObservation,
        difficulty: Difficulty,
        rng: inout SeededRNG
    ) -> Card? {
        guard !observation.myHand.isEmpty else { return nil }
        switch difficulty {
        case .easy:
            guard Bool.random(using: &rng) else { return nil }
            return observation.myHand.randomElement(using: &rng)
        case .medium, .hard, .expert, .master:
            let nonWild = observation.myHand.filter { !$0.isWild }
            let candidates = nonWild.isEmpty ? observation.myHand : nonWild
            var colourCounts: [CardColour: Int] = [:]
            for card in observation.myHand {
                guard let colour = card.colour else { continue }
                colourCounts[colour, default: 0] += 1
            }
            return candidates.min { lhs, rhs in
                let lhsCount = lhs.colour.map { colourCounts[$0, default: 0] } ?? Int.max
                let rhsCount = rhs.colour.map { colourCounts[$0, default: 0] } ?? Int.max
                return lhsCount < rhsCount
            }
        }
    }

    public static func thinkDelay(for difficulty: Difficulty) -> TimeInterval {
        switch difficulty {
        case .easy:   return 0.3
        case .medium: return 0.6
        case .hard:   return 0.9
        case .expert: return 1.2
        case .master: return 1.5
        }
    }

    // MARK: Internal helpers

    /// Legal plays for the AI from its own hand, mirroring GameRules.isLegal / drawFourIsLegal.
    static func legalPlays(observation: AIObservation) -> [Card] {
        observation.myHand.filter { card in
            if observation.mode == .allWild { return true }
            if card.type == .drawFour { return drawFourIsLegal(observation: observation) }
            if card.isWild { return true }
            guard let colour = card.colour else { return true }
            if colour == observation.currentColour { return true }
            if let topType = observation.currentCardType {
                if card.type == topType { return true }
                if case .number(let v1) = card.type, case .number(let v2) = topType, v1 == v2 { return true }
            }
            return false
        }
    }

    /// Mirrors GameRules.drawFourIsLegal using only what an AI may observe.
    private static func drawFourIsLegal(observation: AIObservation) -> Bool {
        if observation.mode == .allWild { return true }
        if observation.ruleProfile.drawFourChallengeable { return true }
        return !observation.myHand.contains { card in
            guard !card.isWild, card.type != .drawFour else { return false }
            return card.colour == observation.currentColour
        }
    }
}

// MARK: - EasyAI

enum EasyAI {

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        let valid = AIPlayer.legalPlays(observation: observation)
        guard let chosen = valid.randomElement(using: &rng) else {
            return .drawCard(playerID: observation.myPlayerID)
        }
        return .playCard(chosen, playerID: observation.myPlayerID)
    }

    static func selectColour(observation: AIObservation, rng: inout SeededRNG) -> CardColour {
        return CardColour.allCases.randomElement(using: &rng) ?? .crimson
    }

    static func selectTarget(
        observation: AIObservation,
        validTargets: [UUID],
        rng: inout SeededRNG
    ) -> UUID {
        return validTargets.randomElement(using: &rng) ?? observation.myPlayerID
    }
}

// MARK: - MediumAI

enum MediumAI {

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        let valid = AIPlayer.legalPlays(observation: observation)
        guard !valid.isEmpty else {
            return .drawCard(playerID: observation.myPlayerID)
        }
        // Prefer action cards
        let actions = valid.filter {
            if case .number = $0.type { return false }
            return true
        }
        let pool = actions.isEmpty ? valid : actions
        guard let chosen = pool.randomElement(using: &rng) else {
            return .drawCard(playerID: observation.myPlayerID)
        }
        return .playCard(chosen, playerID: observation.myPlayerID)
    }

    static func selectColour(observation: AIObservation, rng: inout SeededRNG) -> CardColour {
        // Team-aware: weight by own hand plus the partner's open hand, so the chosen colour
        // sets up whichever teammate is better placed to keep playing, not just the AI itself.
        let myCounts = Dictionary(
            grouping: observation.myHand.compactMap(\.colour),
            by: { $0 }
        ).mapValues { $0.count }
        let partnerCounts = Dictionary(
            grouping: observation.partnerHand.compactMap(\.colour),
            by: { $0 }
        ).mapValues { $0.count }
        let teamCounts = CardColour.allCases.reduce(into: [CardColour: Int]()) { result, colour in
            result[colour] = myCounts[colour, default: 0] + partnerCounts[colour, default: 0]
        }
        // Dictionary.max(by:) ties break in hash-iteration order, which is randomized per
        // process for enum keys — that made AI colour choice (and everything downstream of
        // it) non-deterministic across runs of the same seed. Break ties via the fixed,
        // canonical CardColour.allCases order instead.
        guard let maxCount = teamCounts.values.max(), maxCount > 0 else {
            return CardColour.allCases.randomElement(using: &rng) ?? .crimson
        }
        return CardColour.allCases.first { teamCounts[$0] == maxCount } ?? .crimson
    }

    static func selectTarget(
        observation: AIObservation,
        validTargets: [UUID],
        rng: inout SeededRNG
    ) -> UUID {
        let opponents = validTargets.filter { $0 != observation.partnerID }
        let pool = opponents.isEmpty ? validTargets : opponents
        return pool.min(by: {
            observation.cardCounts[$0, default: 7] < observation.cardCounts[$1, default: 7]
        }) ?? pool.first ?? observation.myPlayerID
    }
}

// MARK: - HardAI

enum HardAI {

    enum Weight {
        static let handReduction:      Float = 1.0
        static let actionBonus:        Float = 0.5
        static let opponentDisruption: Float = 2.0
        static let colourAdvantage:    Float = 0.3
        static let actionConservation: Float = 1.5
        static let partnerPenalty:     Float = 3.0
        static let partnerSynergy:     Float = 0.4
    }

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        let valid = AIPlayer.legalPlays(observation: observation)
        guard !valid.isEmpty else {
            return .drawCard(playerID: observation.myPlayerID)
        }
        let scored = valid.map { ($0, scoreMove($0, observation: observation)) }
        guard let best = scored.max(by: { $0.1 < $1.1 }) else {
            return .drawCard(playerID: observation.myPlayerID)
        }
        return .playCard(best.0, playerID: observation.myPlayerID)
    }

    static func scoreMove(_ card: Card, observation: AIObservation) -> Float {
        let urgency = computeUrgency(observation)
        var score: Float = 0.0

        // Hand reduction reward
        score += Weight.handReduction * (1.0 + urgency)

        // Action card bonus
        if case .number = card.type { } else { score += Weight.actionBonus }

        // Opponent disruption
        if isTargeting(card) {
            if let nearest = observation.nearestOpponentToWin {
                let opponentCount = Float(observation.cardCounts[nearest, default: 7])
                score += Weight.opponentDisruption * (10.0 / (opponentCount + 1))
            }
        }

        // Colour advantage
        if !card.isWild, let colour = card.colour {
            let myColourCount = Float(observation.myHand.filter { $0.colour == colour }.count)
            score += Weight.colourAdvantage * myColourCount

            // Team synergy: leaving the active colour on something the partner's open hand
            // is rich in sets them up for their next turn, regardless of seating order.
            let partnerColourCount = Float(observation.partnerHand.filter { $0.colour == colour }.count)
            score += Weight.partnerSynergy * partnerColourCount
        }

        // Conservation of rare powerful cards when urgency is low
        switch card.type {
        case .drawFour, .discardAll, .forcedSwap:
            if urgency < 0.5 { score -= Weight.actionConservation }
        default: break
        }

        // Penalty for targeting partner (if this is a targeted card and partner is the only valid target)
        if isTargeting(card), let partner = observation.partnerID {
            let opponents = observation.cardCounts.keys.filter {
                $0 != observation.myPlayerID && $0 != partner
            }
            if opponents.isEmpty {
                score -= Weight.partnerPenalty
            }
        }

        return score
    }

    static func computeUrgency(_ observation: AIObservation) -> Float {
        let count = Float(observation.myHand.count)
        return max(0.0, 1.0 - count / 7.0)
    }

    private static func isTargeting(_ card: Card) -> Bool {
        switch card.type {
        case .targetedDraw, .forcedSwap: return true
        default: return false
        }
    }
}

// MARK: - ExpertAI

enum ExpertAI {

    enum Config {
        static let simulationBreadth: Int = 5
        static let simulationDepth: Int = 3
    }

    static func chooseMove(observation: AIObservation, rng: inout SeededRNG) -> GameAction {
        let valid = AIPlayer.legalPlays(observation: observation)
        guard !valid.isEmpty else {
            return .drawCard(playerID: observation.myPlayerID)
        }

        // Pre-score and select top N candidates
        let candidates = valid
            .map { (card: $0, score: HardAI.scoreMove($0, observation: observation)) }
            .sorted { $0.score > $1.score }
            .prefix(Config.simulationBreadth)

        // Simulate each and pick best
        var bestCard = candidates.first!.card
        var bestProb: Float = -1.0
        for candidate in candidates {
            let prob = simulateWinProbability(
                card: candidate.card,
                observation: observation,
                depth: Config.simulationDepth,
                rng: &rng
            )
            if prob > bestProb {
                bestProb = prob
                bestCard = candidate.card
            }
        }
        return .playCard(bestCard, playerID: observation.myPlayerID)
    }

    static func simulateWinProbability(
        card: Card,
        observation: AIObservation,
        depth: Int,
        rng: inout SeededRNG
    ) -> Float {
        if depth == 0 {
            return HardAI.scoreMove(card, observation: observation) / 20.0
        }

        let projectedHandSize = observation.myHand.count - 1

        // If own hand would be empty and partner is also at low count, high probability
        if projectedHandSize == 0 {
            let partnerCount = observation.partnerID.flatMap { observation.cardCounts[$0] } ?? 7
            if partnerCount <= 1 { return 1.0 }
        }

        // Estimate opponent's response using card count only
        let opponentScore = estimateOpponentResponse(observation: observation)

        // Team win probability: own progress vs opponent progress
        let ownProgress: Float = projectedHandSize == 0
            ? 1.0
            : 1.0 / Float(projectedHandSize + 1)
        return (1.0 - opponentScore) * ownProgress
    }

    private static func estimateOpponentResponse(observation: AIObservation) -> Float {
        guard let nearest = observation.nearestOpponentToWin else { return 0.0 }
        let opponentCount = Float(observation.cardCounts[nearest, default: 7])
        return 1.0 / (opponentCount + 1)
    }
}
