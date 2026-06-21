# Wild Pairs — Phase 1 Opus Review Brief

> Prepared by: release-manager | Audience: Opus (senior multi-role review) | Blocking: Phase 2 start

---

## Context

Wild Pairs is an offline Universal iOS/iPadOS 2v2 team card game (one human, three AI). It is an original colour-and-number shedding card game — legally and visually distinct from any existing game. The project is built with Swift 5.9+ / SwiftUI, targeting iOS 17+, with no third-party dependencies, no internet connectivity, no accounts, and no special App Store entitlements.

Phase 0 (repository scaffold) and Phase 1 (complete specifications) are finished. No code has been written yet. Phase 2 (core engine implementation) is blocked until this review is complete and any required changes are applied.

The specifications are in the `docs/` directory. Read these before reviewing:

- [product-spec.md](product-spec.md)
- [ux-spec.md](ux-spec.md)
- [design-system.md](design-system.md)
- [game-rules.md](game-rules.md)
- [technical-architecture.md](technical-architecture.md)
- [state-machine.md](state-machine.md)
- [ai-strategy.md](ai-strategy.md)
- [testing-strategy.md](testing-strategy.md)
- [accessibility-plan.md](accessibility-plan.md)
- [privacy-offline-plan.md](privacy-offline-plan.md)
- [permission-audit.md](permission-audit.md)
- [enterprise-build-notes.md](enterprise-build-notes.md)
- [premortem.md](premortem.md)
- [persona-review-log.md](persona-review-log.md)
- [promoter-score-review.md](promoter-score-review.md)
- [known-issues.md](known-issues.md)

For additional context: [CLAUDE.md](../CLAUDE.md) and [phase-1-review-pack.md](phase-1-review-pack.md).

---

## Review Instructions

Review Phase 1 **ten times**, once from each of the specialist perspectives below. For each role:

1. State your role at the top of the section.
2. List **findings** — specific issues, ambiguities, gaps, or risks you identified.
3. For each finding: rate it **blocking** (must fix before Phase 2), **important** (should fix before Phase 2 gate), or **advisory** (can address later).
4. Recommend the **exact change** needed to each relevant document.
5. End with a one-sentence overall verdict: Ready / Ready with changes / Not ready.

Do not repeat findings across roles. If a finding appears in role 1, subsequent roles should cross-reference it rather than repeat it.

---

## Role 1 — Principal iOS Engineer

Focus on the technical architecture and implementation feasibility.

Look specifically for:
- Is the `(GameState, GameAction) -> (GameState, [GameEffect])` pure reducer design sound for a turn-based card game? Any cases where the pure-function constraint will be hard to maintain?
- Is the `WildPairsCore` / `WildPairsApp` module boundary clean? Can `WildPairsCore` really depend only on `Foundation` for all 11 card types and all three game modes?
- `GameState` has 14 fields including `eventLog: [GameEvent]` (excluded from `Equatable`). Is the `Equatable` exclusion documented as an intentional invariant, or is this a bug waiting to happen in snapshot comparison tests?
- The RNG reconstruction strategy uses `actionCount` to fast-forward from the seed. For a 300-turn game, this calls `next()` 300 times on resume. Is this acceptable performance? What is the cost of the alternative (serialising live RNG state)?
- `GameAction.forceState` is a debug-only case in a `Codable` enum. How is this excluded from the release `Codable` implementation? The document is vague on this.
- `@MainActor` on `GameViewModel` with synchronous engine calls — will Expert AI's bounded lookahead cause visible main-thread stalls? What is the realistic worst-case compute time for Expert lookahead at the bounds described?
- The `AVFoundation` framework is listed for sound playback. Confirm that `AVAudioSession` category configuration for sound playback does not require `NSMicrophoneUsageDescription`. Any risk here?
- Swift 6 concurrency: the docs say "actor-isolated engine where practical" but the engine is currently a `static func` on a `struct`. What is the actual Swift 6 migration path? Is this deferral acceptable?

---

## Role 2 — Lead UX Designer

Focus on the user experience specification and interaction design.

