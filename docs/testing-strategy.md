# Wild Pairs — Testing Strategy

> Last updated: 2026-06-21  
> Status: Living document — update as test suites are implemented.

---

## TL;DR

Test pyramid from base to apex:

1. **Unit tests** (many, fast) — engine logic, rules, persistence, AI constraints
2. **Scenario tests** (medium, fast) — full game scenarios, one per rule/mechanic
3. **Simulation tests** (few, slower) — 1,000 games per AI pairing for balance
4. **UI tests** (selective, slow) — critical user journeys only
5. **Manual test scripts** (scripted, human) — UX, accessibility, device-specific, sensory

All automated tests run via `swift test` (unit, scenario, simulation) or `xcodebuild test` (UI). Manual tests are scripted in `docs/manual-test-scripts.md`.

---

## 1. Test Pyramid

```
         ┌──────────────┐
         │  Manual Tests │  ← UX, accessibility, haptics, layout quality
         └──────┬───────┘
         ┌──────┴───────┐
         │   UI Tests   │  ← Critical journeys (XCTest/XCUITest)
         └──────┬───────┘
         ┌──────┴───────┐
         │  Simulation  │  ← 1,000 games per pairing (balance, stability)
         └──────┬───────┘
         ┌──────┴───────┐
         │   Scenario   │  ← One scenario per rule/mechanic
         └──────┬───────┘
    ┌─────┴──────────────┐
    │     Unit Tests     │  ← Functions, models, encode/decode, AI
    └────────────────────┘
```

### Why this pyramid

Unit and scenario tests are fast (< 1 s each) and run on every commit. Simulation tests are slower (target: < 60 s for 1,000 games) and run at phase gates. UI tests are slow and fragile and cover only the most critical paths. Manual tests cover what automation cannot: visual quality, haptics, VoiceOver feel, one-handed reach.

---

## 2. Test Tooling

| Tool | Purpose | When used |
|---|---|---|
| **Swift Testing** (`@Test`, `#expect`) | Unit and scenario tests | All new tests (preferred) |
| **XCTest** | Legacy unit tests; Xcode UI tests | XCUITest only for UI tests |
| **`SeededRNG`** | Deterministic deck/shuffle for reproducible tests | All tests involving shuffling |
| **`GameStateBuilder`** | Constructs specific game states for scenario tests | All scenario tests |
| **`GameSimulator`** | Runs a complete game headlessly for simulation tests | Simulation tests only |

### Design principles

- **No mocking of the game engine.** Tests exercise the real `GameEngine` reducer. Mocking the engine would test the mock, not the game.
- **Seeded randomness.** All tests that involve any shuffle or random draw use `SeededRNG(seed: N)` for a known, reproducible sequence.
- **Builder pattern for fixtures.** `GameStateBuilder` creates minimal game states for specific scenarios rather than requiring full game setup.
- **One assertion per scenario.** Each scenario test has a single clear pass/fail condition. Complex outcomes are split into multiple tests.

---

## 3. Unit Test Coverage Targets

| Component | Coverage target | Rationale |
|---|---|---|
| Engine reducer (`GameEngine.reduce`) | 95%+ line coverage | Core logic; some branches are defensive/unreachable |
| Rules — valid move calculation | 100% branch coverage | Every legal/illegal combination must be tested |
| Rules — card effect resolution | 100% branch coverage | Every action card must be verified |
| Rules — win conditions | 100% branch coverage | Incorrect win detection is a critical bug |
| Persistence — encode/decode | 100% for all model types | A round-trip failure silently corrupts saves |
| AI — no illegal moves | 100% assertion (not coverage) | AI must never select an unplayable card |
| AI — observation masking | 100% assertion (not coverage) | AI must never see opponents' hands |
| AI — difficulty behaviours | Functional (not coverage) | Each difficulty plays 100 deterministic games without error |

Coverage is measured via Xcode's code coverage report (`xcodebuild test -enableCodeCoverage YES`). Targets are enforced at phase gates, not CI (coverage tooling requires macOS).

---

## 4. Test Tooling Implementation Notes

### SeededRNG

```swift
// WildPairsCore/Sources/WildPairsCore/Testing/SeededRNG.swift
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
```

Usage in tests:

```swift
var rng = SeededRNG(seed: 42)
let deck = Deck.standard().shuffled(using: &rng)
```

### GameStateBuilder

```swift
// Usage pattern
let state = GameStateBuilder()
    .withPlayers([.human("Alice"), .ai(.easy, "Bot1"), .ai(.easy, "Bot2"), .human("Bob")])
    .withTeams([[0, 3], [1, 2]])
    .withHand(forPlayer: 0, cards: [Card(.skip, .crimson)])
    .withTopDiscard(Card(.number(5), .cobalt))
    .build()
```

