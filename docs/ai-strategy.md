# Wild Pairs — AI Strategy

## TL;DR

Wild Pairs ships four AI difficulty levels (Easy, Medium, Hard, Expert) implemented as pure functions that receive an `AIObservation` — a filtered view of `GameState` — and return a `GameAction`. The AI never reads opponent or partner hand contents directly; it may only see hand *sizes*. Each difficulty level uses progressively more sophisticated move scoring, colour selection, and target selection. Expert uses 2–3 turn simulation. All AI logic is deterministic given a fixed seed, enabling automated simulation testing that verifies zero illegal moves and zero stuck games across thousands of random games.

---

## 1. Fairness Principle

The AI must not cheat. Cheating means accessing information that a real human player could not see at the table — specifically, the card contents of other players' hands.

This is enforced structurally: AI implementations receive only an `AIObservation` struct. `AIObservation` is constructed by the ViewModel/engine from `GameState` immediately before the AI is invoked. The constructor explicitly omits opponent and partner hand contents. There is no escape hatch.

**What AI may know:**
- The full discard pile (public)
- The current colour and pending action (public)
- The number of cards each player holds (public — in a real card game, you can count cards)
- The history of cards played this round (public)
- Team assignments (public)
- The full rule profile (public)
- Its own hand (private to itself — the owning player)
- Whose turn it is and turn direction (public)

**What AI may not know:**
- The contents (not count) of any other player's hand
- The sequence of cards remaining in the draw pile
- The RNG state
- Any information that is not visible in `AIObservation`

---

## 2. AIObservation Struct

```swift
struct AIObservation: Sendable {
    // Public game state
    let discardPile: [Card]
    let currentColour: CardColour
    let currentCardType: CardType?
    let cardCounts: [PlayerID: Int]
    let playedCardHistory: [Card]
    let teamState: TeamState
    let roundNumber: Int
    let teamScores: [TeamID: Int]

    // Turn context
    let activePlayerID: PlayerID
    let isMyTurn: Bool
    let turnDirection: TurnDirection

    // Rules
    let ruleProfile: RuleProfile

    // Own hand only — no other player's hand
    let myHand: [Card]
    let myPlayerID: PlayerID
    let myTeamID: TeamID
}
```

### Field Rationale

| Field | Why included |
|---|---|
| `discardPile` | AI needs to see what has been played for card counting |
| `currentColour` | Essential for determining legal plays |
| `currentCardType` | Needed to detect pending draw-two stack, reverse state, etc. |
| `cardCounts` | AI can count opponent cards to detect near-win; this is fair (humans can count) |
| `playedCardHistory` | Enables card counting for Hard/Expert AI |
| `teamState` | AI must know who its partner is to avoid targeting them |
| `roundNumber` | Context for urgency and scoring adjustments |
| `teamScores` | AI adjusts urgency when behind |
| `activePlayerID` | AI confirms it is the active player before acting |
| `isMyTurn` | Convenience guard |
| `turnDirection` | Needed to predict skip/reverse impact on turn order |
| `ruleProfile` | AI must know which card types are enabled, win conditions, etc. |
| `myHand` | AI can only play cards it holds |
| `myPlayerID` | Required to exclude self from target lists |
| `myTeamID` | Required to identify partner |

**Not included:** Opponent hand contents, partner hand contents, draw pile order, RNG state.

---

## 3. Easy AI Algorithm

Easy AI makes random legal moves with no strategy. It is designed to feel like a beginner — it plays valid cards but makes no effort to optimise.

