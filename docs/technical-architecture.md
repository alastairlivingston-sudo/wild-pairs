# Wild Pairs — Technical Architecture

> *Canonical sources: this document is authoritative for data models (§Model Reference) and technical design. For game rules and rule defaults, `game-rules.md` is canonical. For visual tokens, `design-system.md`. Where any other document disagrees with §Model Reference, this document wins.*

## TL;DR

Wild Pairs is a Universal iOS/iPadOS card game built on a strict separation between pure game logic (the `WildPairsCore` Swift Package) and the SwiftUI presentation layer (`WildPairsApp`). The game engine is a single pure reducer function — `(GameState, GameAction) -> (GameState, [GameEffect])` — that contains no UI dependencies, no network calls, and no side effects. All randomness flows through a seeded RNG so that every game can be replayed deterministically and every test produces identical results. ViewModels bridge the two worlds: they dispatch actions into the engine, publish new state to SwiftUI views, and process returned effects (animations, haptics, audio) without any of that logic leaking back into the engine.

---

## 1. Module Boundaries

### WildPairsCore (Swift Package — library target)

Contains everything that has no dependency on UIKit, SwiftUI, or any Apple UI framework:

- All model types: `Card`, `Deck`, `Player`, `GameState`, `GameAction`, `GameEffect`, `RuleProfile`, `SeededRNG`
- `GameEngine` — the pure reducer
- All AI implementations: `AIObservation`, `AIPlayer`, `EasyAI`, `MediumAI`, `HardAI`, `ExpertAI`
- `GameSimulator` — headless simulation runner
- `GameSnapshot` — Codable persistence envelope
- `EventLog` — debug-only event recorder
- Utility types: `CardFactory`, `GameStateBuilder` (used by tests too)

**Dependency rule:** WildPairsCore may import only `Foundation`. It must never import `SwiftUI`, `UIKit`, `AVFoundation`, `CoreHaptics`, or any other UI/media framework.

### WildPairsApp (Xcode app target)

Contains everything that depends on UI frameworks:

- All SwiftUI Views (game board, player hands, settings, onboarding)
- All ViewModels (`GameViewModel`, `SettingsViewModel`, `OnboardingViewModel`)
- App entry point (`WildPairsApp.swift`)
- Asset catalogs, localisation strings
- Haptic and sound effect coordinators
- Animation coordinators that consume `[GameEffect]` returned by the engine
- Adaptive layout containers and size-class helpers

**Depends on:** `WildPairsCore` (as a local Swift Package dependency).

### WildPairsTests (test target inside Swift Package)

Contains all unit and integration tests for game logic:

- Engine correctness tests (`GameEngineTests`)
- Deck and dealing tests (`DeckTests`)
- Rule validation tests (`RuleProfileTests`)
- AI behaviour tests (`AIPlayerTests`)
- Persistence round-trip tests (`GameSnapshotTests`)
- Simulation smoke tests (`GameSimulatorTests`)

**Depends on:** `WildPairsCore` only. Uses `XCTest` or Swift Testing (`import Testing`). Never imports UI frameworks.

### WildPairsUITests (Xcode UI test target)

Contains XCUITest scenarios:

- Full game flow end-to-end via UI (start game, play cards, win)
- Accessibility label verification
- iPad layout assertions

**Depends on:** `WildPairsApp` via XCUIApplication. Does not import `WildPairsCore` directly.

### Dependency Direction

```
WildPairsUITests → WildPairsApp → WildPairsCore
WildPairsTests             → WildPairsCore
```

No arrows go the other way. `WildPairsCore` depends on nothing except Foundation.

---

## 2. Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                          SwiftUI View                            │
│                                                                  │
│   User taps "Play Card" button                                   │
│   → view calls viewModel.play(card: card)                        │
└───────────────────┬──────────────────────────────────────────────┘
                    │ GameAction.playCard(card, playerID)
                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                        GameViewModel                             │