### GameSimulator

```swift
// Usage pattern — runs a full game to completion
let result = GameSimulator.run(
    mode: .standardTeams,
    difficulty: .expert,
    seed: 12345
)
// result.winner: TeamIndex
// result.turns: Int
// result.illegalMoveAttempts: Int (must be 0)
// result.stuck: Bool (must be false)
```

---

## 5. Scenario Test List

Each scenario is one `@Test` function in `WildPairsCoreTests/ScenarioTests.swift`. The description column summarises what the test asserts.

| Test function | Description |
|---|---|
| `testHumanHasNoValidCardMustDraw` | When human's hand contains no card matching top discard colour or number, and no wild, the only legal action is draw. Engine presents draw-only state. |
| `testHumanDrawsPlayableCard` | Human draws a card that matches top discard. Engine immediately presents the option to play the drawn card. Human plays it. Discard pile updates correctly. |
| `testHumanDrawsUnplayableCardTurnPasses` | Human draws a card that does not match. Engine advances to the next player's turn without playing. Draw pile decreases by 1, hand increases by 1. |
| `testHumanChoosesColourAfterWild` | Human plays a Wild card. Engine enters `pendingColourChoice` state. Human picks Jade. Engine resumes with active colour set to Jade. |
| `testHumanChoosesTargetAfterTargetedDraw` | Human plays a Targeted Draw card. Engine enters `pendingTargetChoice` state listing eligible targets. Human picks target index 2. Target player receives +2 cards and loses a turn. |
| `testSkipSkipsCorrectPlayer` | Skip card played by player 0 in a 4-player game (direction: clockwise). Player 1 is skipped; turn passes to player 2. |
| `testSkipTwoSkipsTwoPlayers` | Skip Two card played by player 0 in a 4-player game. Players 1 and 2 are skipped; turn passes to player 3. |
| `testReverseChangesDirectionWith4Players` | Reverse card played in a 4-player game (direction: clockwise). Direction becomes counterclockwise. Turn passes from player 2 to player 1. |
| `testDrawTwoAppliesPenaltyAndSkips` | Draw Two card played. Next player receives +2 cards from the draw pile. Next player's turn is skipped. Turn passes to the player after. |
| `testDrawFourAppliesPenaltyChangesColourAndSkips` | Draw Four Wild played. Player chooses colour. Next player receives +4 cards. Next player is skipped. Active colour set to chosen colour. |
| `testDiscardAllRemovesMatchingColourFromHand` | Discard All card played (colour: Cobalt). Player's entire hand is searched; all Cobalt cards are discarded. Non-Cobalt cards remain. |
| `testForcedSwapExchangesCompleteHands` | Forced Swap card played. Player 0 chooses player 2 as swap target. Player 0's full hand is transferred to player 2 and vice versa. Hand sizes swap correctly. |
| `testTargetedDrawAppliesTwoCardPenaltyToTarget` | Targeted Draw played. Player 1 is chosen as target. Player 1 draws 2 cards. Player 1's turn is skipped. Other players unaffected. |
| `testTeamPlayBonusDrawForBothPartners` | Team Play card played. Both partners of the playing team draw 1 bonus card each. Opponents do not draw. |
| `testResuffleWhenDrawPileEmpty` | Draw pile has 0 cards. Player action requires a draw. Engine reshuffles discard pile (except top card) to form new draw pile. Draw proceeds without error. |
| `testSoloCallResetsPenaltyFlag` | Player reaches 1 card in hand. Player calls Solo!. `soloCallState.calledSolo` flag is set to true. No penalty is applied. |
| `testSoloPenaltyAppliedWhenCaughtByOpponent` | Player reaches 1 card in hand but does not call Solo!. Opponent calls the catch. Penalised player draws 2 cards. `soloCallState.caughtWithoutCall` flag is set. |
| `testTeamWinsOnlyWhenBothPlayersEmpty` | Standard Teams: Player 0 plays last card. Win condition check: player 0's partner (player 3) still has cards. No win declared. Turn continues. |
| `testPlayerGoesOutButPartnerStillHasCards` | Extension of above. Player 0 plays last card. Partner has 3 cards remaining. Engine continues. Partner eventually plays last card. Win declared for team. |
| `testAllWildModeEveryCardPlayable` | All-Wild Teams mode: deck contains only Wild cards (mode rule). Every card in hand is playable on every turn. No "no valid card" state occurs. |
| `testSideToSideTeamPassSwapsSingleCard` | Side-to-Side Teams mode: Team Pass action. Player 0 passes one card (chosen) to their partner player 3. Player 3's hand increases by 1. Player 0's hand decreases by 1. |
| `testSaveAndResumeAfterColourChoicePending` | Game state serialised while in `pendingColourChoice` state. State deserialised. Engine correctly presents colour picker. Player chooses colour. Game continues normally. |
| `testSaveAndResumeAfterTargetChoicePending` | Game state serialised while in `pendingTargetChoice` state. State deserialised. Engine correctly presents target picker. Player chooses target. Game continues normally. |
| `testCorruptedSaveHandledGracefully` | `PersistenceService.loadGame()` is given a malformed JSON string. No crash occurs. Service returns `.failure(.decodingError(...))`. App presents new game option. |
| `testAINeverMakesIllegalMove` | `GameSimulator` runs 1,000 Easy games (seeded 0–999). For each game, every AI move is validated against `GameRules.validMoves(for:state:)`. Assert `illegalMoveAttempts == 0` across all games. |
| `testAIObservationNeverExposesForbiddenFields` | For every AI turn in 100 games: extract the `AIObservation` passed to the AI. Assert `observation.opponentHands == nil` (or equivalent masked representation). Assert `observation.drawPileContents == nil`. |
| `testNoStuckGamesIn100Games` | `GameSimulator` runs 100 games per difficulty (400 total). Each game must complete within 300 turns. Assert `result.stuck == false` and `result.turns <= 300` for all runs. |

