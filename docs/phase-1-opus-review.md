# Wild Pairs — Phase 1 Senior Review (Opus)

> Reviewer: Opus, acting as a senior review board (11 roles)
> Date: 2026-06-21
> Inputs: all 16 Phase 1 specs + the Phase 1 review pack + the Opus review brief
> Mandate: Is Phase 1 good enough that Sonnet can implement Phase 2 **without guessing**?
> Verdict: **Not yet — Ready with changes.** Eight cross-document contradictions touch the Phase 2 core model and must be resolved first. None require architectural rework. The privacy, permission, offline, and enterprise documents are release-grade as-is.

---

## 1. Executive Summary

The Phase 1 documentation set is, in isolation, unusually strong. Each document is internally coherent, detailed, and written to a professional standard. The privacy, permission, offline, and enterprise-build documents in particular are essentially release-quality.

The problem is **not depth — it is cross-document consistency.** Several documents independently describe the same concept (card types, colour type name, team structure, house rules, the RNG algorithm, the persistence layout, the Targeted Draw effect) and they **disagree with each other.** A reader of any single document would be satisfied; an engineer implementing from the whole set is forced to choose which document is authoritative — i.e. to guess. That directly fails the stated Phase 1 bar.

The existing [phase-1-review-pack.md](phase-1-review-pack.md) (authored during Phase 1) correctly caught the deck-composition gap and several unresolved questions, but it reviewed each document largely on its own terms and **missed the cross-document contradictions**, which are the most dangerous class of defect for Phase 2.

This review's job is to surface those, score the work, and produce an actionable change list. The companion file is [phase-1-opus-action-list.md](phase-1-opus-action-list.md).

**Counts:** 8 blocking (for Phase 2), 7 important (block Phase 3+), 5 advisory.

---

## 2. The Eight Phase-2 Blockers (read this first)

These all touch types or constants that Phase 2 must create (`CardType`, `CardColour`, `RuleProfile`, `SeededRNG`, `Deck`, `GameState` team model, `GameSnapshot`). Each is a contradiction *between* documents, not a mere omission.

| ID | Contradiction | Doc A says | Doc B says | Phase 2 artefact affected |
|---|---|---|---|---|
| **ISSUE-01** | Deck composition | `game-rules.md` / `product-spec.md`: three card sets (Beginner/Standard/Advanced), counts unspecified | `ux-spec.md`: "Standard **108-card** deck (locked)" | `Deck`, `CardFactory` |
| **ISSUE-02** | `CardType` cases | CLAUDE.md / `game-rules.md`: **11** types | `accessibility-plan.md` §12 code: **8** types (no `discardAll`, `skipTwo`, `teamPlay`) | `CardType` enum |
| **ISSUE-03** | Colour type name | `technical-architecture.md` / `ai-strategy.md`: `CardColour` | `accessibility-plan.md` §12: `GameColour` | `CardColour` enum |
| **ISSUE-04** | RNG algorithm | `technical-architecture.md` §8: **splitmix64** | `testing-strategy.md` §4: **xorshift64** (degenerate at seed 0, which the sim uses) | `SeededRNG` |
| **ISSUE-07** | House-rule set | `product-spec.md` / `game-rules.md`: **7** rules (Draw Four Anytime, Single-Out, Draw Stacking, Solo Penalty Disabled, Team Pass, Partner Plays Immediately, Scoring) | `ux-spec.md`: **3** different rules (No-draws-back-to-back, **Strict Solo!**, **Jump-in**) | `RuleProfile`, `HouseRule` |
| **ISSUE-08** | Side-to-Side teams | `game-rules.md`: partner is opposite; teams {Human,Partner} = {seat 0, seat 2} | `ux-spec.md` J5: partner is the **right opponent**; "side by side" | `GameState.teamState`, seat model |
| **ISSUE-10** | Persistence path + snapshot schema | `technical-architecture.md` §10: `Application Support/WildPairs/saves/current.json`, lean snapshot | CLAUDE.md / `privacy-offline-plan.md` / `permission-audit.md`: `Documents/wildpairs-game.json`, richer schema; `state-machine.md` defines a *third* schema | `GameSnapshot` |
| **ISSUE-16** | `RuleProfile` factory defaults | Several values declared "configurable" | No concrete defaults for Solo! timeout, target score, team-pass cooldown | `RuleProfile.standardTeams()` etc. |

