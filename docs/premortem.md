# Premortem Report

> Owner: product-director | Run: Phase 1 | Applied to specs: yes

## Purpose
For each specialist role, answer: "Six months from now, this project failed or felt disappointing because…"
Then document the failure mode, severity, likelihood, prevention, spec change needed, and test/quality gate needed.

Severity: `critical` / `high` / `medium` / `low`
Likelihood: `high` / `medium` / `low`
Status: `mitigated` / `open`

---

## 1. Product Director

### Failure 1.1 — Scope creep killed the MVP
**"The project never shipped a playable game because we kept adding features — online multiplayer, custom card editors, stats graphs — instead of finishing the core round loop."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | Enforce MVP scope gate in release-checklist.md §Phase-5 before any new feature work. Product spec §6 explicitly lists non-goals. |
| Spec change | Added explicit non-goals table to product-spec.md. Phase gate requires sign-off before Phase 6 extras. |
| Quality gate | Phase 5 gate: "Can a human play a complete round in all 3 modes?" If no, no new features. |
| Status | mitigated |

### Failure 1.2 — Personal use became a permanent excuse for quality shortcuts
**"The app was always 'good enough for personal use' and never reached the quality level needed for others to enjoy it or for App Store submission."**

| | |
|---|---|
| Severity | high |
| Likelihood | low |
| Prevention | Spec explicitly states "App Store quality codebase from day one." CLAUDE.md reinforces this. |
| Spec change | product-spec.md §4 secondary goal: "App Store quality codebase." All quality gates use production standards, not personal-use exceptions. |
| Quality gate | Each phase gate scored against production standard, not "works for me." |
| Status | mitigated |

---

## 2. UX Lead

### Failure 2.1 — iPad was an afterthought
**"The iPad version was just the iPhone app scaled up. Reviewers noticed immediately. The layout felt cramped and awkward with wasted space."**

| | |
|---|---|
| Severity | high |
| Likelihood | high (common pattern) |
| Prevention | ux-spec.md has 9 dedicated iPad wireframes; design-system.md has distinct device layout decisions; adaptive layout specified per size class. |
| Spec change | ux-spec.md §7 iPad wireframes fully specified with spacious table, side-panel option, larger cards. Phase 5 acceptance: "iPad layout feels intentionally designed." |
| Quality gate | Separate iPad simulator run at Phase 5 gate; ux-review skill invoked for iPad specifically. |
| Status | mitigated |

### Failure 2.2 — The game table was confusing
**"Players couldn't tell whose turn it was, which cards were playable, or what the action prompt was asking them to do."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | ux-spec.md §8 specifies exact action prompt text for every state; playable card highlighting; active player highlight; persistent prompt area. |
| Spec change | Added 15 example prompt strings to ux-spec.md. Illegal card shake + tooltip specified. "One obvious primary action" principle applies to every game table state. |
| Quality gate | MTS-003 (10-turn playthrough) and MTS-004 (full round) manual scripts verify comprehension. First-time player persona review scores UX clarity. |
| Status | mitigated |

### Failure 2.3 — Animation was either too slow or non-existent
**"AI turns took forever and felt robotic. Or we shipped with no animation and the game felt like a spreadsheet."**

| | |
|---|---|
| Severity | medium |
| Likelihood | medium |
| Prevention | motion catalogue in ux-spec.md §10 specifies every animation with exact durations; fast mode halves all durations. |
| Spec change | Animation duration tokens added to design-system.md. AI thinking delays per difficulty specified. Fast mode documented. Reduced motion alternative for every animation. |
| Quality gate | MTS-030 fast AI mode test. Phase 6 includes animation review. |
| Status | mitigated |

---

## 3. iOS Architect

### Failure 3.1 — SwiftUI views directly mutated game state
**"Views called engine functions directly. State became inconsistent. Bugs were impossible to reproduce. The reducer pattern was never fully established."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | technical-architecture.md §4 mandates pure reducer. CLAUDE.md coding style: "Views send GameAction intents; ViewModels dispatch to engine." Phase 2 acceptance: engine must be pure function. |
| Spec change | GameAction enum centralises all mutations. GameEffect returned to ViewModel for side effects. Architecture diagram in tech-architecture.md. |
| Quality gate | ios-architect review agent reviews all view code for direct state mutation. Phase 2 test: engine tests must not import SwiftUI. |
| Status | mitigated |

### Failure 3.2 — The Xcode project was never created cleanly
**"Hand-crafted .pbxproj files had missing references, wrong build phases, and build failures that took hours to debug."**

