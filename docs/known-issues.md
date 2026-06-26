# Known Issues

> Owner: qa-lead | Updated: Phase 9 visual overhaul (2026-06-26)

## Format
Each issue: **ID** · **Severity** · **Phase found** · **Status** · Description · Workaround · Resolution

Severity: `critical` / `high` / `medium` / `low` / `cosmetic`
Status: `open` / `in-progress` / `resolved` / `wontfix` / `deferred`

---

## Open Issues

| ID | Severity | Phase found | Status | Description | Workaround |
|---|---|---|---|---|---|
| KI-030 | medium | Phase 9 | open | design-system.md §3's "AX3+ activates large card mode automatically" is not wired to `dynamicTypeSize` anywhere in code — large card mode is currently a manual Settings toggle only | User can manually enable "Large cards" in Settings at large Dynamic Type sizes; not auto-detected |
| KI-035 | low | Phase 9 | open | `testRoundEndCelebrationRenders` (WildPairsUITests) failed once in a full-suite `quality_full.sh` run on the iPad Air 13" destination (150s draw-loop budget not reached) but passed cleanly in ~52s when re-run in isolation on the same destination — consistent with RNG-dependent round length / simulator contention when running back-to-back with the other 17 UI tests, not a Phase 9 layout/logic regression (no code change made) | Re-run the single test in isolation if it fails in a full-suite run; consider raising the 150s budget or seeding a shorter test-only round if this recurs |

---

## Resolved Issues

