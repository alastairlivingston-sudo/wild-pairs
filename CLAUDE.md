# Wild Pairs — CLAUDE.md

## Identity
| Key | Value |
|---|---|
| Working title | Wild Pairs |
| Type | Offline Universal iOS/iPadOS card game |
| Target platform | iPhone + iPad (Universal), iOS 17+, offline-only |
| Language | Swift 5.9+ |
| UI framework | SwiftUI |
| Test frameworks | Swift Testing (logic), XCTest/XCUITest (UI) |
| Primary user | Personal use; App Store–quality codebase |

## Environment Constraint
Development happens directly on **macOS with Xcode installed** — there is no separate
Windows host and no OneDrive sync step. Build, run, and test locally with `swift build` /
`swift test` / `xcodebuild`, as documented in "Testing Commands" below. Scripts under
`scripts/` run on macOS directly; the historical "Run on Mac with Xcode installed" labelling
on older scripts is a holdover from an earlier setup and can be ignored.

## Phase Plan
| Phase | Name | Gate doc |
|---|---|---|
| 0 | Repository + project OS | `docs/release-checklist.md` §Phase-0 |
| 1 | Specifications + reviews | `docs/release-checklist.md` §Phase-1 |
| 2 | Core game engine vertical slice | `docs/release-checklist.md` §Phase-2 |
| 3 | Full rules engine | `docs/release-checklist.md` §Phase-3 |
| 4 | AI | `docs/release-checklist.md` §Phase-4 |
| 5 | SwiftUI playable Universal app | `docs/release-checklist.md` §Phase-5 |
| 6 | UX polish + accessibility | `docs/release-checklist.md` §Phase-6 |
| 7 | QA hardening | `docs/release-checklist.md` §Phase-7 |
| 8 | Release handover | `docs/release-checklist.md` §Phase-8 |

Do not advance a phase until its gate passes.

## Architecture Decisions

### Module structure
```
WildPairsCore          Swift Package — pure logic, zero UIKit/SwiftUI
WildPairsApp           Xcode app target — SwiftUI, imports WildPairsCore
WildPairsTests         Swift Package test target — tests WildPairsCore
WildPairsUITests       Xcode UI test target — XCUITest
```

### Data flow (MVVM + unidirectional reducer)
```
View → GameAction intent → GameViewModel → GameEngine.reduce(state, action) → new GameState → @Published → View
```
- Engine is a pure function: `(GameState, GameAction) -> (GameState, [GameEffect])`
- ViewModels observe published state; views never mutate engine state directly
- Effects (animate card play, trigger sound, etc.) are handled by ViewModel after reduction

### Persistence
- Format: `Codable` structs serialised as JSON
- Location: `FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!`
- Files:
  - `wildpairs-game.json` — current game snapshot (autosaved every turn)
  - `wildpairs-settings.json` — user preferences
  - `wildpairs-stats.json` — local statistics
- Schema version field on every snapshot for forward-compatible migration
- No iCloud, no CloudKit, no network

### Randomness
- `SeededRNG` wraps `UInt64` seed + `SystemRandomNumberGenerator`
- Production: random seed generated at game start, saved in snapshot
- Tests: inject deterministic seed for reproducible decks and AI moves