If these eight are resolved, the remaining Phase 2 model work is unambiguous.

---

## 3. Scorecard

Each area scored 0–10 against the bar "Sonnet can implement without guessing." For every score below 10, the issue, why it matters, the file to change, the change, the test/gate, severity, and Phase-2-blocking flag are given. Issue IDs reference §2 above and the action list.

### 3.1 Product clarity — 8/10
- **Issue:** Deck composition undefined; several values ("configurable") have no defaults (ISSUE-01, ISSUE-16). App name undecided (ISSUE-15).
- **Why it matters:** Phase 2 builds `Deck`/`CardFactory` and `RuleProfile` factories; without counts and defaults these are guesses.
- **File:** `product-spec.md`, `game-rules.md`.
- **Change:** Add a canonical deck-composition table per card set; specify Solo! timeout (s), default target score, team-pass cooldown.
- **Gate:** `DeckTests` assert exact counts per set.
- **Severity:** Critical (composition), Medium (defaults). **Blocks Phase 2: yes.**

### 3.2 UX quality — 7/10
- **Issue:** The (high-quality) UX spec contradicts the canonical rules on three points: house rules (ISSUE-07), Side-to-Side teams (ISSUE-08), and Solo! being automatic vs manual (ISSUE-09).
- **Why it matters:** The UX spec is what an engineer reads to build screens; if it disagrees with the rules engine the two layers will diverge.
- **File:** `ux-spec.md` (§4 Journeys 5 & 10, §5 card-set/house-rules screen, Wireframe 4).
- **Change:** Reconcile to the canonical rules (see action list); make the house-rules screen list the seven real rules; make Side-to-Side match the rules' partnership.
- **Gate:** Persona walkthrough re-run after reconciliation; UIT covering house-rule toggles maps to engine flags.
- **Severity:** High. **Blocks Phase 2: partially** (RuleProfile/team model).

### 3.3 iPhone UX — 8/10
- **Issue:** Solo! is a timed, penalty-bearing action but no countdown UI is specified; and J10 shows it auto-firing, so the iPhone interaction model is undefined (ISSUE-09).
- **Why it matters:** This is a real-time control with a penalty; it cannot be built without a defined timeout and affordance.
- **File:** `ux-spec.md` (Game table — human turn), `design-system.md` (add a countdown token if used).
- **Change:** Specify the Solo! timeout value, the countdown affordance, and whether the human taps or it auto-calls.
- **Gate:** Manual test MTS for Solo! timing; UIT-Solo.
- **Severity:** Medium. **Blocks Phase 2: no** (Phase 5).

### 3.4 iPad UX — 7/10
- **Issue:** iPad VoiceOver focus order is not separately specified (the accessibility plan gives one order, implicitly iPhone), and the colour-picker popover anchor is ambiguous ("anchored to the played card … or a fixed anchor").
- **Why it matters:** The four-edge iPad table traverses differently; an unspecified order yields a poor VoiceOver experience and rework.
- **File:** `accessibility-plan.md` §2 (add an iPad focus order), `ux-spec.md` (fix the popover anchor to a single rule).
- **Gate:** iPad VoiceOver manual script.
- **Severity:** Medium. **Blocks Phase 2: no.**

### 3.5 Adaptive layout — 8/10
- **Issue:** `ux-spec.md` Split View says "compact layout mirrors iPhone," while `design-system.md` size-class table maps iPad Split View narrow to a compact fallback — consistent — but no breakpoint is given for when the iPad event side-panel disappears in portrait vs landscape on each iPad class.
- **Why it matters:** Minor ambiguity; could cause layout churn but not incorrect logic.
- **File:** `design-system.md` §15.
- **Change:** State the exact width breakpoint at which the side panel hides.
- **Severity:** Low. **Blocks Phase 2: no.**

