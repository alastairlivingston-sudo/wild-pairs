# Wild Pairs — Release Checklist

> Last updated: 2026-06-21  
> How to use: tick off each checkbox as the work is completed. All checkboxes in a phase must be ticked before declaring the phase done and starting the next. Do not tick a box until the work is independently verified.

---

## Phase 0 — Foundation

### Completed work
- [ ] Repository initialised with correct structure (WildPairsCore package + WildPairsApp directory)
- [ ] `Package.swift` created with correct name, platforms (iOS 17+), and targets
- [ ] `WildPairsCore` Swift Package compiles with `swift build`
- [ ] Xcode project created: `WildPairsApp/WildPairsApp.xcodeproj`
- [ ] `WildPairsCore` added as local Swift Package dependency to `WildPairsApp` target
- [ ] Deployment target set to iOS 17.0
- [ ] Device family set to Universal (iPhone + iPad)
- [ ] `PrivacyInfo.xcprivacy` created in app target with correct content (see `docs/privacy-offline-plan.md`)
- [ ] `CLAUDE.md` created with project context and approved command list
- [ ] Core documentation written: `docs/project-structure.md`, `docs/privacy-offline-plan.md`, `docs/permission-audit.md`, `docs/enterprise-build-notes.md`, `docs/testing-strategy.md`, `docs/release-checklist.md`

### Tests
- [ ] `swift build` succeeds with zero errors
- [ ] `swift test` runs and exits cleanly (even with zero tests defined yet)
- [ ] Xcode builds the app target for iPhone 15 simulator without errors
- [ ] Xcode builds the app target for iPad Air simulator without errors

### Documentation
- [ ] `docs/project-structure.md` reviewed and accurate
- [ ] All doc files committed to repository

### Quality gates
- [ ] No third-party Swift Package dependencies (verify `Package.swift` has no remote URLs)
- [ ] No CocoaPods (`Podfile` absent)
- [ ] No Carthage (`Cartfile` absent)
- [ ] `Info.plist` contains no usage description keys
- [ ] `PrivacyInfo.xcprivacy` passes `plutil -lint`

### Sign-off
- [ ] Product Director confirms scope and structure approved
- [ ] QA Lead confirms build environment verified on Mac

---

## Phase 1 — Data Model and Persistence

### Completed work
- [ ] Card model (`Card`, `CardColour`, `CardFace`) defined and conforming to `Codable`
- [ ] All 4 colours defined: Crimson, Cobalt, Jade, Amber
- [ ] All card faces defined: numbers 0–9, Skip, Skip Two, Reverse, Draw Two, Draw Four Wild, Wild, Targeted Draw, Forced Swap, Discard All, Team Play, Team Pass (Side-to-Side only)
- [ ] Standard deck composition defined and verified (count matches expected total)
- [ ] `GameState` model defined and conforming to `Codable`
- [ ] `Settings` model defined and conforming to `Codable`
- [ ] `Statistics` model defined and conforming to `Codable`
- [ ] `PersistenceService` implemented: read/write/delete for all three JSON files
- [ ] `DataResetService` implemented: deletes all three files atomically
- [ ] File paths use `FileManager.default.urls(for: .documentDirectory, ...)`
- [ ] All models implement round-trip encode/decode correctly

### Tests
- [ ] `DeckTests.swift`: standard deck has correct card count
- [ ] `DeckTests.swift`: all 4 colours present in expected quantities
- [ ] `DeckTests.swift`: all action card types present in expected quantities
- [ ] `PersistenceTests.swift`: GameState round-trips through JSON without data loss
- [ ] `PersistenceTests.swift`: Settings round-trips through JSON without data loss
- [ ] `PersistenceTests.swift`: Statistics round-trips through JSON without data loss
- [ ] `PersistenceTests.swift`: loading a missing file returns `.notFound`
- [ ] `PersistenceTests.swift`: loading corrupted JSON returns `.decodingError`
- [ ] `PersistenceTests.swift`: saving and loading produces identical state
- [ ] All persistence tests pass via `swift test`