```
function EasyAI.chooseMove(observation, rng):
    validCards = legalPlays(observation.myHand, observation)
    if validCards is empty:
        return GameAction.drawCard(myPlayerID)
    
    chosenCard = validCards.randomElement(using: rng)
    
    if chosenCard.requiresColourChoice:
        colour = CardColour.allCases.randomElement(using: rng)
        return GameAction.playCard(chosenCard, myPlayerID)
        // colour selection follows via separate selectColour action
    
    if chosenCard.requiresTarget:
        targets = validTargets(observation)
        target = targets.randomElement(using: rng)
        return GameAction.playCard(chosenCard, myPlayerID)
        // target selection follows via separate selectTarget action
    
    return GameAction.playCard(chosenCard, myPlayerID)

function EasyAI.selectColour(observation, rng):
    return CardColour.nonWild.randomElement(using: rng)

function EasyAI.selectTarget(observation, rng):
    return observation.cardCounts.keys
        .filter { $0 != observation.myPlayerID }
        .randomElement(using: rng)
```

**Characteristics:**
- No team awareness (may accidentally target partner)
- No colour strategy (random colour choice)
- No hand-thinning strategy
- Win rate vs Expert: approximately 25–30%

---

## 4. Medium AI Algorithm

Medium AI prefers action cards over number cards (higher disruption value), picks colours that benefit its own hand, and avoids targeting its teammate.

```
function MediumAI.chooseMove(observation, rng):
    validCards = legalPlays(observation.myHand, observation)
    if validCards is empty:
        return GameAction.drawCard(myPlayerID)
    
    // Prefer action cards
    actionCards = validCards.filter { $0.type != .number }
    pool = actionCards.isEmpty ? validCards : actionCards
    
    // Among pool, pick randomly
    chosen = pool.randomElement(using: rng)
    return GameAction.playCard(chosen, myPlayerID)

function MediumAI.selectColour(observation, rng):
    // Count colours in own hand, pick the most frequent
    counts = countColours(observation.myHand)
    return counts.max(by: { $0.value < $1.value })?.key
        ?? CardColour.nonWild.randomElement(using: rng)

function MediumAI.selectTarget(observation, rng):
    partnerID = partnerPlayerID(observation)
    opponents = observation.cardCounts.keys
        .filter { $0 != observation.myPlayerID && $0 != partnerID }
    
    if opponents.isEmpty:
        // Only teammate left — still required to pick someone
        return observation.cardCounts.keys
            .filter { $0 != observation.myPlayerID }
            .first
    
    // Target opponent with fewest cards (nearest to winning)
    return opponents.min(by: {
        observation.cardCounts[$0, default: 7] < observation.cardCounts[$1, default: 7]
    })
```

**Characteristics:**
- Avoids harming partner in target selection
- Prefers action cards
- Colour selection benefits own hand
- No lookahead or probability estimation
- Win rate vs Easy: approximately 60–65%

---

## 5. Hard AI Algorithm

Hard AI scores every legal move using a multi-factor framework and picks the highest-scoring move. It uses colour distribution analysis and strategic target selection.

```
function HardAI.chooseMove(observation, rng):
    validCards = legalPlays(observation.myHand, observation)
    if validCards is empty:
        return GameAction.drawCard(myPlayerID)
    
    scores = validCards.map { card in
        (card, scoreMove(card, observation))
    }
    
    bestScore = scores.max(by: { $0.1 < $1.1 })
    return GameAction.playCard(bestScore.card, myPlayerID)

function scoreMove(card, observation) -> Float:
    score = 0.0
    urgency = computeUrgency(observation)
    
    // Hand reduction reward
    score += Weight.handReduction * (1.0 + urgency)
    
    // Action card bonus
    if card.type != .number:
        score += Weight.actionBonus
    
    // Opponent disruption
    if card.requiresTarget:
        nearestOpponent = nearestOpponentToWin(observation)
        score += Weight.opponentDisruption * (10.0 / Float(observation.cardCounts[nearestOpponent] + 1))
    
    // Colour advantage
    if !card.isWild:
        myColourCount = observation.myHand.filter { $0.colour == card.colour }.count
        score += Weight.colourAdvantage * Float(myColourCount)
    
    // Conservation of rare powerful cards
    if card.type == .drawFour || card.type == .discardAll || card.type == .forcedSwap:
        if urgency < 0.5:
            score -= Weight.actionConservation
    
    // Penalty for targeting partner
    if card.requiresTarget:
        if wouldTargetPartner(card, observation):
            score -= Weight.partnerPenalty
    
    return score

function computeUrgency(observation) -> Float:
    myCount = observation.myHand.count
    return max(0.0, 1.0 - Float(myCount) / 7.0)
```

