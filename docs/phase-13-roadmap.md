# Phase 13+ — Roadmap: Improving Wild Pairs as a Whole

Written at the close of the Phase 12b pass (authentic deck + next-gen UX juice). Ordered by
impact-per-effort within each tier. All items respect the offline/enterprise constraints
(no network, no GameKit/StoreKit/analytics, local persistence only).

## Tier 1 — Feel (the remaining gap to "next-generation")

**Status (Phase 16, 2026-07-06): delivered.** 1 Card travel — played cards fly to the pile
(directional removal transition). 2 Sound + haptic — every effect already carries a distinct
signature (GameViewModel.handle). 3 Turn hand-off — strengthened active-seat glow + a per-seat
arrival pop (the cross-table travelling ring remains a future refinement). 4 Discard memory —
the last 3 real discards fan under the top card. 5 Win/loss moments — confetti/trophy/team wash
on a win, quiet loss (RoundEndView). Deck also fully reskinned (Ink & Foil) + Colour Burst card.

1. **Card travel animations.** Played cards should fly from the hand to the discard (and
   drawn cards from the pile to the hand) along `Theme.Motion.playArc`, not appear/disappear
   in place. `GameEffect` already exists in the reducer contract — add a `matchedGeometryEffect`
   namespace across HandView/TableCenterView keyed by card ID.
2. **Sound + haptic pass.** `SoundCoordinator` and `HapticEngine` exist; audit every effect
   (play, draw, skip, reverse, solo, win) for a distinct, quiet signature. Card-flick sound on
   play, soft thud on draw, shimmer on scene re-tint, team-colour celebration on round win.
3. **Turn hand-off choreography.** A brief 250ms spotlight sweep from the finishing seat to
   the next (element-glow ring travelling the table) so turn order is felt, not inferred.
4. **Discard memory.** Show the last 2–3 real discards fanned under the top card (the ghost
   cards are currently blank stock) — `GameViewState` needs a `recentDiscards` slice.
5. **Win/loss moments.** Round end: cards cascade toward the winning team's side; game end:
   full-screen element burst in the team colour. Loss stays quiet (current desaturation is right).

## Tier 2 — Depth (why you come back)

6. **Local milestones.** Offline "achievements" in `wildpairs-stats.json`: first Solo! catch,
   win with 0 draws, beat Master, 10-game streak. Surface on the Statistics screen as an
   engraved card-back gallery (one medallion per milestone).
7. **AI personalities.** The difficulty ladder is a strategy ladder; personalities (aggressive
   stacker, hoarder, colour-controller) chosen per opponent would make tables feel inhabited.
   Pure `WildPairsCore` heuristic weighting — no new UI beyond a name/avatar flavour.
8. **Practice mode with hints.** A toggleable coach that outlines the "best" card (reusing the
   Hard AI's move scorer) and explains why in one sentence. Reuses PromptBanner.
9. **Statistics that tell stories.** Win rate by element, favourite action card, longest game,
   average round length — all derivable from data already recorded.
10. **House-rules screen.** `RuleProfile` already supports bothTeammatesOut, stacking toggles,
    timer lengths; expose a "Table Rules" editor on New Game for the options the engine
    already honours.

## Tier 3 — Reach and robustness

11. **Landscape + Stage Manager.** The portrait lock simplifies layout but iPad landscape is
    the natural card-table aspect. The zone system (partner top / opponents sides / hand
    bottom) maps cleanly to a wide layout.
12. **Design snapshot tests.** The screenshot-capture class now exists; add a golden-image
    diff (simctl + `xcrun simctl io` comparison against `docs/phase-12-redesign/screenshots/`)
    to catch visual regressions in CI-less local runs.
13. **Performance audit at 120Hz.** TimelineView drift + motes + glass blur are all cheap
    individually; profile together on device (Instruments, Core Animation FPS) and add a
    quality tier that auto-drops motes below ProMotion thresholds.
14. **Colour-blind polish.** Pattern fills are now ink-drawn on ivory; validate all four
    patterns at hand sizes with the accessibility-audit skill, and consider pattern-matched
    pips (hatched pip interiors) so patterns survive the authentic-deck look.
15. **App Store readiness.** Icon set in the elemental language, screenshots from the capture
    harness, privacy nutrition label (trivially empty), and the Phase 8 release checklist.

## Explicitly not planned
- Multiplayer (network/MultipeerConnectivity banned by the enterprise constraints).
- Game Center leaderboards (GameKit banned) — local stats only.
- Any telemetry-driven balancing; AI balance stays simulation-driven (`SimulationTests`).
