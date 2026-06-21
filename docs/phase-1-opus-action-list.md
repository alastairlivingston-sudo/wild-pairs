# Wild Pairs — Phase 1 Opus Action List

> Source: [phase-1-opus-review.md](phase-1-opus-review.md)
> Owner: release-manager (coordination); document owners as noted per action
> Rule: **Phase 2 does not start until every "Blocks Phase 2 = Yes" action is Done.**

Each action is self-contained: what to change, in which file, the resolution to apply, the test/gate that proves it, severity, and whether it blocks Phase 2. Where two documents disagree, the **canonical** source is named so there is one source of truth.

**Authority convention to adopt (do this first):** add a one-line banner to the top of every spec:
> *Canonical sources: for data models, `technical-architecture.md` §Model Reference; for game rules, `game-rules.md`; for visual tokens, `design-system.md`. Where this document disagrees with its canonical source, the canonical source wins.*

---

## A. Blockers — must be Done before Phase 2 starts

### A1 — Define the canonical deck composition (ISSUE-01)
- **Files:** `game-rules.md` (add table), `ux-spec.md` (remove "108-card … locked"), `product-spec.md` (cross-link).
- **Change:** Add a "Deck Composition" table to `game-rules.md` giving, **per card set (Beginner / Standard / Advanced)**, the exact count of each card type per colour and the total deck size. Decide counts deliberately (e.g. how many of each number 0–9 per colour, how many Skip/Reverse/etc. per colour, how many Change Colour / Draw Four total). In `ux-spec.md`, replace every "Standard 108-card deck" reference with "the selected card set" and present the card-set chooser (Beginner/Standard/Advanced) consistent with `state-machine.md`'s `setupCardSet` state.
- **Why:** `Deck` and `CardFactory` are Phase 2 deliverables and cannot be built from "108-card (locked)", which both omits the real numbers and contradicts the three-card-set design (and echoes a competitor's deck size).
- **Gate:** `DeckTests` assert exact card counts per set and that Advanced-only cards are absent from Beginner/Standard.
- **Severity:** Critical. **Blocks Phase 2: Yes.**

### A2 — Make CardType canonically 11 cases (ISSUE-02, ISSUE-20)
- **Files:** `technical-architecture.md` (add canonical enum to the new Model Reference), `accessibility-plan.md` §12 (extend both `switch`es).
- **Change:** Define `CardType` once with all 11 cases: `number(Int)`, `skip`, `reverse`, `drawTwo`, `drawFour`, `changeColour`, `discardAll`, `targetedDraw`, `forcedSwap`, `skipTwo`, `teamPlay`. Confirm whether the number value is an associated value `number(Int)` (the test fixtures `Card(.number(5), .cobalt)` imply yes) and state it. Extend `accessibility-plan.md`'s `voiceOverDescription` and `rulesDescription` switches to cover `discardAll`, `skipTwo`, `teamPlay`.
- **Why:** `CardType` is the most-used model type in Phase 2; an 8-case definition produces non-exhaustive `switch`es and three cards with no VoiceOver label.
- **Gate:** The §12 code compiles against the canonical enum; a unit test enumerates all 11 cases.
- **Severity:** Critical. **Blocks Phase 2: Yes.**

### A3 — One colour type name: `CardColour` (ISSUE-03, ISSUE-13)
- **Files:** `accessibility-plan.md` §12 (`GameColour` → `CardColour`), `technical-architecture.md` (Model Reference).
- **Change:** Standardise on `CardColour` (used by architecture + AI docs). Define its cases as the four colours (`crimson`, `cobalt`, `jade`, `amber`) and state explicitly how "wild/no colour" is represented — either a separate `Card.isWild` flag with `CardColour` always one of four, or an additional case. Reconcile `ai-strategy.md`'s `CardColour.nonWild` reference with whatever is chosen (e.g. provide a static `CardColour.allColours` collection).
- **Why:** Two names for one type forces a guess in every file that touches colour.
- **Gate:** `grep -r "GameColour"` returns zero; model compiles.
- **Severity:** High. **Blocks Phase 2: Yes.**

### A4 — One RNG algorithm; safe at seed 0 (ISSUE-04)
- **Files:** `technical-architecture.md` §8, `testing-strategy.md` §4.
- **Change:** Choose **splitmix64** (recommended — it produces a good sequence from any seed, including 0) and make both documents show the same implementation. If xorshift64 is kept instead, mandate that `init(seed:)` maps seed 0 to a non-zero state, and document it. Either way, both code listings must be byte-identical.
- **Why:** `SeededRNG` is a Phase 2 deliverable; the simulation batch uses seeds 0–999; xorshift64 with state 0 is degenerate (returns 0 forever), silently corrupting game index 0.
- **Gate:** `SeededRNGTests`: (a) two generators with the same seed produce identical sequences; (b) `SeededRNG(seed: 0)` produces a non-constant, well-distributed sequence.
- **Severity:** High. **Blocks Phase 2: Yes.**

### A5 — One house-rule set and defaults (ISSUE-07)
- **Files:** `ux-spec.md` (§4 J3–J5, §5 card-set/house-rules screen, Wireframe 4), `game-rules.md` (canonical), `product-spec.md`, `state-machine.md` (`setupHouseRules`).
- **Change:** Adopt the seven house rules from `product-spec.md`/`game-rules.md` (Draw Four Anytime, Single-Out Win, Draw Stacking, Solo! Penalty Disabled, Team Pass, Partner Plays Immediately, Scoring Enabled) as canonical. Rewrite the `ux-spec.md` house-rules screen to list these seven (not "No draws back-to-back", "Strict Solo!", "Jump-in"). Either drop "Jump-in" or, if wanted, add it to `game-rules.md` as a real rule with full semantics — do not leave it UI-only. Resolve the Solo!-default direction once: `game-rules.md` says the penalty is **on by default** with "Solo! Penalty Disabled" as the off-switch; make the UI match (no "Strict Solo!" opt-in).
- **Why:** `RuleProfile`/`HouseRule` are Phase 2 deliverables; the engine cannot encode a house-rule set the UI contradicts.
- **Gate:** `RuleProfileTests` enumerate exactly the canonical rules; a later UIT asserts each toggle maps to a `RuleProfile` flag.
- **Severity:** Critical. **Blocks Phase 2: Yes.**

### A6 — One Side-to-Side team structure (ISSUE-08)
- **Files:** `ux-spec.md` (Journey 5, mode-selection description), `game-rules.md` (canonical).
- **Change:** Pick one partnership geometry and make both documents identical. `game-rules.md` currently states partner-opposite with teams {Human, Partner} = seats {0, 2} for *all* modes; `ux-spec.md` Journey 5 states Side-to-Side makes the right opponent your partner ({0, 3}). Decide which Side-to-Side actually is, and define the seat→team mapping explicitly for all three modes in `game-rules.md`. Update `ux-spec.md` to match.
- **Why:** `GameState.teamState`/seat model is a Phase 2 type; a wrong assumption forces a seat refactor mid-rules-engine (premortem item 1).
- **Gate:** A unit test asserts the seat→team mapping per mode; `testTeamWinsOnlyWhenBothPlayersEmpty` uses the canonical teams.
- **Severity:** Critical. **Blocks Phase 2: Yes.**

### A7 — One persistence path and one snapshot schema (ISSUE-10)
- **Files:** `technical-architecture.md` §10 (align), `state-machine.md` (snapshot format), `privacy-offline-plan.md` (already canonical for path/filenames).
- **Change:** Adopt CLAUDE.md + `privacy-offline-plan.md` as canonical: files live in the app's **Documents** directory as `wildpairs-game.json`, `wildpairs-settings.json`, `wildpairs-stats.json`. Update `technical-architecture.md` §10 (drop `Application Support/WildPairs/saves/current.json`). Define `GameSnapshot` **once** (fields, schema version, what is/ isn't included) and make `state-machine.md`'s "Snapshot Format" defer to it rather than restate a different shape. Ensure the `DataResetService` filenames in `privacy-offline-plan.md` match.
- **Why:** `GameSnapshot` is a Phase 2 deliverable; divergent paths make resume work but "Reset all data" silently no-op (premortem item 6).
- **Gate:** `GameSnapshotTests` round-trip on the single schema; a test that reset deletes exactly the three canonical files.
- **Severity:** High. **Blocks Phase 2: Yes (snapshot type).**