│                                                                  │
│   func dispatch(_ action: GameAction) {                          │
│       let (newState, effects) =                                  │
│           GameEngine.reduce(state: state, action: action)        │
│       self.state = newState          ← @Published triggers View  │
│       self.process(effects)          ← animation / haptic / sfx  │
│       autosave(newState)             ← persistence side effect   │
│   }                                                              │
└───────────┬────────────────────────┬─────────────────────────────┘
            │                        │
            ▼                        ▼
┌───────────────────┐    ┌───────────────────────────────┐
│   GameEngine      │    │   Effect Processors            │
│                   │    │                                │
│  pure reduce()    │    │  AnimationCoordinator          │
│  no side effects  │    │  HapticCoordinator             │
│  returns newState │    │  SoundCoordinator              │
│  + [GameEffect]   │    │  AccessibilityAnnouncer        │
└───────────────────┘    └───────────────────────────────┘
            │
            ▼
┌──────────────────────────────────────────────────────────────────┐
│                        @Published state                          │
│                                                                  │
│   GameViewModel.state: GameState                                 │
│   ↓ (Combine / SwiftUI observation)                              │
│   All subscribed Views re-render with new state                  │
└──────────────────────────────────────────────────────────────────┘
```

---

## 3. GameEngine Design

### Signature

```swift
struct GameEngine {
    static func reduce(state: GameState, action: GameAction) -> (GameState, [GameEffect])
}
```

### Why No Side Effects in the Engine

The engine is a pure function: given the same `GameState` and `GameAction`, it always produces the same output. This means:

- **Testability:** Tests call `reduce` directly without mocking anything. The output is fully deterministic.
- **Reproducibility:** Any game can be replayed from its initial seed by feeding the same sequence of actions.
- **Separation of concerns:** The engine does not know how to play sounds, trigger haptics, or update the screen. These concerns belong to the platform.
- **Thread safety:** A pure function with value-type inputs and outputs is inherently thread-safe.

### How Effects Are Returned and Processed

`GameEffect` is a value-type enum returned in an array alongside the new state. The ViewModel receives this array and dispatches each effect to the appropriate coordinator:

```swift
// In GameViewModel
private func process(_ effects: [GameEffect]) {
    for effect in effects {
        switch effect {
        case .animateCardPlay(let card, let from, let to):
            animationCoordinator.animate(card: card, from: from, to: to)
        case .triggerHaptic(let style):
            hapticCoordinator.trigger(style)
        case .announceSolo(let playerName):
            accessibilityAnnouncer.announce("\(playerName) — Solo!")
        // ...
        }
    }
}
```

The engine never knows whether effects are actually executed. In tests, effects are simply inspected as values.

---

## 4. GameState Design

`GameState` is a pure value type (`struct`) conforming to `Codable`, `Equatable`, and `Sendable`. Every field is derived exclusively from actions — there is no mutable global state.

| Field | Type | Description |
|---|---|---|
| `schemaVersion` | `Int` | Always 1 for current schema; used for migration |
| `players` | `[Player]` | Ordered array of all players (0–3), seat order preserved |
| `currentPlayerIndex` | `Int` | Index into `players` for the active player |
| `turnDirection` | `TurnDirection` | `.clockwise` or `.counterClockwise` |
| `deck` | `Deck` | Draw pile + discard pile |
| `currentColour` | `CardColour` | Active colour constraint |
| `currentCardType` | `CardType?` | Nil after a colour card resolves |
| `pendingDecision` | `PendingDecision?` | Non-nil when waiting for player input (colour choice, target choice, team pass) |
| `phase` | `GamePhase` | `.dealing`, `.playing`, `.roundEnded`, `.gameEnded` |
| `mode` | `GameMode` | `.standardTeams`, `.allWild`, `.sideToSide` |
| `ruleProfile` | `RuleProfile` | Full rule configuration for current game |
| `roundNumber` | `Int` | 1-based round counter |
| `teamScores` | `[TeamID: Int]` | Cumulative scores per team |
| `rngSeed` | `UInt64` | Seed used for this game's RNG; saved in snapshot |
| `actionCount` | `Int` | Total actions dispatched; used to reconstruct RNG state |
| `eventLog` | `[GameEvent]` | Debug-only; capped at 100 entries; excluded from Equatable |
| `winState` | `WinState?` | Nil during play; populated when game ends |

---

## 5. GameAction Design

`GameAction` is a value-type enum covering every possible player or system input that can change state:

```swift
enum GameAction: Codable, Equatable, Sendable {
    // Normal play
    case playCard(Card, playerID: UUID)
    case drawCard(playerID: UUID)
    case passTurn(playerID: UUID)

