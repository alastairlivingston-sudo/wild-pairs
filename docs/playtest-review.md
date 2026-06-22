# Wild Pairs — End-to-End Playtest Review

> Reviewer: engine + rules walkthrough as an experienced player, before Phase 5 (UI) work on Mac.
> Date: 2026-06-22
> Scope: `WildPairsCore` engine, rules, AI, persistence (Phases 2–4). No UI exists yet, so "playing" is simulated by tracing the reducer against `docs/game-rules.md` (canonical).
> Status: Bugs B1–B5 fixed in this pass. Gaps G1–G5 and UX/fun items documented for Phase 5+.

---

## How this review was done

There is no playable build on Windows (Xcode is Mac-only), so I "played" the game by tracing `GameEngine.reduce` through every card effect, the draw/turn loop, and win detection, checking each against the canonical rules in `docs/game-rules.md`. Where the engine and the rules disagreed, the rules win. I also re-ran the logic of the scenario tests by hand to find ones that would fail on Mac.

---

## Severity legend

| Tag | Meaning |
|---|---|
| **Bug** | Engine produces behaviour that contradicts the canonical rules. Fixed in this pass. |
| **Gap** | A documented feature is not implemented yet. Documented; deferred with a spec. |
| **UX** | Behaviour is rule-correct but confusing or unsatisfying for a player. |
| **Fun** | An opportunity to make the game more engaging/addictive (Phase 5+). |

---

## Bugs found and fixed

### B1 — You cannot play a card you just drew (core mechanic broken)

**What a player sees:** You have no legal card, so you draw. The drawn card *does* match — but your turn ends anyway and the next player goes. You never got to play it. This is maddening and wrong.

**Root cause:** `handleDrawCard` advanced the turn unconditionally at the end of the function (the final `currentPlayerIndex` assignment overwrote the conditional logic above it, which was dead code). The `mustPlayAfterDraw` rule (`true` in every factory profile, per `game-rules.md` §Draw Procedure and the RuleProfile defaults table) was never honoured.

**Fix:** After drawing, the engine checks whether the drawn card is playable (including the Draw-Four restriction). If it is, the turn **stays** with the player so they can play it; if not, the turn advances. Dead code removed.

**Files:** `WildPairsCore/Engine/GameEngine.swift` (`handleDrawCard`).

---

### B2 — A card silently leaks out of the deck on every deal

**What a player sees:** Nothing obvious — but the deck is one card short after every new round, card-counting AI sees a deck that doesn't add up, and reproducibility from a seed drifts.

**Root cause:** `handleNewGame` and `handleBeginNewRound` flipped the starting discard card with two competing pieces of logic: a `repeat` loop that drew until it found a non-wild (removing it from the deck) **and then** a second block that drew *another* card from the draw pile. The card found by the loop was removed from the deck but never placed anywhere — it vanished from the game.