### 3.6 Game rules clarity — 5/10  *(lowest substantive area)*
- **Issues:** Targeted Draw skips-turn contradiction (ISSUE-05); Forced Swap classified as wild vs coloured action (ISSUE-06); Draw Stacking cross-type (Draw Two ↔ Draw Four) ambiguous; Discard All edge cases (no cards of chosen colour; 1-card-after-discard ordering) unspecified; Team Play default variant ambiguous; deck composition (ISSUE-01); Side-to-Side teams (ISSUE-08).
- **Why it matters:** The rules document is the engine's specification. Each ambiguity becomes a branch where the implementer guesses, and the test author may guess differently — exactly what happened with Targeted Draw (rules say *no* skip; `testing-strategy.md` asserts a skip).
- **File:** `game-rules.md` (primary), `testing-strategy.md` (fix the two Targeted Draw scenario rows), `accessibility-plan.md` (Forced Swap type).
- **Change:** Make `game-rules.md` authoritative; resolve each ambiguity explicitly; align tests.
- **Gate:** Scenario tests per resolved rule; a "rules authority" note at the top of `game-rules.md`.
- **Severity:** Critical (composition, Targeted Draw), High (others). **Blocks Phase 2: composition yes; rest blocks Phase 3.**

### 3.7 State machine clarity — 8/10
- **Issue:** `state-machine.md` is excellent (per-state tests, persistence points, resume handling). But its snapshot schema is a *third* variant distinct from `technical-architecture.md` and `privacy-offline-plan.md` (ISSUE-10). Also the AI background-compute note ("Expert dispatched to a background queue") contradicts the architecture's "engine fully synchronous, AI <1ms" claim.
- **Why it matters:** Snapshot schema feeds `GameSnapshot` (Phase 2). Background-compute vs synchronous affects concurrency design.
- **File:** `state-machine.md` (align snapshot to canonical), `technical-architecture.md` / `ai-strategy.md` (reconcile the AI threading statement).
- **Gate:** `GameSnapshotTests` round-trip on the single canonical schema.
- **Severity:** High (schema), Low (threading note). **Blocks Phase 2: partially** (snapshot).

### 3.8 Technical architecture — 7/10
- **Issues:** Persistence path/schema contradicts CLAUDE.md and privacy docs (ISSUE-10); RNG algorithm contradicts testing-strategy (ISSUE-04); `CardColour` vs `GameColour` (ISSUE-03); `CardColour` wild/`nonWild` case undefined though `ai-strategy.md` calls `CardColour.nonWild` (ISSUE-13); `GameAction.forceState` is in a `Codable` enum but is "debug only" with no stated exclusion strategy; the RNG fast-forward-by-replay scheme is acknowledged as a Phase-2 simplification with a noted correctness risk.
- **Why it matters:** These are the foundational model types Phase 2 delivers.
- **File:** `technical-architecture.md` (§7, §8, §10), add a single canonical "Model Reference" listing `CardType` (11 cases), `CardColour` (4 colours + how wild is represented), `RuleProfile` fields/defaults, `GameSnapshot` schema, and persistence path.
- **Gate:** Model types compile on Mac; `GameSnapshotTests`; a unit test that `SeededRNG(seed: 0)` produces a non-degenerate sequence.
- **Severity:** High. **Blocks Phase 2: yes.**

### 3.9 AI design and fairness — 8/10
- **Strengths:** The fairness model (`AIObservation`, no opponent-hand access, structural enforcement, the Forced Swap exception) is excellent and unambiguous — a genuine highlight.
- **Issues:** Expert pseudocode references undefined helpers (`partnerHandSize`, `teamProgressScore`) and `estimateOpponentResponse` is a crude `1/(count+1)` placeholder (ISSUE-17); the stuck-game turn limit is **1000** here but **300** in `premortem.md`/`testing-strategy.md`/`game-rules.md` (ISSUE-12); the xorshift/splitmix conflict (ISSUE-04) also lives here via the simulation seeds.
- **Why it matters:** Mostly Phase 4, but the turn-limit constant and RNG choice should be fixed before any simulation code is written.
- **File:** `ai-strategy.md` (§6, §12, §13).
- **Change:** Define one turn-limit constant; mark Expert helper functions as Phase-4 to-be-specified; align RNG.
- **Gate:** `testNoStuckGames…` uses the single agreed limit.
- **Severity:** Medium. **Blocks Phase 2: no** (turn-limit definition is cheap to fix now).