| | |
|---|---|
| Severity | high |
| Likelihood | high (without mitigation) |
| Prevention | Plan explicitly defers Xcode project creation to Mac in Phase 2 using Xcode's wizard. Package.swift created first and validated. |
| Spec change | docs/project-structure.md §Xcode setup documents the exact wizard steps. enterprise-build-notes.md §3 documents first-time setup. |
| Quality gate | Phase 2 acceptance: `xcodebuild build` succeeds on both iPhone and iPad simulator without errors. |
| Status | mitigated |

### Failure 3.3 — Save/resume was unreliable
**"The game crashed on resume, or saved corrupt state, or lost the current pending decision (colour choice mid-play). Players stopped trusting it."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | state-machine.md documents persistence points for every state. GameSnapshot includes schema version. Corrupted save recovery path documented. Pending decisions saved as part of GameState. |
| Spec change | PersistenceTests target in project structure. MTS-015 (save mid-game and resume) manual test. Phase 3 acceptance: `testSaveAndResumeAfterColourChoicePending` passes. |
| Quality gate | PersistenceTests: encode/decode round-trip for all model types. Corrupted save test. |
| Status | mitigated |

---

## 4. Game Engine Engineer

### Failure 4.1 — The rules engine had hidden state, making bugs unreproducible
**"Card effects had side effects. The engine wasn't a pure function. Some card combinations caused illegal states that only appeared in specific game sequences."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | Engine design is explicitly a pure function `(GameState, GameAction) -> (GameState, [GameEffect])`. SeededRNG allows exact reproduction of any game from a seed. |
| Spec change | technical-architecture.md §4 mandates pure reducer. GameEngine.swift is a struct with static reduce function. |
| Quality gate | All rules tests use deterministic seeds. testForcedSwapExchangesCompleteHands, testReshuffleWhenDrawPileEmpty etc. are in the scenario test list. |
| Status | mitigated |

### Failure 4.2 — Team win condition was never clearly implemented
**"Players didn't understand why the game didn't end when one teammate went out. The team win condition was implemented inconsistently across modes."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | game-rules.md §10 specifies team rules precisely. Win condition per mode in §7. state-machine.md documents `roundEnded` state entry conditions. |
| Spec change | `testTeamWinsOnlyWhenBothPlayersEmpty` and `testPlayerGoesOutButPartnerStillHasCards` in scenario test list. Action prompt shows "Your partner is still playing — keep going!" when one player goes out. |
| Quality gate | WinConditionChecker tests cover all three modes. Phase 3 acceptance: all win condition tests pass. |
| Status | mitigated |

### Failure 4.3 — All-Wild mode was broken because standard match logic was applied
**"In All-Wild mode, cards were incorrectly rejected because they didn't match colour. The mode difference wasn't cleanly handled in the rules engine."**

| | |
|---|---|
| Severity | high |
| Likelihood | high (without mitigation) |
| Prevention | RuleProfile struct captures mode-specific rules. ValidMoveChecker checks `ruleProfile.requiresColourMatch` before rejecting. |
| Spec change | RuleProfile.allWild() factory sets `requiresColourMatch: false, requiresNumberMatch: false`. testAllWildModeEveryCardPlayable scenario test. |
| Quality gate | Dedicated all-wild mode tests in RulesTests target. Phase 3 acceptance: all mode tests pass. |
| Status | mitigated |

---

## 5. AI Gameplay Engineer

### Failure 5.1 — AI made illegal moves, breaking the game
**"An AI player occasionally played a card that didn't match the current colour or wasn't in its hand. The game entered an illegal state."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | GameEngine.isLegalMove() validates every move before applying it. AI calls legalPlays() to get valid candidates. testAINeverMakesIllegalMove runs 1,000 games. |
| Spec change | AIPlayer always selects from `legalPlays(state:for:)` output — never constructs arbitrary GameAction. AIValidityTests assert this. |
| Quality gate | testAINeverMakesIllegalMove (1,000 games, all difficulties, all modes). Zero tolerance. |
| Status | mitigated |

### Failure 5.2 — AI read hidden hand information (cheating)
**"The Hard AI selected its moves based on opponent hand contents. It felt unfair and undermined trust in the game."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | AIObservation struct explicitly excludes opponent hands. AI only receives AIObservation, never GameState directly. |
| Spec change | testAIObservationNeverExposesForbiddenFields test. AIPlayer takes AIObservation parameter, not GameState. |
| Quality gate | AIFairnessTests: assert that opponent hand fields are never populated in AIObservation constructed from any GameState. |
| Status | mitigated |

### Failure 5.3 — Games got stuck — infinite loops between AI players
**"In All-Wild mode with certain AI configurations, a loop of draw cards resulted in a game that never ended. The deck was exhausted and reshuffled indefinitely."**