### Documentation
- [ ] `docs/data-model.md` written (card types, state fields, file schemas)

### Quality gates
- [ ] No `UserDefaults` usage in source (`grep -rE "UserDefaults" WildPairsCore/` returns empty)
- [ ] No network APIs in source
- [ ] Persistence code does not use iCloud APIs

### Sign-off
- [ ] Product Director confirms data model matches game design
- [ ] QA Lead confirms all persistence tests pass

---

## Phase 2 — Core Game Engine

### Completed work
- [ ] `GameRules.validMoves(for:state:)` implemented for all card types and modes
- [ ] Wild card playable on any colour/number
- [ ] Number cards playable when colour or number matches
- [ ] Action cards (Skip, Reverse, Draw Two, etc.) playable when colour matches
- [ ] Draw Four Wild playable only when no other valid card exists (standard rule; house rule variant available)
- [ ] `GameEngine.reduce(state:action:rng:)` implemented as pure function
- [ ] All action card effects implemented:
  - [ ] Skip — correct player skipped
  - [ ] Skip Two — two consecutive players skipped
  - [ ] Reverse — direction flipped (4-player behaviour correct)
  - [ ] Draw Two — next player draws 2, loses turn
  - [ ] Draw Four Wild — next player draws 4, loses turn, colour chosen
  - [ ] Wild — colour chosen by player
  - [ ] Targeted Draw — chosen player draws 2, loses turn
  - [ ] Forced Swap — complete hands exchanged between two players
  - [ ] Discard All — all cards of chosen colour discarded from player's hand
  - [ ] Team Play — both partners draw 1 card
  - [ ] Team Pass — one card passed to partner (Side-to-Side mode only)
- [ ] Draw pile reshuffle when empty implemented
- [ ] Solo! call mechanic implemented (flag management + penalty)
- [ ] Win condition: Standard Teams — both team members empty hand
- [ ] Win condition: All-Wild Teams — same as Standard Teams
- [ ] Win condition: Side-to-Side Teams — same as Standard Teams
- [ ] All three game modes produce correct starting decks

### Tests
- [ ] `ValidMoveTests.swift`: all legal and illegal card combinations tested (100% branch coverage)
- [ ] `CardEffectTests.swift`: each action card effect tested in isolation
- [ ] `WinConditionTests.swift`: all win/no-win scenarios tested (100% branch coverage)
- [ ] All scenario tests implemented and passing (see `docs/testing-strategy.md` Section 5)
- [ ] `testCorruptedSaveHandledGracefully` passes
- [ ] All tests pass via `swift test`

### Documentation
- [ ] `docs/rules.md` written (complete game rules in plain English)

### Quality gates
- [ ] `testAINeverMakesIllegalMove` passes (placeholder AI only, not final AI)
- [ ] `testNoStuckGamesIn100Games` passes for placeholder AI

### Sign-off
- [ ] Product Director plays through a manual test game and confirms rules feel correct
- [ ] QA Lead confirms all scenario tests pass

---

## Phase 3 — AI Players

### Completed work
- [ ] `AIObservation` type defined: contains only information the AI is entitled to see
- [ ] `AIObservation` correctly masks: opponent hand contents, draw pile contents and order
- [ ] `AIObservation` correctly exposes: own hand, discard top, active colour, player count, opponent hand sizes (counts only)
- [ ] Easy AI implemented: plays first valid card; no strategic decisions
- [ ] Medium AI implemented: prefers action cards; avoids playing wilds early
- [ ] Hard AI implemented: tracks colour preferences; uses Draw Four only when advantageous
- [ ] Expert AI implemented: models opponent hand sizes; coordinates with partner; times Solo! calls
- [ ] All AI difficulties implement the `AIPlayer` protocol
- [ ] AI never exceeds `maxDecisionTime` (configurable; default 100 ms)
- [ ] AI chooses colour for wild cards (colour with most cards in hand; Easy picks randomly)
- [ ] AI calls Solo! when appropriate for each difficulty level
- [ ] AI attempts to catch opponents without Solo! call when appropriate