| ID | Severity | Phase found | Status | Description | Resolution |
|---|---|---|---|---|---|
| KI-001 | critical | Phase 1 | resolved | ISSUE-01: Deck composition undefined; "108-card" in ux-spec | Added canonical deck composition table to `game-rules.md`; removed "108-card" from `ux-spec.md` (2026-06-21) |
| KI-002 | critical | Phase 1 | resolved | ISSUE-02/20: `CardType` defined with 8 cases in accessibility-plan; correct count is 11 | Extended `accessibility-plan.md` §12 to all 11 cases; added canonical definition to `technical-architecture.md` §Model Reference (2026-06-21) |
| KI-003 | high | Phase 1 | resolved | ISSUE-03: `GameColour` vs `CardColour` naming conflict | Standardised on `CardColour` everywhere; renamed in `accessibility-plan.md` §12 (2026-06-21) |
| KI-004 | high | Phase 1 | resolved | ISSUE-04: RNG algorithm conflict — splitmix64 vs xorshift64; xorshift64 degenerate at seed 0 | Standardised on splitmix64 in both `technical-architecture.md` §8 and `testing-strategy.md` §4 (2026-06-21) |
| KI-005 | critical | Phase 1 | resolved | ISSUE-07: House rules in ux-spec (3 rules incl. Jump-in) contradicted game-rules.md (7 canonical rules) | Rewrote `ux-spec.md` house-rules screen and wireframe to list the 7 canonical house rules (2026-06-21) |
| KI-006 | critical | Phase 1 | resolved | ISSUE-08: Side-to-Side team structure — ux-spec said partner is right-seat; game-rules.md says partner is opposite | Standardised on partner-opposite (seats {0,2}/{1,3}) in both docs; clarified "Side-to-Side" refers to card-passing mechanic (2026-06-21) |
| KI-007 | high | Phase 1 | resolved | ISSUE-10: Three different persistence paths and snapshot schemas across documents | Standardised on Documents/ path and single GameSnapshot schema in `technical-architecture.md` §10 and §Model Reference (2026-06-21) |
| KI-008 | medium | Phase 1 | resolved | ISSUE-16: RuleProfile factory defaults unspecified ("configurable" with no defaults) | Added concrete factory defaults table to `game-rules.md` §RuleProfile Factory Defaults (2026-06-21) |
| KI-009 | critical | Phase 1 | resolved | ISSUE-18 (doc): No Model Reference section; no authority banners | Added §Model Reference to `technical-architecture.md`; added authority banner to all 16 spec docs (2026-06-21) |
| KI-010 | high | Phase 1 | resolved | ISSUE-05: Targeted Draw — testing-strategy asserted a turn skip; game-rules.md says no skip | Corrected two scenario test rows in `testing-strategy.md` §5 (2026-06-21) |
| KI-011 | high | Phase 1 | resolved | ISSUE-06: Forced Swap labelled as "wild card" in accessibility-plan; canonical is coloured action card | Fixed `voiceOverDescription` in `accessibility-plan.md` §12 to "action card" (2026-06-21) |
| KI-012 | medium | Phase 1 | resolved | ISSUE-12: Turn limit 1000 in ai-strategy vs 300 elsewhere | Standardised on 300 (`maxTurnsPerRound`) in all documents (2026-06-21) |
| KI-013 | medium | Phase 1 | resolved | ISSUE-11: GameStateBuilder fixture used 2 humans and wrong team indices [[0,3],[1,2]] | Fixed `testing-strategy.md` §4 to one human + canonical teams [[0,2],[1,3]] (2026-06-21) |
| KI-014 | high | Phase 1 | resolved | ISSUE-09: ux-spec Journey 10 showed Solo! auto-calling for human; canonical is manual+timeout | Fixed Journey 10 to show manual 5s countdown tap mechanic (2026-06-21) |
| KI-029 | high | Phase 1 | resolved | OneDrive used as source-sync mechanism; conflict copies and casing differences risked lost edits | GitHub established as single source of truth; OneDrive sync retired. `.gitignore`, `docs/git-workflow.md`, and `enterprise-build-notes.md` §Step 1 updated (2026-06-21) |
| KI-028 | low | Phase 2 gate | resolved | Mac round-trip not yet run: `Package.swift` + `WildPairsCore` + `WildPairsTests` must compile and `swift test` must pass on Mac before Phase 2 code is written | Ran on Mac (Swift 6.3.2, Command Line Tools only). `WildPairsCore` builds clean; `swift test` runs all 13 Phase-2/3 placeholder tests green. Root finding: `WildPairsTests` uses Swift Testing (`import Testing`); on a Command-Line-Tools-only machine `Testing.framework`/`lib_TestingInterop.dylib` are present but not on the default dyld search paths, so **bare `swift test` fails** with "no such module 'Testing'". Added `scripts/swift_test.sh` (derives framework search path + rpaths from `xcode-select -p`) as the canonical, portable test command; bare `swift test` works once full Xcode is installed. No package, manifest, or model change required (`Package.swift` unchanged at tools-version 5.9; zero deps; only `import Foundation` in core). Docs updated: `testing-strategy.md` §9, `enterprise-build-notes.md` §6, `git-workflow.md` (2026-06-22) |
| KI-031 | high | Phase 9 | resolved | Cards clipped off the right edge in portrait: local hand's last card, partner's open hand, and the current-colour indicator were all cut off | Root cause was `HandView`'s fixed-width `ScrollView`+`HStack`, the partner `openHandFan`, and the horizontal `ScrollView` seat wrappers in `GameTableView`. Replaced all three with width-aware overlapping fans / a fixed `GeometryReader` grid that always fits the available width (Phase 9 A5/A6/A7, 2026-06-26) |
| KI-032 | medium | Phase 9 | resolved | Landscape orientation supported but never polished; doubled the layout code and was the source of several of the above clipping paths | Locked to portrait-only (`Info.plist`); removed the landscape branch from `GameTableView` entirely (Phase 9 A1, 2026-06-26) |
| KI-033 | low | Phase 9 | resolved | Card back used `suit.club.fill` (an off-brand real-deck club suit symbol) | Replaced with a branded four-suit/monogram `CardBackView` design (Phase 9 A4, 2026-06-26) |
| KI-034 | high | Phase 9 | resolved | Two bugs only surfaced by simulator/UI-test verification, not code review: (1) the HandView clipping fix (KI-031) still clipped the last hand card off the right edge in practice — a centring `HStack` was sized to the full `GeometryReader` width by its flexible `Spacer`s, then `.padding(.horizontal, 16)` was added on top of that already-full-width container, overflowing 16pt past each screen edge; (2) `HandView`'s `.accessibilityLabel("Your hand, N cards")` was applied directly to a `GeometryReader`, which has no view identity of its own, so the label leaked down and overwrote every individual hand card's accessibility label with the literal string "Your hand, 7 cards" instead of its real card description — caught by `testHandCardsHaveCanonicalAccessibilityLabels` failing in `WildPairsUITests`, not by manual review | (1) Centre the fan by sizing it to the *full* GeometryReader width directly (`.frame(width: geo.size.width, alignment: .center)`) instead of an inner flexible-Spacer `HStack` plus separate padding. (2) Add `.accessibilityElement(children: .contain)` before the label — the documented pattern for giving a container its own summary label while keeping children individually reachable. Both verified via `xcrun simctl io screenshot` (pixel-level edge check) and a full `WildPairsUITests` run (18/18 pass) after the fix (2026-06-26). Lesson: SwiftUI layout/accessibility modifier interactions on non-drawing containers (`GeometryReader`, flexible `Spacer`s) can behave unintuitively — code review alone did not catch either bug; simulator screenshots and the UI test suite did |