    // Decisions after action cards
    case selectColour(CardColour, playerID: UUID)
    case selectTarget(targetPlayerID: UUID, playerID: UUID)

    // Team mode
    case teamPass(playerID: UUID)

    // Solo call
    case callSolo(playerID: UUID)

    // Game control
    case pauseGame
    case resumeGame
    case newGame(config: GameConfig)
    case restoreSnapshot(GameSnapshot)

    // System / AI
    case aiMove(GameAction, playerID: UUID)
    case advancePendingDecision

    // Debug / testing
    case forceState(GameState)   // debug builds only
}
```

All cases are `Codable` so that action sequences can be recorded and replayed.

---

## 6. GameEffect Design

`GameEffect` describes a side effect that the engine requests but does not perform. All cases are value types with no closures.

```swift
enum GameEffect: Equatable, Sendable {
    // Card animations
    case animateCardPlay(card: Card, fromPlayerID: UUID, toDiscard: Bool)
    case animateCardDraw(toPlayerID: UUID, count: Int)
    case animateCardShuffle
    case animateDeckEmpty

    // Turn flow
    case animateSkip(playerID: UUID)
    case animateReverse
    case animateSkipTwo(playerID: UUID)

    // Wild card resolution
    case promptColourChoice(playerID: UUID)
    case promptTargetChoice(playerID: UUID, validTargets: [UUID])

    // Solo call
    case announceSolo(playerName: String)
    case soloCallMissed(playerName: String) // penalty applied

    // Round/game end
    case playRoundEnd(winningTeam: TeamID)
    case playGameEnd(winningTeam: TeamID)

    // Haptics
    case triggerHaptic(HapticStyle)

    // Sound
    case playSound(SoundEffect)

    // Accessibility
    case accessibilityAnnounce(String)

    // AI
    case scheduleAIMove(playerID: UUID, delay: TimeInterval)
}
```

---

## 7. RuleProfile Design

`RuleProfile` captures every configurable rule so the engine never hard-codes mode-specific logic. The engine always reads from the rule profile, never from the game mode directly.

```swift
struct RuleProfile: Codable, Equatable, Sendable {
    // Win condition
    var winCondition: WinCondition          // .bothTeammatesOut or .singleOut
    var targetScore: Int                    // points to win (0 = single round)

    // Draw rules
    var mustPlayAfterDraw: Bool
    var drawUntilPlayable: Bool
    var stackDrawCards: Bool                // allow stacking draw-two / draw-four

    // Wild card rules
    var drawFourChallengeable: Bool
    var changeColourRequiresPlay: Bool

    // Special card enables
    var discardAllEnabled: Bool
    var targetedDrawEnabled: Bool
    var forcedSwapEnabled: Bool
    var skipTwoEnabled: Bool
    var teamPlayEnabled: Bool

    // Card set
    var cardSet: CardSet                    // .beginner, .standard, .advanced

    // Hand size
    var initialHandSize: Int               // 7 for standard

    // Team pass
    var teamPassEnabled: Bool
    var teamPassCooldown: Int              // turns between passes

    // Solo call
    var soloCallEnabled: Bool
    var soloCallPenaltyCards: Int          // cards drawn if call missed

    // Solo call
    var soloCallTimeoutSeconds: Double      // 5.0 in all factory defaults

    // Scoring
    var scoringEnabled: Bool
    var maxTurnsPerRound: Int              // 300 — stuck-game safety cap

    // Team Play house-rule variant
    var partnerPlaysImmediately: Bool      // false in all factory defaults