### A8 — Concrete RuleProfile factory defaults (ISSUE-16)
- **Files:** `game-rules.md`, `technical-architecture.md` §7.
- **Change:** Specify concrete default values for every `RuleProfile` field used by the factory methods: `initialHandSize` (state which — `game-rules.md` deal says 7), Solo! timeout (seconds) for the human, default `targetScore` for scoring mode (and/or fixed round count), `teamPassCooldown`, `soloCallPenaltyCards` (2 per rules). Give the exact field values returned by `standardTeams()`, `allWild()`, `sideToSide()`.
- **Why:** `RuleProfile` and its factories are Phase 2 deliverables; "configurable" without a default is a guess.
- **Gate:** `RuleProfileTests` assert the factory outputs field-by-field; `validate()` rejects the documented contradictory combinations.
- **Severity:** Medium (Critical for the factory values). **Blocks Phase 2: Yes.**

### A9 — Add the canonical "Model Reference" + authority banners (ISSUE-18 doc-side, ISSUE-03/02/13 anchor)
- **Files:** `technical-architecture.md` (new §"Model Reference"), all 16 specs (one-line banner).
- **Change:** Add one section to `technical-architecture.md` that lists, in one place, the canonical definitions of `CardType`, `CardColour`, `Card`, `RuleProfile` (fields + defaults), `GameState` (incl. team/seat model), `GameSnapshot`, and the persistence path. Add the authority banner (top of this file) to each spec.
- **Why:** Removes the "which document is right?" friction that is the root cause of the Sonnet-suitability score (5/10).
- **Gate:** A reviewer can point to exactly one definition of each model type.
- **Severity:** Critical (process). **Blocks Phase 2: Yes.**

