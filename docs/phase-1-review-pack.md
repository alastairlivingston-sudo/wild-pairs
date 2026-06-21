# Wild Pairs — Phase 1 Review Pack

> Owner: release-manager | Status: **Phase 1 complete — Opus review applied — Phase 2 may begin (conditionally)**

This document summarises each Phase 1 specification, records key decisions made, flags unresolved questions, identifies residual risks, and states the acceptance criteria that must be met before Phase 2 (core game engine) work can start.

**Opus review:** Completed 2026-06-21. All Phase-2-blocking issues (A1–A9, B5, B6) and the B1/B2 important issues have been applied to the relevant documents. See `phase-1-opus-action-list.md` for the full action list and `phase-1-opus-review.md` for the full review. Non-blocking items (B3, B4, B7, B8, C1–C5) are deferred and tracked in `known-issues.md`.

**Phase 2 conditional go/no-go:** Phase 2 may begin on Windows once a Mac round-trip confirms the empty `Package.swift` + `WildPairsCore` target + `WildPairsTests` target compile and `swift test` runs. See Phase 2 Go/No-Go checklist below.

---

## Document Index

| # | Document | Section |
|---|---|---|
| 1 | [product-spec.md](product-spec.md) | [→](#1-product-specmd) |
| 2 | [ux-spec.md](ux-spec.md) | [→](#2-ux-specmd) |
| 3 | [design-system.md](design-system.md) | [→](#3-design-systemmd) |
| 4 | [game-rules.md](game-rules.md) | [→](#4-game-rulesmd) |
| 5 | [technical-architecture.md](technical-architecture.md) | [→](#5-technical-architecturemd) |
| 6 | [state-machine.md](state-machine.md) | [→](#6-state-machinemd) |
| 7 | [ai-strategy.md](ai-strategy.md) | [→](#7-ai-strategymd) |
| 8 | [testing-strategy.md](testing-strategy.md) | [→](#8-testing-strategymd) |
| 9 | [accessibility-plan.md](accessibility-plan.md) | [→](#9-accessibility-planmd) |
| 10 | [privacy-offline-plan.md](privacy-offline-plan.md) | [→](#10-privacy-offline-planmd) |
| 11 | [permission-audit.md](permission-audit.md) | [→](#11-permission-auditmd) |
| 12 | [enterprise-build-notes.md](enterprise-build-notes.md) | [→](#12-enterprise-build-notesmd) |
| 13 | [premortem.md](premortem.md) | [→](#13-premortemmd) |
| 14 | [persona-review-log.md](persona-review-log.md) | [→](#14-persona-review-logmd) |
| 15 | [promoter-score-review.md](promoter-score-review.md) | [→](#15-promoter-score-reviewmd) |
| 16 | [known-issues.md](known-issues.md) | [→](#16-known-issuesmd) |

---

## 1. [product-spec.md](product-spec.md)

### Purpose
Defines the product, its goals, its target user, the MVP scope, the three game modes, four difficulty levels, three card sets, seven house rules, save/resume requirements, Universal iPhone/iPad requirements, accessibility requirements, privacy guarantees, enterprise build constraints, and success criteria.

### Key Decisions
- **Fully offline, zero network, no accounts** — the hardest constraint. Every downstream decision must be tested against it.
- **Personal use primary persona; App Store quality secondary** — codebase is built to production standard even though the immediate audience is one person.
- **MVP = Phases 2–5** — a fully playable game with all 11 card types, 3 modes, 4 AI difficulties, save/resume, Universal layout, and full accessibility.
- **Non-goals explicitly listed** — online multiplayer, Game Center, iCloud, analytics, ads, IAP, accounts, Bluetooth multiplayer, macOS, localisation all excluded from MVP.
- **Localisation deferred but future-proofed** — all UI strings go into `Localizable.strings` from day one; no hardcoded English strings in the UI layer.
- **Post-MVP architecture hooks defined** — variable player counts, custom card types (protocol-based), macOS Catalyst, Game Center leaderboards — none foreclose future work.

### Unresolved Questions
- **App name** — "Wild Pairs" is the working title; `design-system.md` recommends "Chromatic". No formal decision has been made. This affects the App Store listing, bundle ID, and all user-facing copy.
- **Exact deck composition** — game-rules.md describes card types and that "number cards 0–9 exist in each colour" but the precise card counts per set (total deck size, exact copies of each action card) are not specified. The engine's `CardFactory` and `Deck` struct will need canonical numbers.
- **Solo! timeout duration** — described as "configurable" in product-spec.md and game-rules.md but no default value (in seconds) is specified. This affects both the human UI timer and the AI auto-call delay.
- **Target score thresholds for scoring mode** — described as "configurable" but no default target score or round-count defaults are specified.

### Risks
- **Scope creep** — the non-goals table mitigates this, but the Phase 5 gate must be enforced strictly.
- **"Personal use" quality bar** — product-spec.md explicitly counters this risk by requiring App Store standards throughout, but enforcement depends on phase gates being taken seriously.
- **Deck composition ambiguity** — if canonical card counts are not decided before Phase 2, the `Deck` struct will require a breaking change later.

### Acceptance Criteria for Phase 2
- [ ] App name decision made (working title confirmed or replaced) and documented in `design-system.md`.
- [ ] Canonical card counts per card set specified in `game-rules.md` (exact copies of each card type per colour per set).
- [ ] Solo! timeout default value (seconds) specified in `game-rules.md`.
- [ ] Default target score for scoring mode specified in `game-rules.md`.
- [ ] All items in the product-spec.md Success Criteria table reviewed; any that cannot be verified in Phase 2 annotated with the phase in which they will first be verifiable.

---

## 2. [ux-spec.md](ux-spec.md)

### Purpose
Defines the complete user experience: 10 experience principles, information architecture, 17 user journeys (first launch through post-game summary), 14 ASCII wireframes for iPhone and iPad, game table UX specification, player zones, card interaction model, colour/target picker flows, action prompt text patterns, animation motion catalogue, and accessibility focus order.

### Key Decisions
- **10 experience principles** govern all design decisions — most critical: "one obvious primary action", "never colour-only", "no dead ends", "feel physical not digital".
- **17 user journeys specified** — covers first launch, mid-game resume, mode/difficulty selection, card play, Solo! call, round end, and settings flows.
- **14 ASCII wireframes** — separate wireframes for iPhone and iPad for the key screens; iPad is a true table layout, not a scaled iPhone.
- **Game table action prompt area** — persistent prompt zone above the player hand with 15+ example strings specified; covers every state the human player might encounter.
- **Motion catalogue** — every animation named, duration specified (standard and fast-mode variants), Reduce Motion fallback defined.
- **Colour/target picker flows** — appear as bottom sheets on iPhone, popovers on iPad; confirm-tap required before resolving; cancellation not permitted once a wild card is committed.
- **Illegal card shake + tooltip** — visual feedback for tapping a non-playable card specified.

### Unresolved Questions
- **Solo! button timeout UX** — the timeout is acknowledged but the visual countdown mechanism (progress ring, shrinking bar, number countdown?) is not specified. Needs design decision before Phase 5.
- **AI turn pacing UI** — the UX spec describes AI thinking delays per difficulty but does not fully specify what the human sees during an AI turn (spinner? card-back animation? nothing?). Needs resolution before Phase 5.
- **iPad multi-scene / slide-over** — spec states the game pauses on secondary-window interaction but the pause/resume UX for this scenario is not wireframed.
- **Onboarding flow depth** — the first-launch journey is specified but the depth of the tutorial (rule explanation vs. just a setup wizard) is not pinned down.
- **VoiceOver announcement ordering during rapid AI turns** — if multiple AI players take turns quickly, announcement queuing behaviour is unspecified.

### Risks
- **ASCII wireframes leave visual interpretation ambiguous** — the exact proportions, spacing, and visual hierarchy of the game table are implied but not pixel-specified. Phase 5 may require design iteration.
- **17 journeys may not cover all edge cases** — specifically, Forced Swap + Solo! in the same turn, and Team Pass declining mid-flow, are not explicitly journeyed.
- **iPad split-view behaviour** — game-pauses-on-slide-over is specified but not tested until Phase 5; may conflict with adaptive layout implementation.

### Acceptance Criteria for Phase 2
- [ ] Confirm the 17 journeys cover all card types that require a decision prompt (Discard All colour choice, Targeted Draw target selection, Forced Swap target selection, Change Colour selection, Draw Four colour selection). Add any missing journeys before Phase 2 begins.
- [ ] Solo! timeout countdown visual mechanism decided and added to the UX spec.
- [ ] AI turn "thinking" visual state specified (what the human sees while AI acts).

---

## 3. [design-system.md](design-system.md)

### Purpose
Defines the visual language: app name recommendation, tone of voice, 8 typography styles, 8 spacing tokens, corner radius tokens, card dimensions for iPhone and iPad, 4 game colour palette with colour-blind safe patterns and symbols, button styles, SF Symbol usage, custom suit symbols, animation duration tokens, haptic patterns, dark mode strategy, and device-specific layout decisions.

### Key Decisions
- **4 original colours** — Crimson (Flame), Cobalt (Wave), Jade (Leaf), Amber (Sun) — all original; no UNO colour references.
- **Symbols always visible** — card symbols (Flame, Wave, Leaf, Sun) are shown on every card face by default, not only in colour-blind mode.
- **SF Pro system font** — no custom font dependency; system font scales with Dynamic Type automatically.
- **Animation tokens** — standard and fast-mode duration values specified as design tokens so the engine and UI layer stay in sync.
- **Dark mode** — documented strategy; game colours desaturate slightly for dark backgrounds.
- **Size-class breakpoints** — compact (iPhone) vs. regular (iPad) layout decisions documented; card dimensions differ by form factor.

### Unresolved Questions
- **App name / icon** — `design-system.md` recommends "Chromatic" over "Wild Pairs" but this is a recommendation only. No app icon is designed or specified. Icon design is needed before App Store submission but not before Phase 5.
- **Custom suit symbol assets** — the Flame, Wave, Leaf, Sun symbols need to be created as vector assets (SF Symbols or custom SVG/PDF). The spec describes them but does not yet include asset files.
- **Haptic patterns** — haptic style tokens are named but not fully mapped to CoreHaptics parameters. This is a Phase 6 concern but should be noted.

### Risks
- **Colour-blind pattern fills** — the spec mandates pattern fills for colour-blind mode but the exact patterns (hatch density, line thickness) that will remain distinguishable at card thumbnail size on iPhone SE are untested. This needs to be verified in Phase 5/6.
- **Card readability at small sizes** — the card dimension token for iPhone compact mode is specified, but the smallest legible symbol and number size at that dimension has not been tested with real Dynamic Type sizes.

### Acceptance Criteria for Phase 2
- [ ] App name decision reflected in `design-system.md` (and all other docs where the app name appears).
- [ ] Confirm that all four card symbols (Flame, Wave, Leaf, Sun) are defined clearly enough to produce placeholder vector assets in Phase 5. No actual assets needed in Phase 2.

---

## 4. [game-rules.md](game-rules.md)

### Purpose
The canonical rules reference for the engine. Specifies: setup (players, teams, card sets, dealing), core matching mechanics, full turn structure, complete card catalogue for all 11 card types, all three game modes, win conditions, scoring, the Solo! mechanic, team rules, all seven house rules, turn-direction and skip logic, and draw pile exhaustion.

### Key Decisions
- **Exact turn structure defined** — 7-step sequence (forced draw → skip check → play or draw → resolve effect → Solo! check → empty-hand check → advance turn); order matters for correct engine implementation.
- **All-Wild mode rule isolation** — in All-Wild mode, the only change is that colour/number matching requirements are removed; all card effects still apply.
- **Draw Stacking constraint** — Draw Two and Draw Four can be stacked (house rule) with colour-type matching still required; the cumulative penalty is capped by the stacking chain, not the deck.
- **Forced Swap Solo! re-evaluation** — both players' Solo! status is re-evaluated after a swap; this is a non-obvious rule that the engine must handle.
- **Discard All colour choice timing** — the player chooses the colour to discard after playing the card (not before); this requires a pending decision state.
- **Stuck-game detection** — max 300 turns after which the game ends with current score; prevents infinite loops in All-Wild mode.
- **Solo! window** — closes when the Solo!-holding player's next turn begins or the round ends, whichever comes first.

### Unresolved Questions
- **Exact deck composition** — the rules describe card types but not total card counts per set (see also product-spec.md §1). For example: how many Skip cards per colour? How many Change Colour cards total? This must be resolved before `CardFactory` and `Deck` are implemented.
- **Draw Stacking between Draw Two and Draw Four** — the house rule states players "may stack Draw Two and Draw Four" but the matching rule is stated as "colour-type matching still applies". Does a Draw Four stack onto a Draw Two of the matching colour? The current text is ambiguous.
- **Team Play default variant** — product-spec.md says "both teammates draw 1 card" is the default, with "partner plays immediately" as a house rule variant. game-rules.md §11 describes both but the default is ambiguous between the two descriptions.
- **Discard All + win condition** — if Discard All empties the hand completely, the rules confirm this is a valid win. But if the player has cards of two colours and plays Discard All of the colour that leaves them with 1 card, the sequence of "choose colour → discard → Solo! check → optionally play remaining card" needs full engine clarification.
- **Solo! timeout default** — not specified (see also product-spec.md §1).
- **Score target defaults** — not specified (see also product-spec.md §1).

### Risks
- **Rule ambiguities surface as engine bugs** — the deck composition and Draw Stacking ambiguities are the most likely sources of hard-to-detect engine bugs if resolved inconsistently during implementation.
- **Skip Two team-targeting edge case** — the rules correctly note that Skip Two always skips the human's partner when played by the human in clockwise direction. This is a strategically significant rule that must be correctly communicated to the player; the UX prompt for Skip Two needs to be explicit.
- **Discard All + Forced Swap interaction** — if a player plays Discard All and then their hand has 1 card remaining, and before they call Solo! an opponent plays a Forced Swap — the interaction is not addressed in the rules.

### Acceptance Criteria for Phase 2
- [ ] Canonical deck composition table added to `game-rules.md` (card type, count per colour, total per set).
- [ ] Draw Stacking cross-type rule clarified (can Draw Four stack onto Draw Two?).
- [ ] Team Play default variant unambiguously identified (draw vs. play-immediately).
- [ ] Solo! timeout default value specified.
- [ ] Discard All + 1-card-remaining sequence documented as a named engine edge case.

---

## 5. [technical-architecture.md](technical-architecture.md)

### Purpose
Defines the module structure (`WildPairsCore`, `WildPairsApp`, `WildPairsTests`, `WildPairsUITests`), data flow (MVVM + unidirectional reducer), the pure `GameEngine.reduce` function signature, `GameState` (14 fields), `GameAction` (13+ cases), `GameEffect` (15+ cases), `RuleProfile` design, `SeededRNG` (splitmix64), `AIObservation`, persistence design (file paths, `GameSnapshot` envelope, migration chain), the MVVM layer, adaptive layout architecture, error handling, logging, and testing architecture.

### Key Decisions
- **Engine is a pure function** — `(GameState, GameAction) -> (GameState, [GameEffect])`; no mutation, no network, no side effects. This is the defining architectural constraint.
- **`WildPairsCore` depends only on `Foundation`** — never imports SwiftUI, UIKit, AVFoundation, or any UI framework. Enforced by dependency direction.
- **`GameEffect` is a value enum** — no closures; fully inspectable in tests.
- **`SeededRNG` is splitmix64** — deterministic, serialisable, fast. RNG state is reconstructed at resume by fast-forwarding from the seed using `actionCount`.
- **Persistence in `Application Support/WildPairs/saves/`** — not `Documents/`; app data rather than user-exportable data.
- **`GameSnapshot` includes schema version + build version** — forward-compatible migration chain from v1 onward.
- **`@MainActor` on `GameViewModel`** — all UI-bound state is main-thread isolated; engine calls are synchronous.
- **No third-party dependencies** — zero external packages; only Apple frameworks.

### Unresolved Questions
- **RNG reconstruction performance** — for a long game (approaching 300 turns), fast-forwarding the RNG by replaying `actionCount` calls may be slow. The spec notes "for simplicity in Phase 2" this approach is used; a production alternative (storing live RNG state in snapshot) is deferred. This technical debt should be resolved by Phase 3.
- **Swift 6 concurrency plan** — CLAUDE.md states "actor-isolated engine where practical" but `technical-architecture.md` shows the engine as a `@MainActor` synchronous call. The path to Swift 6 strict concurrency compliance is not fully specified.
- **AI computation threading** — the spec states AI runs as a "timed delay then sync call". For Expert AI with lookahead, a synchronous call on the main actor may cause UI jank. No background dispatch strategy is specified.
- **`forceState` debug action** — the `GameAction.forceState` case is `#if DEBUG` only but is part of the `Codable` enum. Whether this case is excluded from the Codable conformance in release builds needs clarification.

### Risks
- **RNG fast-forward correctness** — if the `actionCount` used to reconstruct the RNG diverges from the actual number of `next()` calls made during the game, resumed games will have different random draws than they would have had. This is a subtle correctness risk.
- **Migration chain correctness** — the migration chain approach is solid but each migration function must be independently tested; a bug in `migrateV1toV2` will corrupt all saves on upgrade.
- **Expert AI main-thread latency** — if Expert AI lookahead is computationally expensive, the `scheduleAIMove` delay conceals latency but does not eliminate it. The main thread freeze during the synchronous compute call could be noticeable.

### Acceptance Criteria for Phase 2
- [ ] `Package.swift` created with correct targets: `WildPairsCore` (library), `WildPairsTests` (test target). Builds cleanly on Mac.
- [ ] All model types implemented as `Codable`, `Equatable`, `Sendable` structs/enums: `Card`, `Deck`, `Player`, `GameState`, `GameAction`, `GameEffect`, `RuleProfile`, `SeededRNG`, `GameSnapshot`.
- [ ] `GameEngine.reduce` skeleton implemented — takes state and action, returns (state, effects). Initial implementation handles at minimum: `newGame`, `drawCard`, `passTurn`, `pauseGame`, `resumeGame`.
- [ ] `WildPairsTests` target can import `WildPairsCore` and run at least one passing test. No SwiftUI imports in test target.
- [ ] RNG fast-forward approach decision made and documented: either accept the Phase 2 simplification with a Phase 3 ticket, or implement snapshot-of-RNG-state now.

---

## 6. [state-machine.md](state-machine.md)

### Purpose
Defines all 15 engine states, all transitions between them, concurrency notes, persistence strategy (autosave trigger points per state), snapshot format, and recovery procedures for corrupted saves and mid-turn background transitions.

### Key Decisions
- **15 states** — from `appLaunching` through `awaitingAITurn`, `awaitingHumanDecision`, `pendingColourChoice`, `pendingTargetChoice`, `pendingTeamPass`, `soloCallWindow`, `roundEnded`, `gameEnded`, `paused`, `errorRecoverable`.
- **Fully synchronous, main actor** — no background threads in the engine; simplifies state correctness guarantees.
- **Autosave on every stable waiting state** — every state where the human waits for input (or AI is about to move) triggers a save. The game is never more than one turn from a valid checkpoint.
- **`pendingDecision` field in `GameState`** — all mid-turn decisions (colour choice, target, team pass) are part of the state, so a backgrounded app resumes with the decision picker re-presented.
- **Corrupted save recovery** — move aside, alert, offer new game. Never crash.
- **`sceneWillDeactivate` triggers save on iPad** for multi-scene support.

### Unresolved Questions
- **`errorRecoverable` state handling** — the state is defined but the exact set of errors that lead to `errorRecoverable` vs. silent correction is not fully enumerated. The engine's production behaviour for invariant violations (not covered by debug `precondition`) needs to be explicit.
- **State on first launch** — no "no saved game" state is explicitly named. The flow from `appLaunching` to the setup screen (no saved game) vs. the resume prompt (saved game exists) should be a named transition.

### Risks
- **Transition completeness** — with 15 states and many card types that can change state non-obviously (e.g., Discard All can trigger `pendingColourChoice` mid-resolution, then `soloCallWindow`, then potentially `roundEnded`), some transition paths may be unspecified. These will surface as bugs in Phase 3.
- **`pendingDecision` + backgrounding during AI turn** — the spec says: on resume from `awaitingAITurn`, recalculate AI move from saved state. If the AI had already started a multi-step card resolution (e.g., played a Discard All and was about to commit a colour), the state at save time may not correctly capture the in-progress resolution.

### Acceptance Criteria for Phase 2
- [ ] Phase 2 engine skeleton implements and covers at minimum the states reachable from `newGame` → `awaitingHumanTurn` → `drawCard` → `awaitingHumanTurn`. Remaining states implemented in Phase 3.
- [ ] State transitions for the Phase 2 scope have unit tests asserting correct state after each action.
- [ ] `errorRecoverable` state entry conditions documented (minimum viable list) before Phase 3 begins.

---

## 7. [ai-strategy.md](ai-strategy.md)

### Purpose
Defines the AI fairness model (`AIObservation`), four difficulty algorithm specifications (Easy through Expert), the move scoring framework, colour and target selection strategies, partner/opponent awareness rules, AI timing model, and the simulation framework with acceptance criteria.

### Key Decisions
- **`AIObservation` is the only input to any AI** — constructed from `GameState` by filtering out all hidden information. AI never receives `GameState` directly.
- **Opponent hand contents are never exposed** — only hand sizes (card counts) are visible.
- **Forced Swap exception** — Forced Swap legally reveals both hands to swapping players; `AIObservation` construction accounts for this.
- **Easy = random valid move** — no heuristic; selection from `legalPlays()` output only.
- **Medium = heuristic** — prefer action cards, hold wilds, prefer colour extension for partner.
- **Hard = scored heuristic** — multi-factor move scoring (hand reduction, partner vulnerability, opponent disruption, Solo! risk).
- **Expert = bounded lookahead simulation** — selects highest-expected-value move from a bounded search tree; uses masked observation throughout.
- **1,000-game illegal-move test** — `testAINeverMakesIllegalMove` must pass for all difficulties in all modes.
- **Simulation acceptance criteria** — Easy < Medium < Hard < Expert win rates against a fixed baseline over a statistically significant sample.

### Unresolved Questions
- **Expert AI lookahead depth** — described as "bounded" but the bound is not specified. The depth affects performance significantly; needs a default (e.g., depth 2 or 3) specified before Phase 4.
- **Performance budget for AI think time** — no maximum latency target is specified for Expert AI on the minimum supported device (iPhone SE). The AI "delay" before moving is cosmetic, but the underlying computation must complete within the delay window or the delay must be extended dynamically.
- **Balance simulation sample size** — "statistically significant" is not quantified. A specific game count (e.g., 1,000 games per difficulty per mode) should be specified.
- **AI partner strategy in Expert mode** — the strategy for choosing moves that help the partner vs. winning solo is described conceptually but the scoring weights between "help partner" and "win self" are not specified.

### Risks
- **Expert AI on older devices** — a deep lookahead tree on iPhone SE could freeze the main actor for hundreds of milliseconds if not bounded carefully. This risk is noted but not mitigated until Phase 4.
- **Balance calibration requires playtesting** — the simulation framework can confirm win rates but cannot substitute for human perception of "fair" vs. "frustrating" difficulty. The Phase 4 gate requires the Opus AI review to assess whether the difficulty curve is humane.
- **AIObservation construction correctness** — if a bug causes opponent hand contents to leak into `AIObservation`, AI will cheat without the bug being visually apparent. The `testAIObservationNeverExposesForbiddenFields` test is critical.

### Acceptance Criteria for Phase 2
- [ ] `AIObservation` struct fully implemented with all visible and excluded fields as specified.
- [ ] `legalPlays(state:for:)` function implemented and returning the correct set of playable cards for all card types (including All-Wild mode).
- [ ] Easy AI implemented (random selection from `legalPlays`). Passes `testAINeverMakesIllegalMove` for Easy difficulty.

---

## 8. [testing-strategy.md](testing-strategy.md)

### Purpose
Defines the test pyramid (unit → scenario → simulation → UI → manual), test tooling (`Swift Testing`, `XCTest`, `SeededRNG`, `GameStateBuilder`, `GameSimulator`), per-phase coverage targets, 23 named scenario tests, 12 UI test scenarios, simulation test design, manual test scripts, and what cannot be tested automatically.

### Key Decisions
- **Test-per-feature mandate** — each card type must have a passing test before it is considered implemented (enforced at Phase 3 gate).
- **`swift test` must pass at start of every phase** — regression safety net from Phase 2 onward.
- **`GameStateBuilder` in `WildPairsCore`** — fluent test fixture builder; avoids duplicating setup code across tests.
- **`SeededRNG(seed: 42)`** — all shuffle/draw tests use fixed seeds so CI is deterministic.
- **Never mock `GameEngine`** — tests call `GameEngine.reduce` directly; no mock behaviour.
- **23 named scenario tests** — cover all card types, all game modes, win conditions, edge cases (stuck game, corrupted save, Forced Swap + Solo!, etc.).
- **12 UI test scenarios** — XCUITest for full game flow, accessibility label verification, iPad layout assertions.

### Unresolved Questions
- **CI/CD strategy** — the Windows development host cannot run `swift test`. Tests are run manually on Mac after file sync via OneDrive. No automated CI pipeline is specified. This is a process risk, not a code risk, but should be acknowledged.
- **Coverage percentage targets** — "full coverage for all state transitions" is the goal but a specific percentage target (e.g., 90% line coverage for `WildPairsCore`) is not stated. This makes the gate subjective.
- **Simulation test runtime** — running 1,000 games per difficulty per mode in CI could take significant time. Runtime budget for the simulation test suite is not specified.
- **Manual test script ownership** — the manual test scripts (MTS-001 through MTS-030+) are referenced but the document describing exactly how each is run is not linked.

### Risks
- **No CI** — without automated CI on Mac, regressions in the engine can be introduced between manual test runs. This is the highest-probability QA risk for the project.
- **UI test brittleness** — XCUITests for a game with dynamic state are inherently fragile. The strategy of using fixed seeds helps but does not eliminate flakiness from timing-dependent UI behaviour.
- **Testing gap for iPad layout** — unit tests cannot verify layout correctness. Manual test scripts for iPad are specified but depend on the developer running them on the correct simulator sizes.

### Acceptance Criteria for Phase 2
- [ ] `WildPairsTests` target created in `Package.swift` and at least one test for each of: `Deck` (shuffle), `SeededRNG` (determinism), `GameEngine.reduce` (newGame action produces correct initial state).
- [ ] `GameStateBuilder` implemented and used in at least one test.
- [ ] `CardFactory` implemented with at least the cards needed for Phase 2 tests.
- [ ] `quality_light.sh` script runs `swift test` and passes on Mac.

---

## 9. [accessibility-plan.md](accessibility-plan.md)

### Purpose
Specifies VoiceOver label patterns for all card types, game state announcements, custom accessibility actions ("Play card", "Card details"), VoiceOver focus order for iPhone and iPad game table, Dynamic Type support across all size classes, large card mode specification, colour-blind mode enhancements (pattern fills + larger symbols), high contrast mode, Reduce Motion specification, haptic accessibility, minimum tap target sizes, and a per-screen implementation checklist.

### Key Decisions
- **Accessibility is mandatory from day one, not Phase 6 retrofit** — accessibility labels are first-class fields on the `Card` model, not added later.
- **`accessibilityLabel` is a computed property on `Card`** — format: "[Colour] [Type/Number]" (e.g., "Crimson Five", "Jade Skip", "Change Colour").
- **Custom actions on playable cards** — VoiceOver surfaces "Play [card name]" as the primary action; "Card details" as secondary.
- **Live region announcements** — turn changes, card plays, Solo! calls, skip/reverse effects all use VoiceOver live regions.
- **Colour-blind mode default** — symbols (Flame, Wave, Leaf, Sun) are visible on all cards by default; colour-blind mode adds pattern fills and larger symbols.
- **Minimum tap targets** — 44×44pt minimum per HIG; game cards exceed this.
- **Reduce Motion** — all card slide, shuffle, and direction-change animations are replaced by instant transitions. No flip animations. Sound effects unaffected.

### Unresolved Questions
- **VoiceOver announcement ordering during rapid AI turns** — if two or three AI players take turns in quick succession, announcement queuing is not fully specified. Does VoiceOver interrupt a previous announcement? Does it queue? Is there a maximum announcement backlog?
- **iPad 4-player table VoiceOver focus order** — the plan specifies focus order for iPhone (bottom hand → discard → draw → opponent zones → status) but the iPad table layout (hands at all four edges) may have a different optimal focus order that is not yet specified.
- **Large Card mode layout on iPhone SE** — the large card mode spec doesn't address how cards in the hand are displayed when the card size pushes the hand beyond the screen width on the smallest supported device.
- **High contrast mode interaction with game colours** — the game's 4 colours (Crimson, Cobalt, Jade, Amber) are chosen for visual appeal; high contrast mode may require different hues that still maintain game identity.

### Risks
- **VoiceOver focus disruption during animations** — if card play animations move elements that have VoiceOver focus, focus can jump unexpectedly. This is common in game apps and must be explicitly managed. The plan specifies Reduce Motion fallbacks but not focus management during animations.
- **Colour-blind pattern fills at small sizes** — the 4 patterns (diagonal hatching, horizontal lines, vertical lines, dots) must remain distinguishable at card thumbnail size (~50pt wide on iPhone SE). This has not been verified with a real device.
- **Dynamic Type reflow at largest accessibility sizes** — at xxxLarge or Accessibility sizes, card content (symbol + number + colour name) may overflow the card face. Reflow strategy for this case is unspecified.

### Acceptance Criteria for Phase 2
- [ ] `Card` model in `WildPairsCore` includes `accessibilityLabel: String` as a computed property, correctly formatted for all 11 card types.
- [ ] `Player` model includes `accessibilityHandDescription: String` (e.g., "5 cards").
- [ ] `GameEffect.accessibilityAnnounce(String)` case implemented and handled by `AccessibilityAnnouncer` in the ViewModel (Phase 5 concern, but model defined in Phase 2).

---

## 10. [privacy-offline-plan.md](privacy-offline-plan.md)

### Purpose
Documents the offline-first guarantee, the data inventory (three JSON files: game snapshot, settings, statistics), the required-reason APIs audit, the `PrivacyInfo.xcprivacy` template, network-free verification scripts, third-party SDK assessment (zero dependencies), data minimisation practices, reset-local-data flow, and trademark/brand safety verification commands.

### Key Decisions
- **"No data collected" App Store privacy label** — the strongest possible privacy declaration. All three JSON files stay on device, never transmitted.
- **`PrivacyInfo.xcprivacy` required** — must declare required-reason API usage (e.g., `NSFileSystemFreeSize` if used, `UserDefaults` if used). Template prepared.
- **Zero third-party SDKs** — no analytics, crash-reporting, or telemetry SDKs. Developer uses Xcode device logs directly.
- **Statistics data minimisation** — only aggregated statistics (games played, wins, win rate) are stored, not per-turn logs or hand histories.
- **`check_no_network_usage.sh`** — script scans for `URLSession`, `Network.framework`, and other network APIs at every phase gate.
- **Trademark grep** — `grep -r "UNO|Mattel|mattel|uno"` must return zero results at Phase 8 gate.
- **Reset local data flow** — Settings screen includes "Reset All Data" option; confirms before deleting all three JSON files.

### Unresolved Questions
- **`PrivacyInfo.xcprivacy` required-reason APIs** — the exact list of APIs used that require a reason declaration needs to be finalised when the Xcode project is created (Phase 5). The template is ready but the final list depends on which Apple APIs the app actually calls (e.g., `FileManager.attributesOfItem` uses `NSFileSystemFreeSize` which requires a declared reason).
- **Statistics schema** — what statistics are tracked is described at a high level (games played, wins, win rate) but the exact `wildpairs-stats.json` schema is not specified. Schema versioning for statistics migration is not addressed.

### Risks
- **Required-reason API audit gap** — new iOS APIs can require reason declarations without obvious signals. Failing to declare a used API in `PrivacyInfo.xcprivacy` is an App Store rejection reason. The audit must be re-run after Phase 5 implementation.
- **`PrivacyInfo.xcprivacy` Xcode project setup** — this file must be added as a resource to the app target in Xcode; it is easy to forget when creating the Xcode project in Phase 5.

### Acceptance Criteria for Phase 2
- [ ] `check_no_network_usage.sh` script exists in `scripts/` directory and can be run on Mac (even if the WildPairsCore package has no Swift files yet).
- [ ] `wildpairs-stats.json` schema defined (even if the file is not written yet).
- [ ] Statistics data minimisation confirmed: no per-hand or per-turn logs in the statistics file.

---

## 11. [permission-audit.md](permission-audit.md)

### Purpose
Certifies that Wild Pairs requires zero runtime permissions. Audits all 22 iOS protected resources and confirms none are used. Documents Info.plist required keys (absent forbidden keys), expected entitlements (sandbox only), 21 capabilities to never enable, no background modes, and verification procedures.

### Key Decisions
- **Zero runtime permissions** — the most aggressive privacy posture possible. No permission dialogs ever appear.
- **21 capabilities listed to never enable** — iCloud, Game Center, Push Notifications, In-App Purchase, Maps, HealthKit, HomeKit, Sign In with Apple, Siri, Wallet, Background Fetch, Background Processing, Associated Domains, Network Extensions, Hotspot, Near Field Communication, Bluetooth, App Groups, ClassKit, MDM Managed App, Automatic Assessment Configuration.
- **`check_project_capabilities.sh`** — runs at every phase gate from Phase 5 onward; scans entitlements file.
- **`NSAllowsArbitraryLoads` must be absent** from Info.plist.
- **No Info.plist privacy usage description keys** — if none of the 22 NSXxxUsageDescription keys appear in Info.plist, the audit passes.

### Unresolved Questions
- **Physical device ad-hoc distribution entitlements** — building for a physical device (even for personal use) requires a signing identity and provisioning profile. The entitlements for simulator vs. device builds may differ. This is documented as optional/post-MVP but the entitlement implications are not fully worked through.
- **AVFoundation for sound** — `technical-architecture.md` lists `AVFoundation` as used for sound effect playback. The permission audit notes AVFoundation is permitted for playback (not microphone/camera). Confirm that `AVAudioSession` configuration does not inadvertently trigger a microphone permission check.

### Risks
- **Xcode capability auto-enablement** — Xcode has been known to silently enable capabilities (e.g., iCloud when adding a file with certain extensions). `check_project_capabilities.sh` must be run after every Xcode project modification, not just at phase gates.
- **AVFoundation category** — setting `AVAudioSession.Category.playback` with incorrect options could interfere with the device's ambient audio or trigger unexpected system behaviour. Needs verification in Phase 5.

### Acceptance Criteria for Phase 2
- [ ] `check_project_capabilities.sh` script exists (it will have nothing to check until Phase 5, but should be created now).
- [ ] `check_permissions_minimal.sh` script exists.
- [ ] Confirmed in writing: `AVAudioSession` use for sound playback does not require any NSMicrophoneUsageDescription key.

---

## 12. [enterprise-build-notes.md](enterprise-build-notes.md)

### Purpose
Documents the Windows-host/macOS-build development workflow, prerequisites (Xcode 15+, no external tools), repository layout, 8-step first-time macOS setup procedure, build commands for iPhone/iPad simulator, test commands, optional physical device deployment, enterprise environment friction points with solutions, Claude Code permission posture, and 21 forbidden capabilities with rationale.

### Key Decisions
- **No Homebrew, CocoaPods, Carthage, Mint, npm, pip, or any package manager** — the project must be buildable from a clean macOS install with only Xcode.
- **Simulator-first** — all feature development and testing in iOS Simulator; physical device testing is optional/pre-release only.
- **OneDrive sync** — Claude Code on Windows edits files; OneDrive syncs them to Mac for compilation. File conflicts are the primary operational risk.
- **Xcode project created via wizard** — not hand-crafted `.pbxproj`; reduces misconfiguration risk.
- **Claude Code on Windows** — used for code editing, document generation, file exploration; never for `swift build` or compilation.
- **`scripts/quality_light.sh` and `quality_full.sh`** — run on Mac after file edits and at phase gates respectively.

### Unresolved Questions
- **OneDrive conflict resolution** — if Claude Code writes a file while Xcode has it open on Mac, OneDrive may create a conflict copy. No conflict-resolution procedure is documented.
- **Large binary assets in OneDrive** — xcassets directories containing PNG assets (card artwork, app icon) may create sync latency. The repository has no assets yet but will in Phase 5.
- **Xcode version pinning** — the notes specify Xcode 15+ but do not pin a specific version. Swift Package resolution behaviour can change between Xcode minor versions.

### Risks
- **OneDrive sync delays** — a freshly edited Swift file may not sync to Mac before the developer runs `swift test`. The developer must wait for sync confirmation before building.
- **`.pbxproj` merge conflicts** — if any Xcode project changes are made on Mac (e.g., adding a file via Xcode's GUI) and Claude Code also edits project files on Windows simultaneously, the `.pbxproj` could corrupt. Workflow discipline is the only mitigation.
- **Xcode auto-generated files** — Xcode may generate or modify files (derived data, `.xcuserstate`, scheme files) that should not be committed. The `.gitignore` must be correct before the Xcode project is created in Phase 5.

### Acceptance Criteria for Phase 2
- [ ] `scripts/` directory exists with at minimum: `quality_light.sh`, `quality_full.sh`, `check_no_network_usage.sh`, `check_permissions_minimal.sh`, `check_project_capabilities.sh`, `check_privacy_manifest.sh`. Each is marked executable and labelled "Run on Mac with Xcode installed".
- [ ] `.gitignore` covers all Xcode-generated files (`*.xcuserstate`, `DerivedData/`, `.build/`, `.swiftpm/`).
- [ ] `Package.swift` is the only file that needs to exist for `swift test` to run (Xcode project deferred to Phase 5).

---

## 13. [premortem.md](premortem.md)

### Purpose
Identifies 30+ potential failure modes across 10 specialist roles (Product, UX, Architect, Game Engine, AI, QA, Accessibility, Performance, Privacy, Enterprise), assesses severity and likelihood, and documents prevention strategies and spec changes applied. All 13 spec changes have been applied to the relevant documents.

### Key Decisions
- **All critical failure modes are mitigated** — the 10 critical failures identified (scope creep, game table confusion, direct state mutation in views, save/resume unreliability, hidden engine state, AI illegal moves, AI cheating, stuck game loops, no tests until end, VoiceOver unplayable) all have explicit prevention and quality gates.
- **13 spec changes applied** — non-goals table, iPad wireframes, action prompt strings, All-Wild RuleProfile, max-turn limit (300), accessibilityLabel as first-class field, app lifecycle save/resume, trademark grep, 21 forbidden capabilities, `check_project_capabilities.sh` in every gate.
- **Quality gates are concrete** — each failure mode has a named test, script, or manual test that gates advancement.

### Unresolved Questions
- **Failure mode coverage completeness** — the premortem covers the 10 named specialist roles but does not include a "localization" role (low risk given English-only MVP) or a "data migration" role (medium risk as schema evolves through phases).
- **Mitigation verification** — all failures are marked `mitigated` based on spec changes, but mitigations are plans, not implemented code. They will need to be verified as each phase is implemented.

### Risks
- **New failure modes in Phase 2+** — the premortem was run on Phase 1 specs; new failure modes specific to the Phase 2 engine implementation (e.g., RNG correctness, `Codable` round-trip for all card types) will emerge and should be added as the project progresses.
- **Mitigation decay** — a spec-level mitigation (e.g., "AI only receives `AIObservation`") can be violated during implementation if there is no automated enforcement. Tests are the enforcement mechanism; tests must be written before the corresponding code.

### Acceptance Criteria for Phase 2
- [ ] No new open failure modes identified before Phase 2 begins (or if new ones are found during the Opus review, they are added to `premortem.md` and mitigated before Phase 2 starts).
- [ ] Phase 2 gate will run `swift test` and verify all engine tests pass — this is the first automated premortem mitigation verification.

---

## 14. [persona-review-log.md](persona-review-log.md)

### Purpose
Documents a UX walkthrough from the perspective of 10 user personas: Casual Player, Strategic Player, First-Time Player, Older/Low-Vision User, Colour-Blind User, VoiceOver User, Commuter (short sessions), Power User, iPad Player, and Enterprise Developer. Each persona scored 10 evaluation areas (0–10), with findings and 13 improvements applied.

### Key Decisions
- **13 improvements applied to specs** — the review drove concrete changes to `ux-spec.md`, `accessibility-plan.md`, `design-system.md`, and `game-rules.md`.
- **iPad Player persona scored highly** — the dedicated iPad table layout and spacious design satisfied the iPad-specific persona.
- **VoiceOver User persona drove accessibility completeness** — the review confirmed that accessibility labels, custom actions, and announcement patterns cover the full game flow.
- **Commuter persona validated save/resume** — autosave on every stable state satisfied the interrupted-session scenario.
- **Enterprise Developer persona** confirmed simulator-first approach and zero-dependency build.

### Unresolved Questions
- **Lowest-scoring areas** — the review log documents scores per persona/area but a summary of which evaluation areas scored below a threshold across all personas is not present. It would be useful to know which areas need the most attention in Phase 5/6 implementation.
- **Teen/younger player persona** — not represented in the 10 personas. If the product is intended as a family game, this persona may surface different UX needs.
- **Real user validation** — the review is a simulated persona walkthrough by the development team; no actual user testing has been conducted.

### Risks
- **Simulated vs. real user behaviour** — persona reviews are useful for identifying obvious issues but cannot substitute for real user testing. Assumptions about what "confuses" a first-time player may be wrong.
- **Score inflation** — simulated persona reviews tend toward optimism; a real first-time player is likely to score lower on game comprehension than the First-Time Player persona did.

### Acceptance Criteria for Phase 2
- [ ] Summary of lowest-scoring areas added to `persona-review-log.md` or captured as known risks in this review pack.
- [ ] Any persona-driven spec changes from the review confirmed as present in the relevant specification documents.

---

## 15. [promoter-score-review.md](promoter-score-review.md)

### Purpose
Rates each of the 10 personas on likelihood to recommend and likelihood to keep playing (0–10), documents what delights them, what frustrates them, what would make them stop playing, and must-improve items. Weighted average: 9.4/10. 18 improvements applied to specifications.

### Key Decisions
- **9.4/10 weighted NPS-style score** — strong result for a specification-stage review. The most common delight: offline-first with no friction. The most common frustration: learning the advanced card types.
- **18 improvements applied** — the review was the most generative improvement pass, driving changes across 8 documents.
- **"What would make them stop" documented per persona** — provides a concrete list of failure modes from the user's perspective (distinct from the technical premortem).
- **Must-improve items consolidated** — items rated as "must-improve before MVP" are documented and should be tracked through Phase 5/6.

### Unresolved Questions
- **What would push from 9.4 to 10.0** — the review identifies delights and frustrations but does not explicitly state what MVP addition or improvement would most move the score. This is useful prioritisation input for Phase 6 polish.
- **Weighted average methodology** — the weighting scheme for the 10 personas is not documented. If certain personas are considered more representative than others, the weighting should be explicit.

### Risks
- **Pre-implementation optimism** — like the persona review, the promoter score is based on specifications, not a working app. Post-implementation scores will likely be lower and should be re-run in Phase 6.
- **Must-improve items implementation tracking** — the 18 improvements are noted as "applied to specifications" but there is no task list confirming each was applied. Some may have been missed.

### Acceptance Criteria for Phase 2
- [ ] Must-improve items from `promoter-score-review.md` verified as present in the relevant specification documents.
- [ ] Plan to re-run promoter score review after Phase 5 (working app) noted in `release-checklist.md`.

---

## 16. [known-issues.md](known-issues.md)

### Purpose
Tracks all known open, resolved, and deferred issues across all phases. Provides a standardised format for issue reporting (ID, severity, phase found, status, description, workaround, resolution).

### Key Decisions
- **Empty at Phase 1 end** — correct. No issues have been found because no code has been written.
- **Standardised format ready** — the format is defined and ready for Phase 2 onwards.
- **Severity levels defined** — `critical`, `high`, `medium`, `low`, `cosmetic`.
- **Status values defined** — `open`, `in-progress`, `resolved`, `wontfix`, `deferred`.

### Unresolved Questions
- None. This document is functioning as intended.

### Risks
- **Issue tracking discipline** — the format is ready but the process for who populates this file (human developer? Claude Code after finding a bug?) and when is not specified. Issues found during Phase 2 development must be logged here promptly, not left as TODOs in code.

### Acceptance Criteria for Phase 2
- [ ] Any bugs found during Phase 2 implementation are logged in `known-issues.md` with correct format before the Phase 2 gate is attempted.
- [ ] No `TODO` or `FIXME` comments in any committed Phase 2 code; all open items must appear in `known-issues.md` instead.

---

## Phase 2 Go / No-Go Summary

Phase 2 may not begin until **all** of the following are true:

### Blocking — resolved before Phase 2

All items below were resolved by applying the Opus review action list (2026-06-21).

| # | Item | Status | Source |
|---|---|---|---|
| A1 | Canonical deck composition table added; "108-card" removed from ux-spec | ✅ Done | game-rules.md §Deck Composition; ux-spec.md |
| A2 | `CardType` defined once with 11 cases; accessibility switches extended | ✅ Done | technical-architecture.md §Model Reference; accessibility-plan.md §12 |
| A3 | Colour type is `CardColour` everywhere; wild representation stated | ✅ Done | technical-architecture.md §Model Reference; accessibility-plan.md §12 |
| A4 | Single RNG algorithm (splitmix64); `SeededRNG(seed:0)` non-degenerate | ✅ Done | technical-architecture.md §8; testing-strategy.md §4 |
| A5 | Seven canonical house rules in all docs; Solo! default resolved | ✅ Done | game-rules.md; ux-spec.md card-set+house-rules screen |
| A6 | One Side-to-Side team geometry; seat→team mapping stated per mode | ✅ Done | game-rules.md §Players and Teams; ux-spec.md Journey 5 |
| A7 | Documents/ persistence path + single `GameSnapshot` schema | ✅ Done | technical-architecture.md §10 and §Model Reference |
| A8 | Concrete `RuleProfile` factory defaults specified | ✅ Done | game-rules.md §RuleProfile Factory Defaults |
| A9 | Model Reference section + authority banners added | ✅ Done | technical-architecture.md §18; all 16 spec docs |
| B5 | Single turn-limit constant (300) | ✅ Done | game-rules.md, ai-strategy.md, testing-strategy.md |
| B6 | Test fixtures use one human + canonical teams [[0,2],[1,3]] | ✅ Done | testing-strategy.md §4 |
| Opus review | Opus review of Phase 1 completed; all required changes applied | ✅ Done | phase-1-opus-review.md |

### Still required before Phase 2 begins

| # | Item | Owner |
|---|---|---|
| Mac round-trip | Empty `Package.swift` + empty `WildPairsCore` + `WildPairsTests` compile; `swift test` runs on Mac | game-engine-engineer (on Mac) |

### Required at Phase 2 gate (before Phase 3)

| # | Item | Gate |
|---|---|---|
| G1 | `Package.swift` with `WildPairsCore` + `WildPairsTests` builds on Mac | Phase 2 |
| G2 | All model types implemented (`Card`, `Deck`, `Player`, `GameState`, `GameAction`, `GameEffect`, `RuleProfile`, `SeededRNG`, `GameSnapshot`) | Phase 2 |
| G3 | `GameEngine.reduce` skeleton handles `newGame`, `drawCard`, `passTurn`, `pauseGame`, `resumeGame` | Phase 2 |
| G4 | `GameStateBuilder` and `CardFactory` implemented and used in tests | Phase 2 |
| G5 | Easy AI implemented; `testAINeverMakesIllegalMove` passes for Easy | Phase 2 |
| G6 | `scripts/` directory contains all 6 quality gate scripts | Phase 2 |
| G7 | `quality_light.sh` runs `swift test` and passes on Mac | Phase 2 |
| G8 | No `TODO` / `FIXME` in committed Phase 2 code; all open items in `known-issues.md` | Phase 2 |

---

*Review pack prepared by: release-manager agent | Phase 1 complete | Phase 2 blocked pending Opus review*