### AI fairness
- `AIObservation` struct: what an AI player may legally know
- AI may see: discard pile, current colour/action, all players' card counts, history of played cards, team win state, own hand, **and its partner's hand contents** (`AIObservation.partnerHand`)
- AI may NOT see: any opponent's hidden hand, beyond what rules explicitly reveal
- Partner hands are open between teammates by design (see `docs/game-rules.md` Team Communication Rules) — this applies symmetrically to the human (sees AI partner's hand in the UI) and the AI (may use partner hand contents in move/colour/target heuristics)
- Exception: Forced Swap card legally reveals both hands to the swapping players

## Canonical Design Vocabulary

### Card colours (original — not UNO colours)
| Internal name | Display name | Symbol | Colour-blind pattern |
|---|---|---|---|
| `crimson` | Fire | Flame | Diagonal hatching |
| `cobalt` | Rain | Wave | Horizontal lines |
| `jade` | Earth | Crystal | Vertical lines |
| `amber` | Wind | Gust | Dots |

Phase 11 display-only retheme: the **internal** vocabulary above (`CardColour` case names,
Codable raw values, this table's "Internal name" column) is the canonical engine vocabulary and
never changes — save files, tests, and AI heuristics key off it. Only the **Display name**/
**Symbol** columns are user-facing and were retitled Fire/Rain/Earth/Wind (was
Crimson/Cobalt/Jade/Amber) to read as real elemental cards. `CardColour.displayName` is the
single source of truth for the display name; everywhere else (VoiceOver, UI copy) reads through
it, so no other code needed to change.

### One-card-left mechanic
- **"Solo!"** — player must call "Solo!" when they play down to one card
- If another player calls them out before the next turn starts: +2 draw penalty
- VoiceOver announcement: "Call Solo! You have one card remaining."

### Game modes
| ID | Name | Core rule |
|---|---|---|
| `standardTeams` | Standard Teams | Colour/number/action matching; single-out wins immediately, crediting the team; a 3-minute round timer falls back to lowest-score-wins if nobody goes out |
| `allWild` | All-Wild Teams | Every card plays on every turn; pure action chaos; same single-out / round-timer win condition |
| `sideToSide` | Side-to-Side Teams | 2v2 team support; team pass option; same single-out / round-timer win condition |

Both-teammates-out is a supported house rule (`RuleProfile.winCondition = .bothTeammatesOut`), not the default.

### Card types
`number`, `skip`, `reverse`, `drawTwo`, `drawFour`, `changeColour`, `discardAll`, `targetedDraw`, `forcedSwap`, `skipTwo`, `teamPlay`

### Difficulty levels
| ID | Strategy | Score multiplier |
|---|---|---|
| `easy` | Random valid move | x1 |
| `medium` | Heuristic (prefer actions, basic team awareness) | x2 |
| `hard` | Scored heuristic (multi-factor move scoring) | x4 |
| `expert` | Simulated lookahead + team strategy | x8 |
| `master` | Same strategy as Expert | x24 |

Round-win points are multiplied by the toughest AI opponent's score multiplier.

### Card sets
| ID | Includes |
|---|---|
| `beginner` | Numbers + skip + reverse + changeColour |
| `standard` | Beginner + drawTwo + drawFour |
| `advanced` | Standard + discardAll + targetedDraw + forcedSwap + skipTwo + teamPlay |

## Coding Style
- No comments unless the WHY is non-obvious (hidden constraint, subtle invariant, workaround)
- No multi-paragraph docstrings; one short line max
- No "added for X flow" or "used by Y" comments — those belong in commits
- Small, composable views; no view exceeds ~80 lines without a clear reason
- Prefer `struct` over `class` in domain model; `class` only where identity/reference semantics are required
- `enum` for exhaustive states, not `String` tags
- All model types conform to `Codable`, `Equatable`, `Sendable` where possible
- Use `@StateObject` in root views; `@ObservedObject` when injected
- No `@EnvironmentObject` for game state (explicit injection only)
- Swift 6 concurrency goals: actor-isolated engine where practical

## Enterprise Constraints

### Never use (runtime)
- `URLSession`, `Network.framework`, `WKWebView`, `SFSafariViewController` (remote)
- `AVFoundation` for microphone, `AVCaptureSession`
- `CoreLocation`, `CLLocationManager`
- `CoreBluetooth`, `MultipeerConnectivity`
- `UserNotifications`, `CloudKit`, `GameKit`, `StoreKit`
- Any analytics, crash-reporting, or telemetry SDK

### Never use (development)
- `sudo` or any system modification
- Homebrew, npm, pip, CocoaPods, Carthage, Mint, Ruby gems
- Remote Swift Package dependencies (SPM local packages only in later phases if needed)
- `curl`, `wget`, `git clone` from remote URLs
- Provisioning profiles beyond simulator-compatible (document physical-device signing separately)

### Info.plist must NOT contain
`NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSBluetoothAlwaysUsageDescription`, `NSContactsUsageDescription`, `NSCalendarsUsageDescription`, `NSLocalNetworkUsageDescription`

## Quality Gates

### After Swift file edits (Mac)
```bash
./scripts/quality_light.sh
```

### At phase completion (Mac)
```bash
./scripts/quality_full.sh
./scripts/check_no_network_usage.sh
./scripts/check_permissions_minimal.sh
./scripts/check_project_capabilities.sh
./scripts/check_privacy_manifest.sh
```

## Agent Ownership
| Agent | File | Owns |
|---|---|---|
| product-director | `.claude/agents/product-director.md` | Scope, personas, MVP |
| ux-lead | `.claude/agents/ux-lead.md` | IA, wireframes, interaction |
| ios-architect | `.claude/agents/ios-architect.md` | SwiftUI, modules, persistence |
| game-engine-engineer | `.claude/agents/game-engine-engineer.md` | Rules, state machine, engine |
| ai-gameplay-engineer | `.claude/agents/ai-gameplay-engineer.md` | AI, simulations, balance |
| qa-lead | `.claude/agents/qa-lead.md` | Tests, QA, bug triage |
| accessibility-lead | `.claude/agents/accessibility-lead.md` | VoiceOver, Dynamic Type |
| performance-reliability-lead | `.claude/agents/performance-reliability-lead.md` | Performance, save/resume |
| privacy-brand-safety-lead | `.claude/agents/privacy-brand-safety-lead.md` | Offline guarantee, privacy |
| enterprise-build-lead | `.claude/agents/enterprise-build-lead.md` | Entitlements, capabilities |
| release-manager | `.claude/agents/release-manager.md` | Release checklist, docs |

## Key Documents
| Document | Purpose |
|---|---|
| `docs/game-rules.md` | Canonical game rules for all modes |
| `docs/state-machine.md` | All engine states and transitions |
| `docs/technical-architecture.md` | Module design and data flow |
| `docs/ux-spec.md` | Complete UX with wireframes |
| `docs/design-system.md` | Visual language and design tokens |
| `docs/testing-strategy.md` | Test plan and commands |
| `docs/ai-strategy.md` | AI algorithms and scoring |
| `docs/accessibility-plan.md` | VoiceOver, Dynamic Type, colour-blind |
| `docs/privacy-offline-plan.md` | Offline guarantee and data minimisation |
| `docs/enterprise-build-notes.md` | Build without enterprise friction |
| `docs/permission-audit.md` | Runtime permission audit |
| `docs/release-checklist.md` | Phase gate checklists |
| `docs/premortem.md` | Failure mode analysis |
| `docs/persona-review-log.md` | Persona-by-persona UX review |
| `docs/promoter-score-review.md` | NPS-style review per persona |

## Testing Commands (macOS only)

```bash
# Run Swift Package unit tests
swift test --package-path .

# Run specific test targets
swift test --package-path . --filter WildPairsTests.EngineTests
swift test --package-path . --filter WildPairsTests.RulesTests
swift test --package-path . --filter WildPairsTests.AITests
swift test --package-path . --filter WildPairsTests.SimulationTests

# Run Xcode tests (after Phase 5)
xcodebuild test \
  -scheme WildPairs \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  | xcpretty

xcodebuild test \
  -scheme WildPairs \
  -destination 'platform=iOS Simulator,name=iPad Air (5th generation),OS=latest' \
  | xcpretty

# Run UI tests
xcodebuild test \
  -scheme WildPairsUITests \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

## Legal and Brand Safety
- Do NOT use: UNO, Mattel, official card artwork, copyrighted/trademarked assets
- All terminology is original: colour names, action names, game name, one-card-left call
- Verify with `grep -r "UNO\|Mattel\|mattel\|uno" docs/ WildPairsCore/ WildPairsApp/` on Mac
- See `docs/design-system.md` for approved terminology