### 3.10 Testability — 7/10
- **Issues:** Scenario descriptions encode a rule that contradicts `game-rules.md` (Targeted Draw skip, ISSUE-05); the `GameStateBuilder` example uses **two human players** and teams `[[0,3],[1,2]]`, contradicting the one-human core and the {0,2}/{1,3} seating (ISSUE-11); xorshift seed-0 degeneracy will silently corrupt the seed-0 simulation game (ISSUE-04); turn-limit 300 vs 1000 (ISSUE-12); coverage targets are stated but the brief's "machine-checkable floor" is only enforceable on Mac (acceptable, but call it out).
- **Why it matters:** Tests are the regression net and the second statement of the rules; if they disagree with `game-rules.md`, the engine has two masters.
- **File:** `testing-strategy.md` (§4 examples, §5 scenario rows).
- **Change:** Fix the two Targeted Draw rows; fix the builder example to one human + canonical teams; align RNG and turn limit.
- **Gate:** These tests are themselves the gate once corrected.
- **Severity:** High. **Blocks Phase 2: no** (Phase 3), but fix the builder/RNG now since both are Phase 2 tooling.

### 3.11 Accessibility — 8/10
- **Strengths:** Among the best documents in the set — exhaustive VoiceOver label patterns, live-region catalogue, per-screen checklist, Reduce Motion table, implementation code.
- **Issues:** The §12 code defines `CardType` with only 8 cases and `GameColour` (ISSUE-02, ISSUE-03); the three advanced cards would hit a non-exhaustive `switch`; iPad focus order not separately specified (§3.4 above).
- **File:** `accessibility-plan.md` §12.
- **Change:** Extend both `switch`es to 11 cases; rename `GameColour` → `CardColour`; add iPad focus order.
- **Gate:** Code sample compiles against the canonical model; VoiceOver manual scripts cover all 11 card types.
- **Severity:** High (enum/name), Medium (iPad order). **Blocks Phase 2: the enum/name fixes, yes** (they define the model used elsewhere).

### 3.12 Offline reliability — 9/10
- **Issue:** Only the persistence path/schema contradiction (ISSUE-10) dings this otherwise excellent area; the offline guarantee, autosave trigger points, corrupted-save recovery, and airplane-mode test are thorough and correct.
- **File:** `technical-architecture.md` (align to the `Documents/` path the privacy and reset-data code already assume).
- **Gate:** `testCorruptedSaveHandledGracefully`; airplane-mode manual script.
- **Severity:** High (path), but isolated. **Blocks Phase 2: partially** (snapshot).

### 3.13 Permission minimisation — 10/10
- No issues. The permission audit is exemplary: all 22 protected resources assessed, Info.plist absent-keys enumerated, entitlements allow-list, capabilities deny-list, background-modes deny-list, and verification scripts. AVFoundation playback (sound) correctly does not require microphone permission and is covered. Nothing to change.

### 3.14 Enterprise build friendliness — 9/10
- **Issue:** Quality-gate scripts are referenced throughout but do not yet exist as committed, executable files; `.gitignore` for Xcode artefacts is unspecified; Xcode version is "15+" but not pinned (SwiftUI behaviour differs between 15.x and 16.x) (ISSUE-18).
- **File:** create `scripts/*.sh` (the privacy/permission docs already contain their bodies); `enterprise-build-notes.md` (pin a minimum Xcode, add a `.gitignore` spec).
- **Gate:** Scripts run on Mac and exit 0 at the Phase 2 gate.
- **Severity:** Low–Medium. **Blocks Phase 2: no** (needed at the gate, not to start).

### 3.15 Legal / brand safety — 7/10
- **Issue:** `ux-spec.md` specifies a "Standard **108-card** deck." 108 is the exact card count of the product this game is explicitly differentiating from; pairing it with "locked" both **contradicts the three-card-set design** (ISSUE-01) and is an avoidable brand-safety smell. The rest of the brand-safety work (original colours, "Solo!" not "UNO!", trademark grep) is strong.
- **File:** `ux-spec.md` (remove the "108-card" phrasing; describe the deck via the canonical card-set composition instead).
- **Gate:** `grep -rEi "108|UNO|Mattel"` review at the Phase 8 gate (extend the existing trademark grep to flag `108`).
- **Severity:** High (it is both a contradiction and a brand smell). **Blocks Phase 2: tied to ISSUE-01, yes.**