---

## 6. UI Test Plan

UI tests are implemented using `XCUITest` and run against the iPhone 15 simulator (primary) and iPad Air simulator (secondary). They are added in Phase 5 of the project.

### Scope policy

UI tests cover only journeys that:
- Cannot be tested at the unit/scenario level, AND
- Represent a critical failure mode if broken (e.g. the game cannot be started or a card cannot be played)

UI tests do not cover visual styling, animation quality, or accessibility — these are covered by manual scripts.

### UI test scenarios

| ID | Journey | Simulator | Priority |
|---|---|---|---|
| UIT-01 | App launches to home screen | iPhone 15 | Critical |
| UIT-02 | App launches to home screen | iPad Air | Critical |
| UIT-03 | Start a Standard Teams game (4 players, Easy) | iPhone 15 | Critical |
| UIT-04 | Select and play a valid card | iPhone 15 | Critical |
| UIT-05 | Attempt to play an invalid card — shake animation fires, no card played | iPhone 15 | High |
| UIT-06 | Draw a card when no playable card is available | iPhone 15 | High |
| UIT-07 | Choose a colour after playing a Wild card | iPhone 15 | High |
| UIT-08 | Choose a target after playing a Targeted Draw card | iPhone 15 | High |
| UIT-09 | Pause game → resume game — state preserved | iPhone 15 | High |
| UIT-10 | Open rules overlay from game table | iPhone 15 | Medium |
| UIT-11 | Navigate to Settings → toggle Large Cards setting | iPhone 15 | Medium |
| UIT-12 | Background app → relaunch → confirm resume prompt appears | iPhone 15 | High |

### Accessibility identifier conventions

All interactive UI elements must have accessibility identifiers set for XCUITest targeting:

```swift
// Convention: lowercase-hyphenated, descriptive
Button("Draw Card") { ... }
    .accessibilityIdentifier("game-draw-card-button")

ForEach(cards) { card in
    CardView(card: card)
        .accessibilityIdentifier("hand-card-\(card.id)")
}
```

---

## 7. Simulation Test Design

### File location

`WildPairsCore/Tests/WildPairsCoreTests/BalanceSimulationTests.swift`

### Architecture

```
BalanceSimulationTests
  └── GameSimulator
        ├── Initialises full game state (no UI)
        ├── Runs AI turns until win condition or turn limit
        ├── Records: winner, turn count, illegal move count, stuck flag
        └── Returns SimulationResult
```

`GameSimulator` uses `GameEngine.reduce()` directly. It uses `SeededRNG` so results are deterministic per seed.

### Suites

| Suite | Games per pairing | Seeds | Trigger |
|---|---|---|---|
| Smoke | 100 | 0–99 | Pre-commit / `swift test` |
| Balance | 1,000 | 0–999 | Phase gate only |

"Per pairing" means: Easy vs Easy, Medium vs Easy, Hard vs Easy, Expert vs Easy (human team vs AI team at given difficulty).

### Acceptance criteria

| Metric | Threshold | Notes |
|---|---|---|
| Illegal AI moves | 0 in all games | Absolute requirement |
| Stuck games (> 300 turns) | 0 in all games | Absolute requirement |
| Expert win rate vs Easy | ≥ 60% | Balance requirement |
| Hard win rate vs Easy | ≥ 55% | Balance requirement |
| Medium win rate vs Easy | 45–55% | Near-parity expected |
| Average turns to completion | 40–120 | Games outside range indicate rules issue |