### Tests
- [ ] `AIConstraintTests.swift`: AI never selects a card not in its valid moves set (1,000 games, all difficulties)
- [ ] `AIConstraintTests.swift`: AI observation never exposes opponent hand contents
- [ ] `AIConstraintTests.swift`: AI decision time never exceeds `maxDecisionTime`
- [ ] `BalanceSimulationTests.swift` smoke suite (100 games per pairing): Expert ≥ 60% vs Easy, Hard ≥ 55% vs Easy
- [ ] All scenario tests still passing after AI integration
- [ ] `testAINeverMakesIllegalMove` passes with all four AI implementations
- [ ] `testNoStuckGamesIn100Games` passes for all difficulties

### Documentation
- [ ] `docs/ai-design.md` written (per-difficulty behaviour, observation model)

### Quality gates
- [ ] Balance simulation smoke suite passes all acceptance criteria (see `docs/testing-strategy.md` Section 7)
- [ ] Expert win rate vs Easy ≥ 60% in 1,000-game balance suite

### Sign-off
- [ ] Product Director confirms AI difficulty feels distinct during manual play
- [ ] QA Lead confirms all AI tests pass

---

## Phase 4 — SwiftUI Interface

### Completed work
- [ ] Home screen implemented (New Game, Resume Game, Settings, Stats, Rules buttons)
- [ ] Game setup screen implemented (mode selection, difficulty selection, player name entry)
- [ ] Game table screen implemented (discard pile, draw pile, current player indicator, hand cards)
- [ ] Card view implemented: displays colour (Crimson, Cobalt, Jade, Amber), face value, action name
- [ ] Colour picker overlay implemented (for Wild / Draw Four Wild)
- [ ] Target picker overlay implemented (for Targeted Draw)
- [ ] Hand swap preview implemented (for Forced Swap)
- [ ] Solo! button implemented with appropriate timing
- [ ] Pause / resume / new game controls implemented
- [ ] Settings screen implemented: animation speed, haptics, colour-blind mode, large cards, reduced motion, house rules, reset data
- [ ] Statistics screen implemented
- [ ] Rules / help screen implemented
- [ ] All text localised to `Localizable.strings` (English only for initial release)
- [ ] VoiceOver labels applied to all interactive elements
- [ ] Accessibility identifiers applied to all interactive elements (for UI tests)
- [ ] Large card mode implemented
- [ ] Colour-blind mode implemented (shape/label supplements colour)
- [ ] Reduced motion mode implemented
- [ ] Dynamic Type supported (text scales with system font size)
- [ ] Portrait and landscape layouts implemented for both iPhone and iPad
- [ ] iPad Split View narrow (compact-width) layout handled correctly

### Tests
- [ ] App builds for iPhone 15 simulator without errors
- [ ] App builds for iPad Air simulator without errors
- [ ] App launches without crash on iPhone 15 simulator
- [ ] App launches without crash on iPad Air simulator
- [ ] MTS-001 through MTS-006 manual test scripts pass (see `docs/manual-test-scripts.md`)

### Documentation
- [ ] `docs/ui-component-guide.md` written

### Quality gates
- [ ] Zero SwiftUI deprecation warnings for iOS 17 APIs
- [ ] Zero force-unwraps in UI code
- [ ] VoiceOver: all interactive elements have non-empty accessibility labels

### Sign-off
- [ ] Product Director approves visual design
- [ ] QA Lead confirms Phase 4 manual tests pass on both iPhone and iPad simulators

---

## Phase 5 — Integration and UI Tests

### Completed work
- [ ] `GameViewModel` integrates `GameEngine`, `PersistenceService`, and `AIPlayer`
- [ ] Save-on-background implemented via `sceneDidEnterBackground`
- [ ] Resume-on-foreground implemented via `sceneWillEnterForeground`
- [ ] Corrupted save handled gracefully (prompts new game, does not crash)
- [ ] All three game modes playable end-to-end from home screen through win screen
- [ ] Statistics updated correctly at end of each completed round
- [ ] Reset local data flow implemented and verified
- [ ] XCUITest file created: `CriticalJourneyUITests.swift`
- [ ] UI tests UIT-01 through UIT-12 implemented (see `docs/testing-strategy.md` Section 6)