**Hard AI Weight Constants (in HardAI.swift):**
```swift
enum Weight {
    static let handReduction:      Float = 1.0
    static let actionBonus:        Float = 0.5
    static let opponentDisruption: Float = 2.0
    static let colourAdvantage:    Float = 0.3
    static let actionConservation: Float = 1.5
    static let partnerPenalty:     Float = 3.0
}
```

---

## 6. Expert AI Algorithm

Expert AI evaluates the top N candidate moves by simulating 2–3 turns ahead and estimating win probability after each.

```
function ExpertAI.chooseMove(observation, rng):
    validCards = legalPlays(observation.myHand, observation)
    if validCards is empty:
        return GameAction.drawCard(myPlayerID)
    
    // Pre-score using Hard scoring to rank candidates
    candidates = validCards
        .map { (card: $0, score: HardAI.scoreMove($0, observation)) }
        .sorted(by: { $0.score > $1.score })
        .prefix(ExpertConfig.simulationBreadth)  // top N=5 moves
    
    // Simulate each candidate
    bestMove = candidates.max { a, b in
        simulateWinProbability(a.card, observation, depth: 3, rng: rng)
            < simulateWinProbability(b.card, observation, depth: 3, rng: rng)
    }
    
    return GameAction.playCard(bestMove.card, myPlayerID)

function simulateWinProbability(card, observation, depth, rng) -> Float:
    if depth == 0:
        return HardAI.scoreMove(card, observation) / 20.0  // normalise to 0–1
    
    // Estimate resulting state after playing this card
    projectedHandSize = observation.myHand.count - 1
    projectedOpponentMin = minOpponentCardCount(observation)
    
    // Check if this wins the round
    if projectedHandSize == 0 && partnerHandSize == 0:
        return 1.0
    
    // Recurse: estimate opponent's best response
    opponentScore = estimateOpponentResponse(observation, depth: depth - 1, rng: rng)
    
    // Team win probability = own progress vs opponent progress
    return (1.0 - opponentScore) * teamProgressScore(projectedHandSize, observation)

function estimateOpponentResponse(observation, depth, rng) -> Float:
    // Use Medium scoring to model average opponent response
    // (Expert does not use opponent hand contents — uses card count only)
    nearestOpponent = nearestOpponentToWin(observation)
    opponentCardCount = observation.cardCounts[nearestOpponent, default: 7]
    return 1.0 / Float(opponentCardCount + 1)
```

**Expert Config Constants:**
```swift
enum ExpertConfig {
    static let simulationBreadth: Int = 5   // top N moves evaluated by simulation
    static let simulationDepth: Int = 3     // turns ahead to simulate
}
```

---

## 7. Move Scoring Framework

All Hard and Expert AI use a shared scoring framework with named weight dimensions.

### Scoring Dimensions

| Dimension | Description | Base Weight | Urgency Modifier |
|---|---|---|---|
| `handReduction` | Reward for reducing own hand by 1 | 1.0 | × (1 + urgency) |
| `teamBenefit` | Reward for enabling partner to play | 0.8 | × (1 + urgency × 0.5) |
| `opponentDisruption` | Reward for targeting nearest-to-win opponent | 2.0 | × 1.0 (no modifier) |
| `colourAdvantage` | Reward proportional to own cards of chosen colour | 0.3 | × 1.0 |
| `actionConservation` | Penalty for spending rare cards early | −1.5 | ÷ (1 + urgency) — penalty shrinks as urgency rises |
| `winProbability` | Estimated probability of team winning after move (Expert only) | 5.0 | × 1.5 if winning |
| `riskOfHelpingOpponent` | Penalty for reverse/skip that accidentally benefits opponent | −1.0 | × 1.0 |
| `urgency` | Multiplier computed from own hand size | Computed | Applied to all dimensions |
| `modeFit` | Adjusts weights per game mode (see below) | × 1.0–1.5 | — |