| | |
|---|---|
| Severity | critical |
| Likelihood | low |
| Prevention | GameSimulator includes a max-turn limit (300). testNoStuckGamesIn100Games asserts no game times out. |
| Spec change | GameEngine must detect reshuffle loop and trigger game end with current score if max turns exceeded. Edge case documented in game-rules.md §13. |
| Quality gate | testNoStuckGamesIn100Games and BalanceSimulationTests both assert zero stuck games. |
| Status | mitigated |

---

## 6. QA Lead

### Failure 6.1 — No tests were written until the end
**"The rules engine accumulated bugs during development. By Phase 7, fixing one bug broke three others. There was no regression safety net."**

| | |
|---|---|
| Severity | critical |
| Likelihood | high (without discipline) |
| Prevention | Phase 2 acceptance explicitly requires EngineTests passing before Phase 3 begins. Each card effect in Phase 3 must have a passing test. |
| Spec change | testing-strategy.md mandates test-per-feature: each card type must have a test before it's considered implemented. |
| Quality gate | `swift test` must pass at start of every phase. quality_light.sh runs tests after every significant edit. |
| Status | mitigated |

### Failure 6.2 — The simulator ran but real devices had layout issues
**"The iPhone SE layout was never tested. Text was clipped. The colour picker was too small. Real users found these on Day 1."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | Manual test scripts cover iPhone SE (MTS-017), large iPhone (MTS-018), all iPad sizes (MTS-019–022). Phase 5 acceptance: "No key controls awkwardly stretched, clipped, or unreachable." |
| Spec change | ux-spec.md includes SE-specific notes per screen. design-system.md documents small-screen approach. |
| Quality gate | Phase 5: run on both iPhone SE simulator AND iPad simulator before gate passes. |
| Status | mitigated |

---

## 7. Accessibility Lead

### Failure 7.1 — VoiceOver made the game unplayable
**"VoiceOver users couldn't play the game. Card labels were missing or meaningless. Turn state wasn't announced. There was no way to play a card without sight."**

| | |
|---|---|
| Severity | critical |
| Likelihood | high (if left to Phase 6) |
| Prevention | accessibility-plan.md specifies VoiceOver label patterns for every card type. Custom actions: "Play card", "Card details". Live region announcements for turn changes. Phase 6 acceptance: VoiceOver can play a complete round. |
| Spec change | Accessibility labels designed as part of Card model — accessibilityLabel is a first-class field. Not retrofitted. |
| Quality gate | MTS-024 VoiceOver full game navigation. MTS-025 hear game status on demand. Both must pass at Phase 6 gate. |
| Status | mitigated |

### Failure 7.2 — Colour-blind mode was added as a cosmetic option but didn't actually work
**"Colour-blind mode just added text labels to cards, but the colour indicator, current colour chip, and discard pile were still colour-only. The game was still unplayable."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | accessibility-plan.md §5 specifies colour-blind mode must affect: cards, colour indicator, discard pile, all colour chips. "Never colour-only" is an experience principle. |
| Spec change | Design system specifies pattern fills as alternative. Symbols (Flame, Wave, Leaf, Sun) are always visible by default, not just in colour-blind mode. |
| Quality gate | MTS-028 colour-blind mode test verifies every game element independently of colour. |
| Status | mitigated |

---

## 8. Performance & Reliability Lead

### Failure 8.1 — The app crashed when backgrounded during an AI turn
**"The app was backgrounded while an AI was 'thinking'. On resume, the game state was corrupt or the UI was frozen on the AI thinking indicator."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | AI thinking is a simple timed delay, not a background thread lock. state-machine.md specifies autosave on entering `awaitingAITurn`. On resume, the AI move is recalculated from the saved GameState. |
| Spec change | App lifecycle: `sceneWillResignActive` triggers synchronous save. On foreground resume, if state is `awaitingAITurn`, dispatch AI move recalculation. No background threads that can leave state dirty. |
| Quality gate | MTS-015 save mid-game and resume. Phase 5 acceptance: app state survives backgrounding during AI turn. |
| Status | mitigated |

### Failure 8.2 — Animations caused frame drops on older devices
**"The deal animation and card play animation ran at 40fps on iPhone SE. The game felt laggy and cheap."**

| | |
|---|---|
| Severity | medium |
| Likelihood | low |
| Prevention | Animations use SwiftUI's built-in animation system (no custom CALayer animations). Motion is simple translation/opacity. Reduced motion mode eliminates all animations. |
| Spec change | design-system.md animation tokens use `.spring()` modifiers, not custom `UIView.animate`. No GPU-intensive effects (no blur, no shadow animation). |
| Quality gate | Phase 6: run on iPhone SE simulator and verify UI remains responsive during deal. |
| Status | mitigated |