Look specifically for:
- Are all 17 user journeys complete? Do they cover the edge cases introduced by advanced card types — specifically Discard All (colour choice mid-resolution), Forced Swap (target selection affecting both players' Solo! status), and Skip Two (the "you will skip your partner" scenario)?
- The Solo! button has a configurable timeout but no default value is specified and no visual countdown mechanism is designed. This is a real-time interaction with penalty consequences — the UX for it needs to be locked before Phase 5. What is missing?
- What does the human player see while three AI players take their turns? The motion catalogue specifies AI delays but the visual state of the table during AI play (card animations, prompt area text, player highlight state) is not fully described.
- The colour/target picker "cannot be cancelled once committed" — but what happens if the user backgrounded the app while the picker was open? The state machine says the pending decision is saved. When the user relaunches, does the picker re-appear? Is re-appearing mid-picker after app restore a good UX?
- The onboarding journey exists but the depth of the tutorial is unspecified. For a beginner using only the Beginner card set, is the onboarding flow sufficient to start playing without reading the rules? What is missing?
- Are there dead-end states the user cannot escape from? Review each state in `state-machine.md` and confirm every state has a visible escape route.
- The "Partner is still playing — keep going!" message when one teammate goes out is specified in `premortem.md`. Is this message specified in `ux-spec.md`? Is it prominent enough that a new player won't be confused by the game not ending when they go out?

---

## Role 3 — iPad Product Designer

Focus on the iPad-specific experience.

Look specifically for:
- The iPad layout places hands at all four edges (bottom = human, top = partner, left/right = opponents). On a 12.9" iPad in landscape, how many cards can be shown per hand before overflow? The spec says cards scroll horizontally but a 4-player game with 7-card starting hands plus draws may need a specific overflow strategy.
- iPad wireframes in `ux-spec.md` are ASCII art — sufficient for layout decisions but not for visual hierarchy. What visual hierarchy decisions are underspecified that could cause implementation ambiguity?
- On iPad, action sheets appear as popovers. The colour picker and target picker are described as popovers — where exactly are they anchored? (Anchored to the wild card, to the discard pile, to the player zone?) The anchor matters for avoiding coverage of important game information.
- iPad Split View: `state-machine.md` says the game pauses on secondary-window interaction. Is there a pause screen wireframe for this scenario? Is the pause state visually distinct from an in-game pause (from the pause button)?
- The iPad table layout with hands at all four edges creates a VoiceOver traversal problem. The VoiceOver focus order for the iPad layout is not specified in `accessibility-plan.md`. This is a gap — specify it.
- Large Card mode on iPad: does the large card mode change only card face size, or does it also change the number of cards visible in the hand at once? On iPad there is room for a more generous large-card layout than on iPhone.

---

## Role 4 — Game Systems Designer

Focus on the rules completeness, consistency, and playability.

Look specifically for:
- **Deck composition gap** — `game-rules.md` describes all 11 card types but never specifies the total deck size or card counts per type. This is a blocking gap. The engine's `CardFactory` and `Deck` cannot be implemented without canonical numbers. Provide a recommended deck composition for each card set or flag this as the highest-priority blocking gap.
- **Draw Stacking cross-type ambiguity** — the house rule says Draw Two and Draw Four can be stacked, with "colour-type matching still applies". Can a Draw Four stack onto a Draw Two of matching colour? Can a Draw Two stack onto a Draw Four? The rule is ambiguous and the engine will need a concrete answer.
- **Skip Two team-targeting consequence** — in clockwise direction, a Skip Two played by the human skips Left Opponent and Partner. This means the human's own partner is skipped, which is a significant strategic penalty. Is this intended? Is it communicated clearly enough in the rules and the UX prompt?
- **Discard All sequence completeness** — the rules specify "choose a colour → discard all of that colour". But what if the player has no cards of the chosen colour? Is that an illegal choice (the prompt only shows colours the player holds) or a legal choice with no effect? What if Discard All is played and the player holds only one colour — does the choice UI even appear, or is it auto-resolved?
- **Team Play default variant** — `product-spec.md` and `game-rules.md` describe two variants (both-draw vs. partner-plays-immediately). Which is the default? The documents are not fully consistent on this.
- **Forced Swap + out player** — `game-rules.md` states "a player who went out cannot be targeted by Targeted Draw, Forced Swap, or similar cards once they are out." But in the Standard Teams win condition, both teammates must go out. So a player goes out, their partner continues. Can the opponents target the partner with Forced Swap to swap them with the already-out player? What does the out-player's hand look like (empty)?
- **All-Wild mode and wild card colour choice** — the rules note that in All-Wild mode, colour choice still happens but "the colour does not restrict the next player's options." If colour choice has no effect on play, is there any gameplay reason to make it? Should wild cards in All-Wild mode skip the colour choice entirely?
- **Round vs. game end** — `game-rules.md` describes round end and game end but the scoring mode round-restart sequence (reshuffle, re-deal, increment round counter, re-present setup or auto-restart?) is not specified.

---

## Role 5 — AI Gameplay Engineer

Focus on the AI design, fairness, and implementation feasibility.

Look specifically for:
- **AIObservation and Discard All** — when a Discard All card is played, all discarded cards are public. Does `AIObservation.playedCardHistory` capture this correctly? After a Discard All, the AI knows the discarded cards came from a specific player's hand — is this information correctly exposed or correctly masked?
- **AIObservation and Forced Swap** — after a Forced Swap, both hands are legally revealed to the swapping players. How long does this revealed information persist in `AIObservation`? For the rest of the round? Until the next draw?
- **Expert AI lookahead depth** — "bounded depth" is described but the bound is never specified. A depth-3 lookahead in a 4-player game with 7 cards per player and 11 card types has a combinatorial explosion. What is a realistic depth that produces strong play without exceeding a ~100ms compute budget on an iPhone SE?
- **Easy AI in All-Wild mode** — in All-Wild mode, every card is legal. Easy AI selects randomly from all cards. This means Easy AI never uses action cards strategically and may play Change Colour on a wildly unhelpful colour. Is this the intended Easy experience in All-Wild mode, or should Easy AI have a minimum baseline (e.g., always plays a number card first if available)?
- **`testAINeverMakesIllegalMove` for 1,000 games** — is 1,000 games per difficulty per mode (12,000 total games) a reasonable CI runtime? What is the expected runtime of this test suite on an M-series Mac? If it takes more than a few minutes, it may not belong in the standard `swift test` run.
- **Partner identity in multi-player AI** — in a 4-player game, the AI at index 1 (Left Opponent) has a partner at index 3 (Right Opponent). Medium and Hard AIs are described as having "partner awareness." Is the partner relationship encoded in `AIObservation.teamState`? If so, confirm that each AI instance correctly identifies its own partner.
- **Balance simulation acceptance criteria** — the docs say "statistically significant sample" without a number. Recommend a specific game count (e.g., 500 games per pairing) and a specific minimum win-rate delta between adjacent difficulties (e.g., each level must win at least 5% more often than the level below it against a fixed opponent).

---

## Role 6 — QA Lead

Focus on testability, coverage gaps, and quality gate enforcement.

Look specifically for:
- **Missing scenario tests** — the 23 named scenario tests are listed but several card-type interactions may not be covered. Check specifically: Forced Swap + Solo! in the same turn (both players' Solo! status re-evaluated), Draw Stacking across a chain of 3+ players, Skip Two applied when turn direction is counter-clockwise (who is skipped?), Discard All on the last 1 card (win via Discard All), Team Play when partner is already out.
- **`testSaveAndResumeAfterColourChoicePending`** — this test is named in the premortem. Confirm it appears in the 23 scenario tests or add it. This is a critical path for save/resume correctness.
- **Simulation test runtime budget** — a test suite that runs 1,000 games 12 times may take minutes. Is this run as part of `quality_light.sh` or only `quality_full.sh`? This needs to be explicit.
- **UI test fragility** — the 12 XCUITest scenarios depend on dynamic game state. A fixed seed is used, but if the seed + mode + difficulty combination doesn't produce a deterministic UI sequence (e.g., if the AI delay timer affects test timing), the test may be flaky. How is test flakiness mitigated?
- **Coverage target quantification** — "full coverage for state transitions" is stated but a percentage target is not. Recommend adding an explicit coverage floor (e.g., 90% line coverage for `WildPairsCore`) and making it machine-checkable with `swift test --enable-code-coverage`.
- **No CI on Windows** — the development workflow has no automated CI. Recommend a minimum manual testing cadence (e.g., `swift test` must be run and pass before any PR/commit is finalised on Mac) and document this in `enterprise-build-notes.md`.
- **Known-issues discipline** — the process for logging issues in `known-issues.md` is undefined. Who is responsible? When? Add a one-paragraph process to `known-issues.md`.

---

## Role 7 — Accessibility Lead

Focus on VoiceOver completeness, Dynamic Type, colour-blind mode, and Reduce Motion.

Look specifically for:
- **VoiceOver announcement queue management** — when three AI players take consecutive turns rapidly, VoiceOver may announce three "Player X played card Y" announcements in quick succession. Does iOS interrupt the current announcement for the next? Does the queue overflow? The plan does not address announcement rate limiting or queuing strategy.
- **iPad VoiceOver focus order** — the accessibility plan specifies focus order for iPhone but not for iPad's 4-edge table layout. This is a blocking gap. Specify the focus order for the iPad game table explicitly: which zone is traversed first, how does the user navigate between the four player zones, and where does focus return after a card is played?
- **Dynamic Type at Accessibility sizes** — at the two largest iOS Accessibility Dynamic Type sizes (AX4 and AX5), card face content (symbol + number + colour name) will overflow a fixed-size card face. The plan acknowledges that layouts reflow but does not specify how card faces handle this. Options: truncate, scale card face, show label only, show number only. Pick one and specify it.
- **Large Card mode + colour-blind mode interaction** — both modes affect card visual appearance. Are they additive (large card size AND pattern fills AND larger symbols)? Or does one override the other? The specs do not address both-active state.
- **Colour-blind pattern fills at iPhone SE card size** — the four patterns (diagonal hatching, horizontal lines, vertical lines, dots) must be distinguishable at the smallest card dimension on iPhone SE. The design-system.md specifies the patterns but not minimum line spacing or density. Risk: patterns may be indistinguishable at small size. Add minimum pattern density specifications.
- **Solo! button accessibility** — the Solo! button appears when the human's hand drops to 1 card. VoiceOver must announce the Solo! requirement and focus the button. The plan describes the announcement but not the VoiceOver focus behaviour. Does focus jump to the Solo! button automatically, or must the user swipe to find it?
- **Skipped-player VoiceOver announcement** — when the human player's turn is skipped (Skip or Skip Two), VoiceOver must announce this prominently. The accessibility-plan.md covers Solo! announcements but does not explicitly cover skip announcements. Confirm these are in the plan and add them if missing.

---

## Role 8 — Privacy & Brand Safety Lead

Focus on the offline guarantee, data minimisation, and trademark/brand safety.

Look specifically for:
- **`PrivacyInfo.xcprivacy` required-reason APIs** — the template is prepared but the final API list depends on implementation. The key risk: `FileManager.attributesOfItem(atPath:)` uses `NSFileSystemFreeSize` which requires a declared reason. Is this API used in the persistence layer? List every Foundation API that Wild Pairs uses that may trigger a required-reason declaration and verify each is in the template.
- **`AVAudioSession` and privacy** — `AVFoundation` is used for sound playback. Confirm that calling `AVAudioSession.sharedInstance().setCategory(.playback)` does not trigger any microphone permission check or require `NSMicrophoneUsageDescription`.
- **Statistics data minimisation** — `wildpairs-stats.json` is described as storing "aggregated statistics" but the schema is not defined. Define the exact fields. Are game timestamps stored? Are turn counts per game stored? Every field should be justified against the minimum-necessary principle.
- **App Store "No data collected" label correctness** — the strongest possible privacy declaration. Confirm that the `EventLog` in debug builds does not contain player-identifiable information. Even debug-only data should respect privacy principles.
- **Trademark scan completeness** — the grep command `grep -r "UNO|Mattel|mattel|uno"` is specified. But the related game genre has additional trademark risks: "Go Out" (common phrase but associated with some games), "Wild card" (generic), and the specific action card names used. Review all 11 card type names against the trademark register to confirm none are protected. The custom names (Skip Two, Team Play, Forced Swap, Targeted Draw, Discard All) appear original — confirm.
- **App name trademark** — "Wild Pairs" and "Chromatic" should be checked against the App Store and trademark register before the app name is finalised.

---

## Role 9 — Enterprise Build Lead

Focus on the build workflow, Xcode project setup, and zero-friction build environment.

Look specifically for:
- **`Package.swift` to Xcode project transition** — Phase 2 delivers `Package.swift` + `WildPairsCore`; Phase 5 adds the Xcode project. The transition from package-only to package-plus-Xcode-project must be documented precisely. Specifically: does adding the Xcode project require any changes to `Package.swift`? Are there known Xcode wizard steps that can silently enable unwanted capabilities?
- **`.gitignore` correctness** — before the Xcode project is created in Phase 5, the `.gitignore` must correctly exclude `*.xcuserstate`, `DerivedData/`, `.build/`, `.swiftpm/configuration/`, and any Xcode-generated scheme files that should not be committed. Review the current `.gitignore` (if it exists) and confirm it is complete.
- **OneDrive conflict risk** — if a Swift file is edited by Claude Code on Windows while Xcode has it open on Mac, OneDrive may create a conflict copy (`filename (Alastair's MacBook conflict).swift`). This could introduce a non-compiling duplicate file into the package. Document a workflow procedure to prevent this (e.g., always close Xcode before editing on Windows).
- **Script executability** — the `scripts/` shell scripts must be marked executable (`chmod +x`) before they can be run on Mac. Scripts committed without the executable bit will fail silently. Confirm this is handled in the setup procedure.
- **Xcode version** — `enterprise-build-notes.md` specifies Xcode 15+ but Swift Package syntax and SwiftUI APIs can differ between Xcode 15 and Xcode 16. Pin a minimum Xcode version (e.g., Xcode 15.4 or Xcode 16.0) and document it.
- **Physical device signing** — documented as "optional". If the developer wants to test on a real device, what is the minimum setup required? (Personal team certificate? Free Apple ID? Paid developer account?) The notes say "document separately" but this documentation doesn't exist yet. Add a one-paragraph summary.

---

## Role 10 — Release Manager

Focus on documentation completeness, phase gate clarity, and handover readiness.

Look specifically for:
- **Phase gate completeness** — `release-checklist.md` gates are listed but have you verified that every blocking item in `phase-1-review-pack.md` appears in the Phase 2 section of `release-checklist.md`? If not, the gate will be passed without resolving blocking items.
- **Document cross-consistency** — check that the following are consistent across all 16 documents: card type names (all 11), game mode identifiers (`standardTeams`, `allWild`, `sideToSide`), colour names (Crimson, Cobalt, Jade, Amber), difficulty level names, house rule names. A single inconsistency in a doc becomes a source-of-truth dispute during implementation.
- **Solo! mechanic naming** — the mechanic is called "Solo!" throughout. Confirm this name appears consistently (with the exclamation mark, with the capital S) in all 16 documents. Name inconsistency in documentation becomes naming inconsistency in code.
- **Missing documents** — are there any documents referenced in CLAUDE.md or the phase gate checklists that do not yet exist? Specifically: `docs/project-structure.md` is referenced in `premortem.md`. Does it exist?
- **Phase 1 spec version tracking** — the specs have no version number or last-modified date. If the Opus review requires changes, how will the team know which version of a spec is current? Recommend adding a brief "last updated" line to each spec or relying on git history (which is more robust).
- **`release-checklist.md` Phase 2 section** — review the Phase 2 section of `release-checklist.md` and confirm it maps to the acceptance criteria in `phase-1-review-pack.md`. Any Phase 2 acceptance criterion not in the checklist is a gap.
- **Post-Opus update procedure** — once the Opus review is complete, who applies the required changes? Are the changes applied to the specs directly, with git commits? Should a `phase-1-changes.md` be created to track what was changed in response to the review? Recommend a simple procedure.

---

## Expected Output Format

Return findings in this structure:

```
## Role N — [Role Name]

### Findings

#### F[N.1] — [Short title] | [blocking / important / advisory]
[Description of the finding]
**Required change:** [Exact document and change needed]

#### F[N.2] — ...

### Verdict: [Ready / Ready with changes / Not ready]
[One sentence justification]
```

At the end of all 10 roles, provide:

```
## Overall Phase 1 Assessment

**Blocking findings:** [count]
**Important findings:** [count]
**Advisory findings:** [count]

**Phase 2 gate:** [Open / Blocked]

**Recommended next steps:** [Ordered list of actions before Phase 2 begins]
```

---

## What Opus Should NOT Do

- Do not write any Swift code.
- Do not propose changes to the architecture that would require major restructuring of already-agreed decisions (the pure reducer, the module split, the MVVM pattern). Flag concerns about these decisions but treat them as settled unless a critical correctness issue is found.
- Do not add features or expand scope. Flag any spec that implies scope beyond the MVP but do not recommend including the expanded scope.
- Do not produce a finding that is already listed as a known unresolved question in `phase-1-review-pack.md` unless you have a specific recommended resolution. Cross-reference the review pack instead.

---

*Brief prepared by: release-manager | Phase 2 blocked until this review is complete and changes applied*