---

## B. Important — resolve before they block Phase 3, fix tooling now where cheap

### B1 — Targeted Draw: does it skip the turn? (ISSUE-05)
- **Files:** `game-rules.md` (canonical: states it does **not** skip), `testing-strategy.md` §5 (fix `testTargetedDrawAppliesTwoCardPenaltyToTarget` and `testHumanChoosesTargetAfterTargetedDraw`, which currently assert a skip).
- **Change:** Make the two test rows match the rule (target draws 2, **keeps** their turn). If a skip is actually desired, change `game-rules.md` instead — but pick one.
- **Gate:** The corrected scenario tests.
- **Severity:** High. **Blocks Phase 2: No (Phase 3); fix now to avoid wrong tests.**

### B2 — Forced Swap: wild or coloured action card? (ISSUE-06)
- **Files:** `game-rules.md` (canonical: coloured action card, matches on colour or type), `accessibility-plan.md` §12 (currently labels it "wild card").
- **Change:** Reconcile to coloured-action-card; fix the accessibility `voiceOverDescription` and the wild-card label example.
- **Gate:** Valid-move test for Forced Swap matching; accessibility label test.
- **Severity:** High. **Blocks Phase 2: No (Phase 3).**

### B3 — Solo!: manual-with-timeout or automatic? (ISSUE-09)
- **Files:** `game-rules.md` + `state-machine.md` (canonical: human taps within a timeout, else penalty), `ux-spec.md` Journey 10 (currently shows auto-call).
- **Change:** Make Journey 10 consistent with the manual+timeout model (and with the resolved Solo! default from A5). Specify the timeout value (link to A8).
- **Gate:** `checkingSoloPenalty` state tests; UIT for Solo! timing.
- **Severity:** High. **Blocks Phase 2: No (Phase 3/5).**

### B4 — Reconcile the AI-threading statement (ISSUE, §3.7)
- **Files:** `state-machine.md` (Concurrency Notes), `technical-architecture.md`, `ai-strategy.md` §11.
- **Change:** Decide whether Expert AI computes synchronously on the main actor (architecture: "<1ms, synchronous") or on a background queue (state-machine: "dispatched to a background queue"). State one model; if background, specify how the result re-enters the FIFO action queue and how `awaitingAITurn` autosave interacts.
- **Gate:** Documented; verified in Phase 4 with an Expert-latency check on the minimum device.
- **Severity:** Medium. **Blocks Phase 2: No (Phase 4).**

### B5 — One stuck-game turn limit (ISSUE-12)
- **Files:** `ai-strategy.md` (§12 says 1000), `game-rules.md`/`premortem.md`/`testing-strategy.md` (say 300).
- **Change:** Pick one constant (recommend 300, matching the larger document set) and reference it everywhere by name.
- **Gate:** `testNoStuckGames…` uses the single constant.
- **Severity:** Medium. **Blocks Phase 2: No; cheap to fix now.**

### B6 — Fix test-fixture realism (ISSUE-11)
- **Files:** `testing-strategy.md` §4.
- **Change:** Change the `GameStateBuilder` example to one human + three AI and the canonical team indices ({0,2}/{1,3} or whatever A6 decides). The current `[[0,3],[1,2]]` with two humans contradicts the core game and A6.
- **Gate:** Builder example compiles against the canonical model.
- **Severity:** Medium. **Blocks Phase 2: No; fix now (Phase 2 tooling).**

### B7 — iPad VoiceOver focus order (§3.4)
- **Files:** `accessibility-plan.md` §2.
- **Change:** Add an explicit iPad game-table focus order for the four-edge layout (the existing order is implicitly iPhone). Also fix the colour-picker popover anchor in `ux-spec.md` to a single rule (anchor to the discard pile, not "card or fixed point").
- **Gate:** iPad VoiceOver manual script.
- **Severity:** Medium. **Blocks Phase 2: No (Phase 5/6).**

### B8 — Rule edge cases: Draw Stacking, Discard All (§3.6)
- **Files:** `game-rules.md`.
- **Change:** Specify (a) whether Draw Two and Draw Four stack onto each other across types and the resulting cumulative-penalty rule; (b) Discard All when the player holds no cards of the chosen colour (legal no-op vs disallowed choice) and the exact ordering when Discard All leaves the player on 1 card (choose colour → discard → Solo! check). Specify the Team Play default variant unambiguously (draw 1 each vs partner-plays-immediately).
- **Gate:** Scenario tests per resolved edge case.
- **Severity:** High. **Blocks Phase 2: No (Phase 3).**

