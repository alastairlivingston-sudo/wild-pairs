# Known Issues

> Owner: qa-lead | Updated: Phase 1 (post-Opus review, 2026-06-21)

## Format
Each issue: **ID** · **Severity** · **Phase found** · **Status** · Description · Workaround · Resolution

Severity: `critical` / `high` / `medium` / `low` / `cosmetic`
Status: `open` / `in-progress` / `resolved` / `wontfix` / `deferred`

---

## Open Issues

_No code bugs yet — no code written. Phase 2 implementation issues will be logged here as they arise._

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
| KI-028 | low | Phase 2 gate | deferred | Mac round-trip not yet run: empty Package.swift + WildPairsCore + WildPairsTests must compile and `swift test` must pass on Mac before Phase 2 code is written | Before Phase 2 code starts |