### 3.16 Build feasibility on Windows for Phase 2 — 8/10
- **Assessment:** Sound. Phase 2 is a pure Swift Package (`Package.swift` + `WildPairsCore` + tests); **no Xcode project is required for Phase 2**, so everything is editable on Windows and built/tested on Mac. See §6 for the full Windows verdict.
- **Issue:** The only real risk is the edit-on-Windows / compile-on-Mac loop: there is no compiler on Windows, so every type error and the eight contradictions above surface only after OneDrive sync + a Mac build. Precise specs are the mitigation.
- **File:** `enterprise-build-notes.md` (add a "Phase 2 round-trip" note: validate an empty `Package.swift` + targets compile on Mac before writing model code).
- **Severity:** Medium (process). **Blocks Phase 2: no, given the §2 blockers are resolved.**

### 3.17 Build feasibility on macOS/Xcode for later phases — 9/10
- **Issue:** Only the un-pinned Xcode version and not-yet-created scripts (ISSUE-18) hold this back from 10. The 8-step first-time setup, simulator-first strategy, no-account requirement, and friction-point playbook are thorough and correct.
- **Severity:** Low. **Blocks Phase 2: no.**

### 3.18 Sonnet implementation suitability — 5/10  *(the crux)*
- **Issue:** Because the foundational model types are described inconsistently across documents — `CardType` (8 vs 11), colour type name (`CardColour` vs `GameColour`), team seating ({0,2}/{1,3} vs {0,3}/{1,2}), RNG algorithm, house-rule set, persistence schema/path, deck composition — Sonnet **would have to guess** on the very first Phase 2 types. A guess that differs from a later document's assumption produces silent divergence that only surfaces in Phase 3–6.
- **Why it matters:** This is the exact failure mode the Phase 1 bar exists to prevent.
- **File:** Resolve all eight §2 blockers and add a single canonical "Model Reference" section to `technical-architecture.md` that every other document defers to.
- **Change:** One authoritative type catalogue; a one-line "authority" banner in each spec ("For models, `technical-architecture.md` §Model Reference is canonical; for rules, `game-rules.md` is canonical").
- **Gate:** A reviewer can point to exactly one definition of each type. Re-score to ≥9 after reconciliation.
- **Severity:** Critical. **Blocks Phase 2: yes.**

**Aggregate:** strongest cluster — privacy/permission/offline/enterprise (9–10); weakest cluster — rules clarity and Sonnet-suitability (5), dragged down entirely by cross-document contradictions rather than missing content.

---

## 4. Full Issue Register

| ID | Title | Severity | Blocks P2 | Primary file(s) |
|---|---|---|---|---|
| ISSUE-01 | Deck composition undefined; "108-card" in ux-spec | Critical | **Yes** | game-rules.md, ux-spec.md, product-spec.md |
| ISSUE-02 | CardType 8 vs 11 cases | Critical | **Yes** | accessibility-plan.md §12, technical-architecture.md |
| ISSUE-03 | CardColour vs GameColour name | High | **Yes** | accessibility-plan.md §12, technical-architecture.md |
| ISSUE-04 | RNG splitmix64 vs xorshift64 (+ seed-0 degeneracy) | High | **Yes** | technical-architecture.md §8, testing-strategy.md §4 |
| ISSUE-05 | Targeted Draw: skip turn? rules say no, tests say yes | High | No (P3) | game-rules.md, testing-strategy.md §5 |
| ISSUE-06 | Forced Swap: wild vs coloured action card | High | No (P3) | game-rules.md, accessibility-plan.md §12 |
| ISSUE-07 | House-rule set: 7 (rules) vs 3 incl. Jump-in/Strict Solo (ux) | Critical | **Yes** | ux-spec.md, game-rules.md, product-spec.md, state-machine.md |
| ISSUE-08 | Side-to-Side team structure contradiction | Critical | **Yes** | ux-spec.md, game-rules.md |
| ISSUE-09 | Solo!: manual+timeout vs automatic | High | No (P3/5) | ux-spec.md J10, game-rules.md |
| ISSUE-10 | Persistence path + 3 snapshot schemas | High | **Yes** (snapshot) | technical-architecture.md §10, state-machine.md, privacy-offline-plan.md |
| ISSUE-11 | Test fixtures: 2 humans + wrong team indices | Medium | No | testing-strategy.md §4 |
| ISSUE-12 | Turn limit 300 vs 1000 | Medium | No | ai-strategy.md, game-rules.md, testing-strategy.md |
| ISSUE-13 | CardColour wild/nonWild case undefined | Medium | **Yes** (model) | technical-architecture.md |
| ISSUE-14 | PrivacyInfo reason code DDA9.1 likely wrong category | Medium | No (P5) | privacy-offline-plan.md §3.1/§4.3 |
| ISSUE-15 | App name undecided | Low | No | design-system.md, product-spec.md |
| ISSUE-16 | RuleProfile factory defaults unspecified | Medium | **Yes** (factories) | game-rules.md, technical-architecture.md §7 |
| ISSUE-17 | Expert AI pseudocode references undefined helpers | Low | No (P4) | ai-strategy.md §6 |
| ISSUE-18 | Scripts not created; .gitignore + Xcode version unpinned | Low–Med | No | scripts/, enterprise-build-notes.md |
| ISSUE-19 | Animation-speed enum: slow/normal/fast vs normal/fast/off | Low | No | privacy-offline-plan.md, ux-spec.md, design-system.md |
| ISSUE-20 | Number card model (`.number(Int)`?) — fold into ISSUE-02 | Low | **Yes** (model) | technical-architecture.md |