---

## 9. Privacy & Brand Safety Lead

### Failure 9.1 — A network call crept in
**"A crash reporter SDK was added during Phase 7 QA 'just for debugging'. It made network calls and could have triggered App Tracking Transparency. The offline guarantee was broken."**

| | |
|---|---|
| Severity | critical |
| Likelihood | medium |
| Prevention | CLAUDE.md explicitly lists prohibited frameworks. check_no_network_usage.sh runs at every phase gate. No third-party SDK can be added without explicit approval. |
| Spec change | privacy-offline-plan.md §6: no third-party SDKs. Network scan script. CLAUDE.md enterprise constraints section. |
| Quality gate | check_no_network_usage.sh must return PASS at every phase gate. Phase 7 acceptance: zero network APIs. |
| Status | mitigated |

### Failure 9.2 — A doc or UI string used "UNO" or a Mattel trademark
**"A test file used 'UNO' in a comment. A rules screen said 'like UNO but for teams.' App Store review rejected the app for trademark reference."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | CLAUDE.md legal section. privacy-offline-plan.md trademark scan command. All docs use original terminology. |
| Spec change | Trademark grep command added to check_privacy_manifest.sh and release-checklist.md Phase 8. privacy-brand-safety-lead agent specifically reviews all user-facing text. |
| Quality gate | `grep -r "UNO\|Mattel\|mattel\|uno" docs/ WildPairsCore/ WildPairsApp/` must return zero results at Phase 8 gate. |
| Status | mitigated |

---

## 10. Enterprise Build Lead

### Failure 10.1 — An Xcode capability was automatically added and triggered a provisioning error
**"Xcode silently enabled iCloud when we added a file (it did this before in a team project). The project now required an entitlement we didn't want. Enterprise policy blocked the build."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | enterprise-build-notes.md §10 documents 21 capabilities to never enable. check_project_capabilities.sh scans entitlements after every build. Simulator-first avoids provisioning. |
| Spec change | Phase 2 and Phase 5 gates: run check_project_capabilities.sh and verify PASS before advancing. |
| Quality gate | check_project_capabilities.sh must PASS at every phase gate from Phase 5 onward. |
| Status | mitigated |

### Failure 10.2 — The project required a physical device or Apple Developer account to build
**"The project used a capability or entitlement that required a paid Developer account. The simulator build failed. The user couldn't run the app at all without setting up signing."**

| | |
|---|---|
| Severity | high |
| Likelihood | low |
| Prevention | Simulator-first strategy. Zero special entitlements. enterprise-build-notes.md explains why no Developer account is needed for simulator. |
| Spec change | Phase 5 acceptance explicitly states: "App builds for iPhone simulator without errors" and "App builds for iPad simulator without errors" — without requiring a paid Developer account. |
| Quality gate | Phase 5 build gate uses simulator destination only. Physical device steps documented as optional. |
| Status | mitigated |

---

## 11. Release Manager

### Failure 11.1 — Documentation was out of date at handover
**"The release-checklist.md still referenced Phase 3 todos. The README described the old architecture. The user opened Xcode and nothing matched the docs."**

| | |
|---|---|
| Severity | high |
| Likelihood | medium |
| Prevention | Each phase gate requires doc update as part of completion. release-manager agent reviews doc completeness. |
| Spec change | release-checklist.md §Phase-8 includes: "All docs reflect current implementation." Phase 8 doc review is mandatory. |
| Quality gate | Phase 8 gate: release-manager agent reviews all docs vs. current code structure and reports discrepancies. |
| Status | mitigated |

---

## Summary of Spec Changes Applied

| Change | Document updated |
|---|---|
| Non-goals table added | product-spec.md |
| iPad wireframes fully specified | ux-spec.md |
| 15 example action prompt strings specified | ux-spec.md |
| All-Wild mode RuleProfile documented | game-rules.md, state-machine.md |
| Max-turn limit (300) for stuck-game detection | game-rules.md |
| accessibilityLabel as first-class Card field | technical-architecture.md |
| App lifecycle save/resume for AI turn background | state-machine.md |
| Trademark grep added to release checklist | release-checklist.md |
| 21 forbidden capabilities documented | enterprise-build-notes.md |
| check_project_capabilities.sh in every post-Phase-5 gate | release-checklist.md |

All changes have been applied to the relevant documents. The premortem finds all critical failure modes mitigated before Phase 2 begins.