---

## Deferred / Won't Fix

These items are acknowledged, non-blocking for Phase 2, and deferred to the phase noted.

| ID | Severity | Blocks | Status | Description | Deferred to |
|---|---|---|---|---|---|
| KI-015 | high | Phase 3 | deferred | ISSUE-05 (B1): Scenario tests for Targeted Draw corrected in docs; must verify in Phase 3 code | Phase 3 — scenario test implementation |
| KI-016 | high | Phase 3 | deferred | ISSUE-06 (B2): Forced Swap coloured-action classification must be reflected in CardFactory and legal-move logic | Phase 3 — rules engine |
| KI-017 | high | Phase 3/5 | deferred | ISSUE-09 (B3): Solo! timeout UX (countdown visual, animation) not yet specified in design-system.md | Phase 5 — UI build |
| KI-018 | medium | Phase 4 | deferred | B4: AI threading model contradicts between state-machine.md ("Expert dispatched to background") and technical-architecture.md ("synchronous <1ms"). Resolve before Phase 4. | Phase 4 — AI implementation |
| KI-019 | medium | Phase 5/6 | deferred | B7: iPad VoiceOver focus order not separately specified for the 4-edge table layout | Phase 6 — accessibility pass |
| KI-020 | high | Phase 3 | deferred | B8: Draw Stacking cross-type rule (Draw Two onto Draw Four) ambiguous | Phase 3 — rules engine |
| KI-021 | high | Phase 3 | deferred | B8: Discard All edge cases (no cards of chosen colour; 1-card-remaining ordering) not fully specified | Phase 3 — rules engine |
| KI-022 | medium | Phase 5 | deferred | ISSUE-14 (C1): PrivacyInfo reason code DDA9.1 may be wrong category — verify at Phase 5 when Xcode project created | Phase 5 — Xcode project |
| KI-023 | low | Phase 2 gate | in-progress | ISSUE-18 (C2): Quality-gate scripts not yet created; Xcode version not pinned. `.gitignore` created (2026-06-21). Scripts remain for Phase 2 gate. | Phase 2 gate — scripts must exist before Phase 2 gate |
| KI-024 | low | — | deferred | ISSUE-15 (C3): App name "Wild Pairs" is working title; final App Store name not decided | Phase 8 — release |
| KI-025 | low | — | deferred | ISSUE-19 (C4): Animation speed enum values differ between privacy-offline-plan (slow/normal/fast) and ux-spec (Normal/Fast/Off) | Phase 5 — UI build |
| KI-026 | low | Phase 4 | deferred | ISSUE-17 (C5): Expert AI helper functions (`partnerHandSize`, `teamProgressScore`, `estimateOpponentResponse`) are placeholders in ai-strategy.md pseudocode — marked Phase 4 to-be-specified | Phase 4 — AI implementation |
| KI-027 | medium | Phase 5 | deferred | B7: Colour-picker popover anchor in ux-spec is ambiguous ("card or fixed point") — should specify single rule | Phase 5 — UI build |

> KI-028 (Mac round-trip gate) moved to **Resolved** on 2026-06-22 — see the Resolved Issues table above.