**Fix:** Single, clear start-card routine: draw until a non-wild is found, set aside any wild cards drawn, return those wilds to the bottom of the draw pile (matching the rules' "shuffle it back and flip again"), and discard exactly the one start card. No card leaves the game.

**Files:** `WildPairsCore/Engine/GameEngine.swift` (`handleNewGame`, `handleBeginNewRound`).

---

### B3 — Draw Four is illegal in All-Wild mode (mode-breaking)

**What a player sees:** In All-Wild Teams — where *every* card is supposed to be playable on every turn — the engine refuses to let you play a Draw Four whenever you also hold a colour-matching card (which is almost always).

**Root cause:** `GameRules.drawFourIsLegal` enforced the standard "only when you have no other matching card" restriction without checking the game mode. `GameRules.isLegal` short-circuits to `true` in All-Wild, but `GameEngine.legalPlays` and `isLegalMove` route Draw Four through `drawFourIsLegal`, which ignored the mode. This also means the existing scenario test `testAllWildModeEveryCardPlayable` would have **failed** on Mac.

**Fix:** `drawFourIsLegal` returns `true` immediately in All-Wild mode.

**Files:** `WildPairsCore/Engine/GameRules.swift` (`drawFourIsLegal`).

---

### B4 — The Solo! penalty mechanic was unenforceable (missing core feature)

**What a player sees:** The headline tension mechanic — "call Solo! when you drop to one card or get caught and draw 2" — did nothing. `callSolo` set a flag; there was no way for anyone to catch a player who forgot.

**Root cause:** There was no `GameAction` to call out a player who failed to declare Solo!, and no handler to apply the penalty. The flag, the penalty count (`soloCallPenaltyCards`), and the timeout (`soloCallTimeoutSeconds`) all existed in the model but were never used together.

**Fix:** Added `GameAction.callOutSolo(targetPlayerID:callerID:)` and `handleCallOutSolo`. When called on a player who holds exactly one card and has not declared Solo! (and the rule is enabled), that player draws `soloCallPenaltyCards` cards and the engine emits `.soloCallMissed` + a VoiceOver announcement. The 5-second timing window itself remains a ViewModel concern (it is time-based), but the engine now owns the rule.

**Files:** `WildPairsCore/Models/GameAction.swift` (new case), `WildPairsCore/Engine/GameEngine.swift` (dispatch + `handleCallOutSolo`).

---

### B5 — AI players never called Solo! (and were permanently catchable)

**What a player sees:** Once the catch mechanic exists (B4), the AI would be exploitable forever — it never declares Solo! — which both contradicts the rules ("the AI automatically calls Solo! with a short simulated delay") and would feel cheap.

**Root cause:** AI `chooseMove` never returns `.callSolo`, and `handlePlayCard` reset `hasCalledSolo` to `false` for *every* player on reaching one card.

**Fix:** When a player drops to exactly one card, the engine now auto-satisfies the Solo! requirement for **AI-role** players (sets `hasCalledSolo = true` and emits `.announceSolo`) while leaving **human** players needing to tap (flag stays `false`). This matches `game-rules.md` §Solo! Engine Handling exactly: AI auto-calls, the human must call manually. The same role-aware logic is applied on the Discard All and Forced Swap paths that can also drop a hand to one card.

**Files:** `WildPairsCore/Engine/GameEngine.swift` (`handlePlayCard`, `handleSelectColour`, `handleSelectTarget`).

---

## Gaps (documented, deferred to Phase 5+)

### G1 — Side-to-Side Team Pass is not implemented
`handleTeamPass` is a no-op, and `GameAction.teamPass(playerID:)` carries no card to pass. Implementing the round-start card exchange (`game-rules.md` §Side-to-Side) requires a model change (the action must carry the chosen card, and the engine needs a pre-round "team pass" phase that pairs both teammates' selections). **Until this lands, Side-to-Side Teams is mechanically identical to Standard Teams.** Deferred — needs a small model change best done alongside the Phase 5 UI that drives it.

**Proposed model:** `case teamPass(card: Card, playerID: UUID)`; a `GamePhase.teamPass` entered after dealing when `teamPassEnabled`; collect one card per player, then swap within each team simultaneously, then transition to `.playing`.

### G2 — Draw Four challenge not implemented
`challengeDrawFour` returns the state unchanged. Not an MVP-facing feature; the "Draw Four Anytime" house rule (`drawFourChallengeable`) covers the relevant config. Low priority.

### G3 — Draw stacking not implemented
`stackDrawCards` is `false` in all profiles, so Draw Two / Draw Four always resolve immediately. The house rule is off by default; deferred.

### G4 — `maxTurnsPerRound` is not enforced by the engine
Only `GameSimulator` caps turns at 300. The pure engine cannot loop on its own (each action makes progress), and the cap is a runtime safety net, so this is acceptable — but the ViewModel should also enforce it as a defensive measure (`game-rules.md` §Error Handling).

### G5 — Unused rule flags
`changeColourRequiresPlay` and `drawUntilPlayable` are modelled but not read by the engine. They are off by default; wire them up if/when the corresponding house rules ship.

---

## UX observations (rule-correct but worth attention)

### U1 — A "game" is one round with nothing to chase (default)
`scoringEnabled = false` and `targetScore = 0` mean a session is a single round that ends at `.roundEnded` with no score, no streak, no "next round." For a card game meant to be picked up repeatedly, this is the single biggest engagement risk. The data model already supports it (`GameStats`, `teamScores`, `DifficultyStats`, win streaks) — it just isn't the default experience.

**Recommendation (Phase 5):** Default the New Game flow to a multi-round session (best-of-3, or first team to 300 points), and always show running stats on the home screen. See Fun items below.

### U2 — Team Play feels like a trap
The default Team Play effect makes **both** you and your partner draw a card — it grows your team's hands, which is the opposite of the goal. A player will quickly learn to never want this card and will resent being forced to play it as their only colour match. It is double-edged *by design* (`game-rules.md` §Team Play), but the design intent is subtle.

**Recommendation:** Surface a clear tooltip ("You and your partner each draw 1"), and seriously consider shipping with the `partnerPlaysImmediately` variant on by default for a more satisfying, pro-active feel.

### U3 — Skip Two skips your own partner
A Skip Two played by the human in clockwise order skips the Left Opponent **and** the Partner, landing on the Right Opponent. This is correct and documented, but it is a foot-gun. The UI should preview who will be skipped before the card is committed.

---

## Fun / addictiveness recommendations (Phase 5+ — design, not bugs)

1. **Multi-round arc by default.** Best-of-3 or race-to-300 turns a 3-minute round into a 10-minute "just one more round" session. Engine already supports `targetScore` + cumulative `teamScores`.
2. **Always-visible progression.** Win streak, total wins, and per-difficulty win rate on the home screen (data already in `GameStats`). Streaks are the cheapest, strongest retention hook.
3. **Solo! as a moment.** Now that B4 makes the catch real: a tap-to-call button with a shrinking timer ring, a satisfying haptic + sound on a successful call, and a small "Caught!" celebration when an opponent forgets. This is the most distinctive mechanic — lean into it.
4. **Clutch-moment feedback.** Extra celebration when you win on a Draw Four, empty your hand to clinch a round for the team, or catch a missed Solo!. Proportionate delight (`ux-spec.md` principle 9).
5. **Daily / shared seed challenge.** Deterministic seeding already exists (`SeededRNG`, `GameConfig.seed`). A "daily deal" everyone could replay is a zero-network, fully-offline retention feature that fits the enterprise constraints perfectly.
6. **Rival framing.** Name the AI opponents and track a head-to-head record per opponent to create a light "nemesis" narrative across sessions.

---

## Test impact

- `ScenarioTests.testAllWildModeEveryCardPlayable` would have failed before B3; it now passes.
- `ScenarioTests.testHumanDrawsPlayableCard` previously worked around B1 by manually re-seating the player; the draw-and-play fix makes the natural flow correct. (Test left as-is; still valid.)
- New tests added in `SoloMechanicTests.swift` cover B4/B5: catching a human who forgot, no penalty when Solo! was called, AI auto-call, penalty disabled by house rule.
- New assertions in `CardEffectTests` / `ScenarioTests` cover the draw-and-play behaviour and the start-card conservation invariant.

---

## Summary

| ID | Title | Type | Status |
|---|---|---|---|
| B1 | Can't play a drawn card | Bug | Fixed |
| B2 | Start-card deck leak | Bug | Fixed |
| B3 | Draw Four blocked in All-Wild | Bug | Fixed |
| B4 | Solo! penalty unenforceable | Bug | Fixed |
| B5 | AI never calls Solo! | Bug | Fixed |
| G1 | Side-to-Side Team Pass | Gap | Deferred (needs model change) |
| G2 | Draw Four challenge | Gap | Deferred |
| G3 | Draw stacking | Gap | Deferred |
| G4 | `maxTurnsPerRound` engine enforcement | Gap | Documented |
| G5 | Unused rule flags | Gap | Documented |
| U1 | Single-round default | UX | Recommendation |
| U2 | Team Play feels like a trap | UX | Recommendation |
| U3 | Skip Two hits your partner | UX | Recommendation |