### Performance target

The smoke suite (100 games × 4 pairings = 400 games) must complete in under 30 seconds on a standard MacBook. If it takes longer, optimise `GameSimulator` (avoid unnecessary copies, prefer value-type mutations).

---

## 8. Manual Test Scripts

Full scripts are in `docs/manual-test-scripts.md`. The manual test suite covers:

### Device and layout tests

- iPhone SE (smallest supported) — verify no truncation, no overlap
- Large iPhone (Pro Max) — verify layout uses space well
- iPad mini — verify tablet layout
- iPad portrait — verify two-panel or expanded layout
- iPad landscape — verify orientation-specific layout
- iPad Split View narrow — verify compact-width layout
- App rotation during game — verify state preserved

### Accessibility tests

- VoiceOver — full game navigation (all interactive elements reachable and labelled)
- VoiceOver — hear game status on demand (current turn, hand contents, discard pile)
- Dynamic Type AX3 — all text readable without truncation
- Large card mode — all card text readable
- Colour-blind mode — no information conveyed by colour alone
- Reduced motion — all state changes legible (no animation-dependent feedback)

### Save / resume tests

- Background app → relaunch → confirm resume
- Force-quit → relaunch → confirm resume
- Resume after colour choice pending
- Resume after target choice pending
- Resume with corrupted save (manually corrupt JSON)

### Gameplay mode tests

- Standard Teams full round
- All-Wild Teams full round
- Side-to-Side Teams full round with team pass

### Permission verification test

- Play full game → confirm zero permission prompts

### Data tests

- Reset all data → confirm files deleted → confirm stats zeroed

---

## 9. Test Environment Setup (macOS)

### Running Swift Package tests

```bash
# Navigate to repo root (where Package.swift is)
cd ~/Developer/WildPairs

# Run all tests (unit + scenario + simulation smoke suite)
swift test --package-path .

# Run with verbose output (shows individual @Test names)
swift test --package-path . --verbose

# Run only a specific test suite
swift test --package-path . --filter WildPairsCoreTests

# Run a single test by name
swift test --package-path . --filter "testHumanHasNoValidCardMustDraw"

# Run with code coverage (requires xcodebuild)
xcodebuild test \
  -scheme WildPairs \
  -project WildPairsApp/WildPairsApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -enableCodeCoverage YES
```

### Viewing code coverage

After running with `-enableCodeCoverage YES`:

1. Open Xcode → open the `.xcresult` bundle from DerivedData.
2. View the Coverage tab.
3. Or use `xcrun xccov view --report <path-to.xcresult>` for command-line output.

### Continuous integration

Tests run via `swift test` on macOS GitHub Actions runner (or equivalent). The workflow runs:

1. `swift build` — confirm package builds
2. `swift test --package-path . --filter "(?!BalanceSimulation)"` — all tests except slow balance suite
3. Report results

Balance simulation tests are excluded from CI and run manually at phase gates.

---

## 10. What Cannot Be Tested Automatically

The following must be tested manually using the scripts in `docs/manual-test-scripts.md`:

| What | Why automation cannot cover it |
|---|---|
| Visual appearance and layout quality | XCUITest can take screenshots but cannot assess visual quality |
| VoiceOver navigation feel | Automation can confirm elements are reachable but not that the experience is coherent |
| Haptic feedback | Simulator does not produce haptics; physical device only |
| Animation smoothness | Automation can verify state changes but not 60fps animation quality |
| One-handed reachability on physical device | Simulator does not model thumb reach zones |
| Physical device save/resume after memory pressure | Cannot reliably reproduce OS memory pressure in simulator |
| Colour-blind mode legibility | Automation cannot assess perceptual legibility |
| Dynamic Type at extreme sizes | Automation can check text is present but not that it is readable |
| Card text readability in large card mode | Visual quality check only |
| First-launch onboarding comprehension | Requires a human to judge whether a new player understands the rules |

---

## 11. Test File Locations

```
WildPairs/
├── Package.swift
└── WildPairsCore/
    └── Tests/
        └── WildPairsCoreTests/
            ├── UnitTests/
            │   ├── DeckTests.swift
            │   ├── CardDefinitionTests.swift
            │   ├── ValidMoveTests.swift
            │   ├── CardEffectTests.swift
            │   ├── WinConditionTests.swift
            │   ├── PersistenceTests.swift
            │   └── AIConstraintTests.swift
            ├── ScenarioTests.swift
            └── BalanceSimulationTests.swift
```

UI tests are in the Xcode project:

```
WildPairs/WildPairsApp/
└── WildPairsAppTests/
    └── UITests/
        └── CriticalJourneyUITests.swift
```