    // Factory methods — see game-rules.md §RuleProfile Factory Defaults for exact field values
    static func standardTeams() -> RuleProfile
    static func allWild() -> RuleProfile
    static func sideToSide() -> RuleProfile
}
```

**Validation:** A `validate() throws` method checks for contradictory rule combinations (e.g., `drawUntilPlayable && mustPlayAfterDraw` are compatible but `stackDrawCards && !drawUntilPlayable` needs a cap) before any game starts.

---

## 8. SeededRNG Design

```swift
struct SeededRNG: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) {
        // splitmix64 initialisation: mix the seed so that seed 0 produces
        // a non-degenerate sequence (unlike xorshift64, which returns 0 forever at state 0).
        self.state = seed &+ 0x9e3779b97f4a7c15
        _ = next()  // advance once to spread the mixed seed
    }
    mutating func next() -> UInt64 {
        // splitmix64
        state = state &+ 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
```

**Algorithm: splitmix64.** This is the canonical RNG for Wild Pairs. Both `technical-architecture.md` (here) and `testing-strategy.md` §4 must show byte-identical implementations.

- Single 64-bit state, extremely fast, good statistical properties, easy to serialise.
- Produces a well-distributed sequence from **any** seed, including 0.
- Seed is stored in `GameState.rngSeed` and saved in `GameSnapshot`, allowing any saved game to resume with identical random draws.

**Why not xorshift64:** xorshift64 has state = 0 as a fixed point (returns 0 forever), which silently corrupts seed-0 simulations. splitmix64 has no such fixed point.

**Production:** The seed is generated from `SystemRandomNumberGenerator` at game start.

**Tests:** Tests construct `SeededRNG(seed: 42)` (or any fixed value). `SeededRNGTests` must include: (a) two generators with the same seed produce identical sequences; (b) `SeededRNG(seed: 0).next()` produces a non-zero, non-constant sequence.

**RNG threading through engine:** The engine takes `var rng` as an `inout` parameter on internal methods. Because `GameState` contains the seed but not the live RNG, the ViewModel reconstructs the RNG at the correct point using `actionCount` to fast-forward from the seed. For simplicity in Phase 2, the RNG is advanced by replaying the required number of `next()` calls.

---

## 9. AIObservation Design

`AIObservation` is constructed from `GameState` by filtering out everything the AI is not allowed to see. It is the only input an AI implementation receives.

### Visible Fields

| Field | Rationale |
|---|---|
| `discardPile: [Card]` | Public information — all players can see the discard |
| `currentColour: CardColour` | Public — determines legal plays |
| `currentCardType: CardType?` | Public — determines pending effect |
| `cardCounts: [PlayerID: Int]` | Public — hand *sizes* are visible (not contents) |
| `playedCardHistory: [Card]` | Public — cards that have been discarded this round |
| `teamState: TeamState` | Public — who is on whose team |
| `myHand: [Card]` | Private — only the AI's own hand is included |
| `activePlayerID: PlayerID` | Public — whose turn it is |
| `isMyTurn: Bool` | Convenience derived from above |
| `turnDirection: TurnDirection` | Public — affects skip/reverse predictions |
| `ruleProfile: RuleProfile` | Public — AI must know the rules |
| `roundNumber: Int` | Public — context for scoring |
| `teamScores: [TeamID: Int]` | Public — scoreboard is visible |

### Excluded Fields

- Opponent hands (contents, not just count) — **never exposed**
- Partner hand contents — **never exposed**
- The internal RNG state — **never exposed**
- Pending decisions of other players — exposed only to the relevant player

---

## 10. Persistence Design

### File Paths

Files live in the app's **Documents** directory — the canonical location used by `privacy-offline-plan.md`, `permission-audit.md`, and the `DataResetService`. Not `Application Support`.

```
<Documents>/wildpairs-game.json       ← autosave slot (current game)
<Documents>/wildpairs-settings.json  ← user preferences
<Documents>/wildpairs-stats.json     ← local statistics
```

Swift:
```swift
let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let gameURL      = dir.appendingPathComponent("wildpairs-game.json")
let settingsURL  = dir.appendingPathComponent("wildpairs-settings.json")
let statsURL     = dir.appendingPathComponent("wildpairs-stats.json")
```

`DataResetService` deletes exactly these three files and no others. Tests for reset must assert deletion of these exact paths.

### GameSnapshot Envelope

```swift
struct GameSnapshot: Codable {
    let schemaVersion: Int          // must match GameState.schemaVersion; current = 1
    let savedAt: Date
    let buildVersion: String        // CFBundleShortVersionString at save time
    let state: GameState
}
```

### Migration Strategy

When loading a snapshot whose `schemaVersion` is less than the current version, a chain of migration functions is applied:

```swift
func migrate(snapshot: GameSnapshot) throws -> GameSnapshot {
    var s = snapshot
    if s.schemaVersion < 2 { s = migrateV1toV2(s) }
    if s.schemaVersion < 3 { s = migrateV2toV3(s) }
    return s
}
```

Migrations live in `WildPairsCore/Persistence/Migrations/`. Each migration is tested independently.

### Autosave Trigger Points

- After every `reduce` call that changes phase (dealing complete, card played, round ended)
- On `applicationDidEnterBackground` notification (via ViewModel)
- On `sceneWillDeactivate` for iPad multi-scene support

### Corrupted Save Recovery

On decode failure, the ViewModel:
1. Logs the error (debug builds only)
2. Moves the corrupted file to `saves/corrupted_<timestamp>.json` for potential diagnostics
3. Presents a "Saved game could not be loaded — Start new game?" alert
4. Does not crash

---

## 11. MVVM Layer Design

### GameViewModel Responsibilities

```swift
@MainActor
class GameViewModel: ObservableObject {
    @Published private(set) var state: GameState
    @Published private(set) var pendingEffects: [GameEffect] = []

    func dispatch(_ action: GameAction)          // calls engine, updates state, processes effects
    func save()                                  // triggers persistence
    func restore() async throws                  // loads snapshot, validates, sets state
    func scheduleAITurn(for playerID: UUID)      // delays then calls AI, dispatches result
}
```

### What ViewModels Adapt for Display

ViewModels transform raw `GameState` into display-friendly derived values:

- `var currentPlayerName: String` — looks up player by index
- `var isLocalPlayerTurn: Bool` — checks active player against local player IDs
- `var validMoves: [Card]` — filters own hand for legal plays
- `var soloButtonVisible: Bool` — checks hand count and rule profile
- `var scoreboardRows: [ScoreboardRow]` — maps team scores to display model

Views never compute these themselves. Views only read `@Published` properties and call ViewModel methods.

### Why Direct Engine Mutation from View is Prohibited

Views must not call `GameEngine.reduce` directly because:

1. Effect processing (animation, sound, haptics) would be skipped
2. Autosave would not trigger
3. AI scheduling would not trigger
4. The action sequence log would be incomplete
5. It violates the single-source-of-truth principle

All mutations flow through `GameViewModel.dispatch`.

---

## 12. Adaptive Layout Architecture

### Size Class Strategy

The app uses `horizontalSizeClass` and `verticalSizeClass` from the SwiftUI environment to select layout containers:

| Device / Orientation | hSizeClass | vSizeClass | Layout |
|---|---|---|---|
| iPhone portrait | compact | regular | `CompactPortraitLayout` |
| iPhone landscape | compact | compact | `CompactLandscapeLayout` |
| iPad portrait | regular | regular | `RegularPortraitLayout` |
| iPad landscape | regular | regular | `RegularLandscapeLayout` |
| iPad Split View | compact | regular | falls back to `CompactPortraitLayout` |

### Why Separate Layout Compositions

Simple scaling (`.scaleEffect`) is insufficient because:

- Card hand arrangements need to change from a bottom-arc (iPhone) to a side-column (iPad) — different geometry, not just size
- The discard/draw area moves from the vertical centre on iPhone to the horizontal centre on iPad
- Player labels and score overlays need repositioning, not just scaling
- iPad should show more information density, not just bigger elements

Each layout container is a SwiftUI `View` that arranges its children differently based on the size class. The game state passed in is identical; only the arrangement changes.

---

## 13. Error Handling Strategy

### Recoverable Errors

| Situation | Recovery |
|---|---|
| Corrupted save file | Move aside, prompt user to start new game |
| Illegal action dispatched (wrong player, invalid card) | Engine returns current state unchanged + `.accessibilityAnnounce("Invalid move")` |
| Deck exhausted (reshuffle fails) | Engine reshuffles discard into draw pile; if still empty, round ends |
| AI returns no valid move | Engine forces a draw action |

### Unrecoverable Errors (Debug Only)

In `#if DEBUG` builds, `assert` and `precondition` are used for invariant violations (e.g., `playerIndex out of bounds`, `pendingDecision inconsistency`). These crash immediately in development so bugs surface during testing.

In production builds, the same code paths log the inconsistency via `EventLog`, attempt a graceful state correction (e.g., skip to next player), and continue. The game should never crash in production.

---

## 14. Logging Strategy

- All logging uses `EventLog` — a struct that appends `GameEvent` values to a capped array inside `GameState`.
- `EventLog` is active only in `#if DEBUG` builds; in production the methods are no-ops compiled away.
- No `print` statements in production code.
- No `os.log`, `OSLog`, or `Logger` usage — no system log pollution.
- No remote logging, crash reporting, or analytics of any kind. The app is fully offline.
- The event log is included in `GameSnapshot` in debug builds to aid diagnostics but is stripped from release snapshots.

---

## 15. Testing Architecture

### Determinism via SeededRNG

Every test that involves shuffling or drawing constructs a `SeededRNG(seed: <fixed value>)`. The seed is documented in the test as part of the test fixture description. This means CI always produces identical results regardless of machine or date.

### GameStateBuilder

`GameStateBuilder` is a fluent builder in `WildPairsCore` (available to tests) that constructs arbitrary `GameState` values for testing:

```swift
let state = GameStateBuilder()
    .withPlayers(4)
    .withMode(.standardTeams)
    .withHand(playerIndex: 0, cards: [CardFactory.red5, CardFactory.blueReverse])
    .withCurrentColour(.crimson)
    .build()
```

### CardFactory

`CardFactory` provides static convenience properties for common cards:

```swift
CardFactory.crimson5    // number card, crimson, value 5
CardFactory.wildDraw4   // draw four wild
CardFactory.cobaltSkip  // skip, cobalt colour
```

### Testing the Real Engine

Tests never mock `GameEngine`. They call `GameEngine.reduce(state:action:)` directly and assert on the returned state and effects. This ensures tests cover real behaviour, not mock behaviour.

### No UI in Tests

`WildPairsTests` never imports SwiftUI or UIKit. All assertions are on `GameState` and `[GameEffect]` values.

---

## 16. Build Phases

| Phase | Focus | Deliverables |
|---|---|---|
| Phase 2 | Swift Package + core engine | Package.swift, all model types, GameEngine skeleton, SeededRNG, basic deck tests |
| Phase 3 | Full rules implementation | All card effects, turn management, win detection, RuleProfile validation, complete test coverage |
| Phase 4 | AI implementation | All four AI difficulty levels, AIObservation, GameSimulator, balancing tests |
| Phase 5 | SwiftUI app + Xcode project | Xcode project, all views, ViewModels, persistence, adaptive layouts |
| Phase 6 | UX polish | Animations, haptics, sound, accessibility labels, onboarding |
| Phase 7 | QA | Full test pass, performance profiling, memory leak checks, TestFlight build |

---

## 17. Dependency List

**Zero external (third-party) dependencies.**

### Apple Frameworks Used

| Framework | Module | Usage |
|---|---|---|
| `Foundation` | WildPairsCore | UUID, Date, FileManager, JSONEncoder/Decoder, Codable |
| `SwiftUI` | WildPairsApp | All UI rendering and layout |
| `Combine` | WildPairsApp | `@Published` observation (via SwiftUI's ObservableObject) |
| `CoreHaptics` | WildPairsApp | Haptic feedback patterns |
| `AVFoundation` | WildPairsApp | Sound effect playback |
| `XCTest` | WildPairsTests | Unit test infrastructure |
| `Testing` | WildPairsTests | Swift Testing framework (Swift 5.9+) |
| `XCTest` (UI) | WildPairsUITests | UI automation |

### Why No Third-Party Frameworks

- **Security:** Fewer dependencies means smaller attack surface.
- **Longevity:** Third-party packages become unmaintained; Apple frameworks are supported indefinitely.
- **App Review:** No risk of rejection due to SDK policy violations in a dependency.
- **Offline-first:** No package resolution needed after initial clone.
- **Simplicity:** The game logic is straightforward enough that no external libraries provide meaningful value over Foundation + SwiftUI.

---

## 18. Model Reference

**This section is the single canonical source of truth for all data model types.** Every other document that describes a model type defers to this section. Where any other document disagrees with this section, this section wins.

### CardColour

```swift
enum CardColour: String, Codable, Equatable, Sendable, CaseIterable {
    case crimson
    case cobalt
    case jade
    case amber
}
```

- Exactly **four cases**. There is no `.wild` case.
- Wild cards (Change Colour, Draw Four, Discard All) have `colour: CardColour? = nil` on the `Card` struct.
- `GameState.currentColour: CardColour` is never nil — there is always an active colour constraint.
- `CardColour.allCases` (from `CaseIterable`) provides all four colours; use this wherever the code previously referenced `CardColour.nonWild`.

### CardType

```swift
enum CardType: Codable, Equatable, Sendable {
    case number(Int)        // associated value: 0–9
    case skip
    case reverse
    case drawTwo
    case drawFour
    case changeColour
    case discardAll
    case targetedDraw
    case forcedSwap
    case skipTwo
    case teamPlay
}
```

Exactly **11 cases**. Every `switch` on `CardType` must be exhaustive across all 11.

- `number(Int)` carries the face value (0–9). `Card(.number(5), .cobalt)` is a cobalt 5.
- `forcedSwap` is a **coloured action card** (not wild): it has a `CardColour` and matches by colour or type. Its `Card.colour` is non-nil.
- `discardAll` is a **wild-type card**: `Card.colour == nil`.

### Card

```swift
struct Card: Codable, Equatable, Sendable, Identifiable {
    let id: UUID
    let type: CardType
    let colour: CardColour?   // nil for wild-type cards (changeColour, drawFour, discardAll)
    
    var isWild: Bool { colour == nil }
}
```

### GameState — Seat and Team Model

```
Seat 0: Human player      → Team A
Seat 1: Left Opponent     → Team B
Seat 2: AI Partner        → Team A
Seat 3: Right Opponent    → Team B
```

- `GameState.players: [Player]` is always 4 elements, indexed 0–3 in seat order.
- `GameState.teams: [[Int]]` = `[[0, 2], [1, 3]]` for all three game modes.
- The seating is **identical in all modes**. "Side-to-Side" refers to the card-passing mechanic, not a different seat geometry.
- `GameStateBuilder` test fixtures must use `.withTeams([[0, 2], [1, 3]])`.

### GameSnapshot — Schema

```swift
struct GameSnapshot: Codable {
    let schemaVersion: Int      // current = 1
    let savedAt: Date
    let buildVersion: String    // CFBundleShortVersionString
    let state: GameState
}
```

### Persistence Paths

```
<Documents>/wildpairs-game.json       ← autosave
<Documents>/wildpairs-settings.json  ← user preferences
<Documents>/wildpairs-stats.json     ← local statistics
```

`DataResetService` deletes exactly these three files.

### RuleProfile Factory Defaults

See `game-rules.md` §RuleProfile Factory Defaults for the complete field-by-field table. Key values:

| Field | Default (all factories) |
|---|---|
| `initialHandSize` | 7 |
| `soloCallEnabled` | `true` |
| `soloCallPenaltyCards` | 2 |
| `soloCallTimeoutSeconds` | 5.0 |
| `maxTurnsPerRound` | 300 |
| `teamPassEnabled` | `false` (except `sideToSide()` → `true`) |

### Stuck-Game Turn Limit

**300 turns per round.** This constant (`RuleProfile.maxTurnsPerRound`) is referenced by `game-rules.md`, `testing-strategy.md`, `premortem.md`, and this document. The value in `ai-strategy.md` §12 was 1000 and has been corrected to 300.