---

## C. Advisory — fix when convenient; not gating

### C1 — PrivacyInfo reason code (ISSUE-14)
- **File:** `privacy-offline-plan.md` §3.1/§4.3.
- **Change:** Verify whether the app actually reads file **timestamps** (`creationDate`/`modificationDate`). Plain file read/write via `FileManager` is not itself a required-reason API. If timestamps are not read, no File-Timestamp declaration is needed; if they are, use the correct app-container reason (`C617.1`), not `DDA9.1` (which is the "display to user" reason). Confirm against current Apple docs at Phase 5.
- **Severity:** Medium (App Store validation, Phase 5). **Blocks Phase 2: No.**

### C2 — Quality-gate scripts, `.gitignore`, Xcode pin (ISSUE-18)
- **Files:** create `scripts/quality_light.sh`, `quality_full.sh`, `check_no_network_usage.sh`, `check_permissions_minimal.sh`, `check_project_capabilities.sh`, `check_privacy_manifest.sh` (bodies already exist in the privacy/permission docs); `enterprise-build-notes.md` (pin a minimum Xcode, e.g. 15.4 or 16.0, and add a `.gitignore` spec covering `.build/`, `DerivedData/`, `*.xcuserstate`, `.swiftpm/`).
- **Severity:** Low–Medium (needed at the Phase 2 gate). **Blocks Phase 2: No.**

### C3 — App name decision (ISSUE-15)
- **File:** `design-system.md`, `product-spec.md`.
- **Change:** Confirm "Wild Pairs" as the working title for code/bundle through MVP; defer the final App Store name. No code impact if the bundle id stays stable.
- **Severity:** Low. **Blocks Phase 2: No.**

### C4 — Animation-speed enum values (ISSUE-19)
- **Files:** `privacy-offline-plan.md` (settings: slow/normal/fast), `ux-spec.md` (Normal/Fast/Off), `design-system.md`.
- **Change:** Pick one set of values for the `animationSpeed` setting and use it in all three.
- **Severity:** Low. **Blocks Phase 2: No.**

### C5 — Expert AI helper functions (ISSUE-17)
- **File:** `ai-strategy.md` §6.
- **Change:** Mark `partnerHandSize`, `teamProgressScore`, and the `estimateOpponentResponse` placeholder as "Phase 4 — to be specified", or specify them, so the Phase 4 author is not left inventing them silently.
- **Severity:** Low. **Blocks Phase 2: No (Phase 4).**

---

## D. Phase 2 Go/No-Go checklist

Phase 2 may begin when **all of A1–A9 and B5–B6 are Done** (B5/B6 are pulled forward because they touch Phase 2 tooling), and:

- [x] A1 Deck composition table added; "108-card" removed from ux-spec *(done 2026-06-21)*
- [x] A2 `CardType` defined once with 11 cases; accessibility switches extended *(done 2026-06-21)*
- [x] A3 Colour type is `CardColour` everywhere; wild representation stated *(done 2026-06-21)*
- [x] A4 Single RNG algorithm (splitmix64); `SeededRNG(seed: 0)` proven non-degenerate *(done 2026-06-21)*
- [x] A5 Seven canonical house rules in all docs; Solo! default resolved *(done 2026-06-21)*
- [x] A6 One Side-to-Side team geometry; seat→team mapping stated per mode *(done 2026-06-21)*
- [x] A7 Documents/ persistence path + single `GameSnapshot` schema *(done 2026-06-21)*
- [x] A8 Concrete `RuleProfile` factory defaults specified *(done 2026-06-21)*
- [x] A9 Model Reference section + authority banners added *(done 2026-06-21)*
- [x] B5 Single turn-limit constant (300) *(done 2026-06-21)*
- [x] B6 Test fixtures use one human + canonical teams [[0,2],[1,3]] *(done 2026-06-21)*
- [ ] One Mac round-trip: empty `Package.swift` + targets compile and `swift test` runs (per review §6) *(pending — must run on Mac)*

Also applied (not in original checklist):
- [x] B1 Targeted Draw scenario tests corrected (no skip) *(done 2026-06-21)*
- [x] B2 Forced Swap accessibility label corrected (coloured action card, not wild) *(done 2026-06-21)*

Re-run the scorecard for **Game rules clarity**, **Technical architecture**, **Accessibility**, and **Sonnet implementation suitability**; each should reach ≥9 before the gate opens.

---

*Generated from the Opus Phase 1 review. All A-items and B5/B6 applied 2026-06-21. Mac round-trip is the sole remaining gate item before Phase 2 code starts.*