### Tests
- [ ] All unit and scenario tests still passing
- [ ] All simulation smoke suite tests passing
- [ ] UI tests UIT-01 through UIT-12 passing on iPhone 15 simulator
- [ ] UI tests UIT-01, UIT-02, UIT-03 passing on iPad Air simulator
- [ ] MTS-007 through MTS-016 manual test scripts pass

### Documentation
- [ ] UI test failure triage guide added to `docs/testing-strategy.md`

### Quality gates
- [ ] `testSaveAndResumeAfterColourChoicePending` passes
- [ ] `testSaveAndResumeAfterTargetChoicePending` passes
- [ ] `testCorruptedSaveHandledGracefully` passes

### Sign-off
- [ ] Product Director confirms all game modes playable end-to-end
- [ ] QA Lead confirms UI tests passing and integration complete

---

## Phase 6 — Accessibility and Layout Polish

### Completed work
- [ ] VoiceOver: full game is navigable using VoiceOver only (no touch required)
- [ ] VoiceOver: game status (current turn, active colour, hand size) is announced or accessible on demand
- [ ] VoiceOver: card actions have descriptive labels (e.g. "Skip card, Crimson colour, play this card")
- [ ] Dynamic Type: all text renders correctly at AX3 (largest accessibility size)
- [ ] Colour-blind mode: all game information is conveyed without relying on colour alone
- [ ] Large card mode: all card text and symbols readable without magnification
- [ ] Reduced motion: all state changes are legible without animation
- [ ] iPhone SE layout: no truncation, no overlap, all controls reachable
- [ ] iPhone Pro Max layout: space used appropriately
- [ ] iPad mini layout: correct tablet layout
- [ ] iPad portrait layout: correct
- [ ] iPad landscape layout: correct
- [ ] iPad Split View narrow (compact width): correct layout fallback
- [ ] Rotation during game: state preserved, layout adapts without glitch
- [ ] Haptic feedback implemented and works on physical device

### Tests
- [ ] MTS-017 through MTS-030 manual test scripts pass
- [ ] Xcode Accessibility Inspector: no critical accessibility issues reported
- [ ] All automated tests still passing

### Documentation
- [ ] Accessibility decisions documented in `docs/accessibility-notes.md`

### Quality gates
- [ ] No information conveyed by colour alone (colour-blind mode: WCAG 1.4.1)
- [ ] All interactive elements have non-empty VoiceOver labels
- [ ] All text legible at Dynamic Type AX3

### Sign-off
- [ ] Product Director approves accessibility posture
- [ ] QA Lead confirms MTS-017 through MTS-030 pass

---

## Phase 7 — QA Hardening

### Completed work
- [ ] All known bugs from Phase 1–6 resolved or documented
- [ ] All edge cases identified in testing fixed or documented as known limitations
- [ ] Final balance simulation (1,000 games per pairing) run and results recorded
- [ ] Performance profiling completed: no main-thread hangs during AI turns
- [ ] Memory usage profiled: no leaks detected during extended play sessions
- [ ] Crash-free sessions confirmed across 50+ manual test sessions total

### Tests — Low-permission definition of done

All of the following must be true before Phase 7 is declared complete:

- [ ] App does not ask for any protected-resource permission during normal gameplay
- [ ] No protected-resource usage description keys present in `Info.plist` (`grep -i UsageDescription WildPairsApp/Info.plist` returns empty)
- [ ] No unnecessary entitlements enabled (only `application-identifier` and `get-task-allow`)
- [ ] No background modes enabled (`UIBackgroundModes` key absent from `Info.plist`)
- [ ] No network APIs present in source (`grep -rE "URLSession|URLRequest|Network\." WildPairsCore/ WildPairsApp/` returns empty)
- [ ] No third-party SDKs in project (`Package.swift` has no remote URL dependencies; no `Podfile`; no `Cartfile`)
- [ ] No account/login/cloud dependency (no iCloud, no Game Center, no Sign in with Apple)
- [ ] App builds for iPhone simulator without errors (`xcodebuild build -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'` succeeds)
- [ ] App builds for iPad simulator without errors (`xcodebuild build -destination 'platform=iOS Simulator,name=iPad Air (5th generation),OS=latest'` succeeds)
- [ ] App runs in airplane mode (MTS-016 passes)
- [ ] Save/resume works without iCloud (MTS-015 passes)
- [ ] All unit tests pass (`swift test --package-path .`)
- [ ] Zero illegal AI moves in simulation (1,000-game balance suite)
- [ ] Zero stuck games in simulation (1,000-game balance suite)
- [ ] Known issues documented (see Known Issues register below)
- [ ] `scripts/check_no_network_usage.sh` passes
- [ ] `scripts/check_permissions_minimal.sh` passes
- [ ] MTS-031 through MTS-034 manual test scripts pass

### Documentation
- [ ] Known issues register populated (or confirmed empty)
- [ ] `docs/privacy-offline-plan.md` confirmed current and accurate
- [ ] `docs/permission-audit.md` audit history table updated with Phase 7 entry

### Quality gates
- [ ] All 34 manual test scripts in `docs/manual-test-scripts.md` have been run and results recorded
- [ ] Balance suite results meet acceptance criteria (Expert ≥ 60% vs Easy, Hard ≥ 55% vs Easy)
- [ ] Zero crashes recorded in manual test sessions

### Known Issues Register

| ID | Description | Severity | Resolution / Workaround |
|---|---|---|---|
| — | (none at phase start) | — | — |

### Sign-off
- [ ] Product Director confirms all Phase 7 QA gates met
- [ ] QA Lead confirms all 34 manual test scripts pass and results recorded

---

## Phase 8 — App Store Submission Preparation

### Completed work
- [ ] App Store Connect record created
- [ ] Bundle identifier registered
- [ ] App name "Wild Pairs" confirmed available in App Store Connect
- [ ] Screenshots prepared: iPhone 6.7" (required), iPhone 6.5" (required), iPad 12.9" (required)
- [ ] App preview video prepared (optional)
- [ ] App description written (no mention of UNO, Mattel, or trademarked terms)
- [ ] Keywords list prepared (no competitor trademarks)
- [ ] Privacy policy URL provided (if required for chosen category)
- [ ] Age rating questionnaire completed (expected: 4+)
- [ ] `PrivacyInfo.xcprivacy` confirmed present and correct in app target
- [ ] Release build created (Archive in Xcode)
- [ ] Release build validated in Xcode Organiser (no errors)
- [ ] Release build uploaded to App Store Connect via Xcode Organiser or `altool`
- [ ] App Store Connect review information completed

### Tests
- [ ] Release build (not debug) tested on simulator: app launches and plays correctly
- [ ] Release build: `get-task-allow` entitlement confirmed absent (expected in release)
- [ ] Trademark scan: `grep -rEi "UNO|Mattel" docs/ WildPairsCore/ WildPairsApp/` returns no matches in user-visible content
- [ ] App Store metadata reviewed: no competitor trademarks in title, keywords, or description

### Documentation
- [ ] `docs/app-store-metadata.md` written and reviewed
- [ ] `docs/release-checklist.md` (this file) fully checked with all phases complete

### Quality gates
- [ ] Archive passes Xcode Organiser validation without warnings
- [ ] `PrivacyInfo.xcprivacy` accepted by App Store Connect (no privacy manifest errors)
- [ ] App Store Connect shows "Ready for Review" status

### Sign-off
- [ ] Product Director approves App Store listing content
- [ ] QA Lead confirms release build tested
- [ ] Submission initiated by authorised team member with App Store Connect access