### Mode-Specific Weight Adjustments

| Mode | Adjustment |
|---|---|
| `standardTeams` | Baseline weights |
| `allWild` | `colourAdvantage` weight × 1.5; `actionConservation` weight × 0.5 (wilds are plentiful) |
| `sideToSide` | `opponentDisruption` weight × 1.3; `teamBenefit` weight × 0.7 (less partner cooperation) |

### Urgency Formula

```
urgency = max(0.0, 1.0 - (handCount / 7.0))
```

With 1 card left, urgency = 6/7 ≈ 0.86. With 7 cards (full hand), urgency = 0.0.

---

## 8. Colour Selection Strategy

Used when playing `changeColour` or `drawFour`.

```
function selectColour(observation) -> CardColour:
    // Count non-wild cards per colour in own hand
    counts = Dictionary(grouping: observation.myHand.filter { !$0.isWild }, by: { $0.colour })
        .mapValues { $0.count }
    
    // Pick colour with most cards
    best = counts.max(by: { $0.value < $1.value })?.key
    
    // Tiebreak: prefer colour that appears later in standard order
    // (arbitrary but consistent — avoids deterministic patterns)
    if best == nil:
        return .crimson   // fallback if hand is all wilds
    
    return best
```

**Partner awareness (Hard/Expert only):** If the AI can infer the partner is likely holding many of a given colour (via card counting from the discard history), it skews the colour choice to match. This is done without reading the partner's hand — it uses the cards *not* seen in the discard/play history as probabilistic evidence.

---

## 9. Target Selection Strategy

Used when playing `targetedDraw`, `forcedSwap`, or `skipTwo`.

```
function selectTarget(observation) -> PlayerID:
    partnerID = partnerPlayerID(observation)
    
    opponents = observation.cardCounts.keys
        .filter { $0 != observation.myPlayerID && $0 != partnerID }
    
    // Prioritise opponent nearest to winning (fewest cards)
    if !opponents.isEmpty:
        return opponents.min(by: {
            observation.cardCounts[$0, default: 7] < observation.cardCounts[$1, default: 7]
        })!
    
    // Fallback: if only partner remains (edge case), must still choose
    return partnerID
```

**forcedSwap special case:** Forced swap exchanges own hand with the target's hand. AI must check whether swapping is actually beneficial — if own hand is larger than the target's, it should swap with the opponent. If own hand is smaller than all other hands, forced swap harms self and should be avoided (Hard/Expert will score this negatively). Easy and Medium ignore this nuance.

---

## 10. Partner vs Opponent Awareness

```
function partnerPlayerID(observation) -> PlayerID?:
    return observation.teamState.players
        .filter { $0.teamID == observation.myTeamID && $0.id != observation.myPlayerID }
        .first?.id
```

**Medium AI:** Filters partner from target list. Does not otherwise model partner state.

**Hard AI:** Avoids targeting partner, scores moves that enable partner to go out (e.g., playing a card that does not skip partner), avoids playing reverse when it would help opponents.

**Expert AI:** Models partner card count trend (decreasing = partner is winning = increase urgency to support), adjusts colour choice to avoid forcing partner to draw, gives bonus score to moves that leave partner with the active colour.

**Strict limitation:** No AI level may access `observation.myHand` of another player. The partner's hand is always unknown to the AI. All partner reasoning is probabilistic, based only on card counts and play history.

---

## 11. AI Timing

| Difficulty | Base Think Delay | Rationale |
|---|---|---|
| Easy | 0.3 s | Feels like a casual player making a quick pick |
| Medium | 0.6 s | Feels like a considered choice |
| Hard | 0.9 s | Feels like deliberate strategy |
| Expert | 1.2 s | Feels like deep calculation |

Delays are implemented as `Task.sleep` in `GameViewModel.scheduleAITurn()`. The AI computation itself is synchronous and typically takes <1 ms. The delay is purely cosmetic UX.