---

## 5. Second Premortem — "Three phases from now, this went wrong because Phase 1 missed something"

Setting: end of Phase 4 (engine + rules + AI done), about to start Phase 5 (UI).

1. **The team model couldn't represent Side-to-Side.** Phase 2 hard-coded teams as {0,2}/{1,3} from `game-rules.md`. In Phase 3 we found `ux-spec.md` describes Side-to-Side as partner-on-the-right ({0,3}/{1,2}). Fixing it meant a `GameState` seat refactor after the rules engine was already built on the old assumption. → *Prevented by ISSUE-08.*
2. **Half our Phase 3 scenario tests baked in the wrong rule.** We wrote tests asserting Targeted Draw skips the target's turn (from `testing-strategy.md`). The rules say it does not. When we noticed, we couldn't tell which was canonical and re-litigated a settled rule mid-phase. → *ISSUE-05.*
3. **The settings screen didn't map to the engine.** `RuleProfile` implemented the seven documented house rules; the UI shipped toggles for "Jump-in" and "Strict Solo!" that had no engine flag. → *ISSUE-07.*
4. **Phase 4 balance numbers were meaningless.** Phase 2 guessed deck counts. We tuned AI weights against that deck. When the real composition was decided in Phase 5, every balance result and weight was invalid. → *ISSUE-01.*
5. **A flaky simulation chased for days.** `SeededRNG` used xorshift64; the simulation batch starts at seed 0; xorshift64 with state 0 returns 0 forever, so game index 0's "shuffle" was a no-op and its result was garbage. → *ISSUE-04.*
6. **Reset-data deleted nothing.** The engine wrote saves to `Application Support/.../current.json` (architecture doc) but `DataResetService` deleted `Documents/wildpairs-game.json` (privacy doc). Resume worked; "Reset all data" silently left the save in place. → *ISSUE-10.*
7. **Three advanced cards shipped with no VoiceOver label.** The accessibility label extension's `switch` had 8 cases; `discardAll`, `skipTwo`, `teamPlay` fell through. The Phase 6 accessibility pass hit a non-exhaustive `switch` and we discovered it late. → *ISSUE-02.*
8. **Phase 5 built on a different Xcode.** Phase 2 author used Xcode 15.x; Phase 5 used 16.x; an unpinned SwiftUI behaviour change cost a day. → *ISSUE-18.*

Every one of these traces to a contradiction or omission catalogued in §4 — i.e. they are all preventable now, on paper, at near-zero cost.

---

## 6. Can Phase 2 safely proceed on Windows?

**Yes — conditionally.** The condition is resolving the eight §2 blockers, not the platform.

**Why the platform is fine for Phase 2:**
- Phase 2's deliverables are `Package.swift`, the `WildPairsCore` model types, the `GameEngine` skeleton, `SeededRNG`, and `Deck`/`CardFactory` with tests. **None require the Xcode project** (`enterprise-build-notes.md` correctly defers project creation to Phase 5). All are plain `.swift` files editable on Windows.
- There are zero remote dependencies, so no package resolution / network is needed.
- The split (write on Windows, build/test on Mac via OneDrive) is documented and workable.

**The real constraint — no compiler on Windows:**
- Sonnet cannot type-check on Windows. Every error — and every one of the eight contradictions if left unresolved — surfaces only after a OneDrive sync and a Mac `swift build`/`swift test`. That makes the feedback loop slow and makes spec precision the primary defence.
- **Mitigation (add to `enterprise-build-notes.md`):** at Phase 2 start, do one Mac round-trip to confirm an empty `Package.swift` + empty `WildPairsCore` target + empty test target compile and `swift test` runs, *before* writing model code. This validates the package skeleton independently of the model work.

**OneDrive hazards to document:** a file edited on Windows while Xcode/Finder holds it open on Mac can produce a conflict copy (`… (conflict).swift`) that silently joins the target. Keep Xcode closed while editing on Windows during Phase 2 (trivial, since Phase 2 doesn't need Xcode).

**Verdict:** Windows is a green light for Phase 2 **once the model-level blockers are resolved and a one-line canonical Model Reference exists.** Until then, proceeding would guarantee guessing.

---

## 7. Second Promoter-Score Review (based on specified UX)

"Would this target user recommend the app / keep playing, based purely on the specified experience?" Scored 0–10. This is a fresh pass; it deliberately weights how the *contradictions* would surface to each user once implemented as written.

| Persona | Score | What delights | What would bite (per this review) |
|---|---|---|---|
| Casual solo player | 9 | Instant start, offline, warm tone, Quick Play | Solo! auto-vs-manual confusion (ISSUE-09) |
| Strategic player | 8 | 4 difficulties, advanced cards, real decisions | Rule inconsistencies (Targeted Draw) feel arbitrary once played (ISSUE-05) |
| First-time player | 8 | Onboarding overlay, polite illegal-move tooltips | House-rule names that don't match Rules screen (ISSUE-07) |
| Older / low-vision | 9 | Large Card mode, Dynamic Type to AX5, high contrast | Card content overflow at AX5 not fully specified |
| Colour-blind | 10 | Symbols always on, patterns, names everywhere | — (genuinely excellent) |
| VoiceOver user | 8 | Superb label/announcement spec, custom actions | 3 advanced cards risk missing labels (ISSUE-02); iPad focus order (ISSUE-04/§3.4) |
| Commuter (short sessions) | 9 | Resume-anywhere, autosave every turn | Persistence path bug could lose a save (ISSUE-10) |
| Power user | 7 | Depth, house rules, modes | Mode/house-rule contradictions frustrate until resolved (ISSUE-07/08) |
| iPad player | 8 | True table layout, popovers, side panel | iPad VoiceOver order, popover anchor ambiguity |
| Enterprise developer (the builder) | 7 | Privacy/permission/build story is a 10 | "Which document is authoritative?" friction (the §2 blockers) |

**Weighted average ≈ 8.3/10** — strong, and below the project's self-reported 9.4 specifically because the contradictions, invisible on paper today, would become real friction the moment they are implemented. Resolving §2 would move this back toward 9.

---

## 8. Recommendation

**Do not start Phase 2 yet.** Apply the action list in [phase-1-opus-action-list.md](phase-1-opus-action-list.md):

1. Resolve the eight blockers (§2) — almost all are "pick the canonical document and make the other match."
2. Add a single **Model Reference** section to `technical-architecture.md` and an authority banner to each spec.
3. Create the six quality-gate scripts and a `.gitignore`; pin a minimum Xcode version.
4. Do the one Mac round-trip to confirm the empty package compiles.

None of this is architectural rework. The architecture (pure reducer, module split, MVVM, seeded RNG, masked AI observation, offline persistence) is sound and should not change. The work is reconciliation and a single source of truth for the model. Estimated effort: small — these are edits to existing documents, not new design.

Re-review the four amended areas (rules clarity, technical architecture, accessibility model, Sonnet suitability) and confirm each definition appears exactly once before opening the Phase 2 gate.

---

*Prepared by Opus as senior review board. No application code was written. Phase 2 remains blocked pending the action list.*