**Fast Mode** (for testing and simulation): A `isFastMode` flag on `GameViewModel` sets all delays to 0. This is also used by `GameSimulator` for headless simulation.

**Animation gating:** The AI move is not dispatched until any pending card animation completes. This prevents the engine receiving an action while an animation is mid-flight. The ViewModel uses an animation completion callback before calling `scheduleAITurn`.

---

## 12. Simulation Framework

`GameSimulator` runs headless games for automated balancing and correctness testing.

```swift
struct GameSimulator {
    struct Config {
        var gameCount: Int
        var playerCount: Int
        var aiDifficulties: [Difficulty]
        var mode: GameMode
        var ruleProfile: RuleProfile
        var baseSeed: UInt64
        var fastMode: Bool
    }

    struct Results {
        var completedGames: Int
        var illegalMovesDetected: Int
        var stuckGames: Int
        var winRateByTeam: [TeamID: Double]
        var averageRoundLength: Double
        var averageHandSizeAtRoundEnd: Double
        var errorLog: [String]
    }

    static func run(config: Config) -> Results
}
```

### Seed Strategy

Each simulated game uses `seed = baseSeed + gameIndex`. This means any individual game can be re-run in isolation by setting `baseSeed` and `gameIndex`. A failed game is fully reproducible.

### Acceptance Criteria

| Metric | Pass threshold |
|---|---|
| Illegal moves | 0 across all simulated games |
| Stuck games | 0 (no game exceeds 1000 turns) |
| Easy vs Easy win rate | 45–55% per team (balanced) |
| Easy vs Expert win rate | Expert wins 65–80% |
| Expert vs Expert win rate | 45–55% per team (balanced) |

---

## 13. Anti-Patterns to Avoid

### AI Must Never Access Opponent Hand Directly

**Enforcement:** `AIObservation` is the only input to any AI function. It contains no opponent hand field. Code review must verify no AI file imports the type that exposes full `GameState`.

**Test:** `AIPlayerTests.testAIObservationDoesNotExposeOpponentHands()` — verifies `AIObservation` construction strips non-self hands.

### AI Must Never Make an Illegal Move

**Enforcement:** Before dispatching any AI action, `GameViewModel` calls `GameEngine.isLegalMove(state:action:)` and asserts in debug / logs in production. If the AI returns an illegal move, the engine ignores it and draws instead.

**Test:** `GameSimulatorTests.testZeroIllegalMovesAcross1000Games()` — simulation counts any illegal move attempt as a test failure.

### AI Must Never Cause a Stuck Game

**Enforcement:** The engine enforces a maximum turn limit (1000 turns per round) and ends the round as a draw if exceeded. `GameSimulator` checks `stuckGames == 0`.

**Test:** `GameSimulatorTests.testZeroStuckGamesAcross1000Games()`.

---

## 14. Balancing Targets

### Win Rate Matrix (team games, 2v2)

| Team A | Team B | Target win rate (Team A) |
|---|---|---|
| Easy × 2 | Easy × 2 | 45–55% |
| Medium × 2 | Easy × 2 | 55–70% |
| Hard × 2 | Medium × 2 | 55–70% |
| Expert × 2 | Hard × 2 | 55–70% |
| Expert × 2 | Easy × 2 | 65–80% |
| Mixed (E+Ex) | Mixed (M+H) | 45–65% |

### Weight Tuning

All weight constants are defined as named `enum` constants at the top of each AI file (`HardAI.swift`, `ExpertAI.swift`). They are not driven by a remote config or user-visible setting. To re-balance, a developer modifies the constants, runs `GameSimulatorTests`, and verifies win rates fall within targets.

Balancing occurs in Phase 4. Initial weights are set to produce approximately correct behaviour; fine-tuning is done by bisection on the constant values until all cells in the matrix above are within target ranges.

No A/B testing, no remote weight delivery, no user-configurable AI weights. The values are baked into the build.
