# D1 — Active-Half Focus: implementation plan

Chosen direction: **02 · Active-Half Focus** (`02-active-half-focus.html` is the parity reference).
Scope: **pass-and-play only** (two human teammates, `partnerRole == .human`). AI-partner games keep
today's single-perspective `GameTableView` untouched.

## Thesis
The device lies flat between the two teammates: **You** always at the bottom edge, **Partner**
always at the top edge (rotated 180°). Whoever is to act gets the big, lit, interactive half with a
full-size hand; the waiting teammate collapses to a slim rotated strip (name + count + card-backs).
No "pass the device" popup — turn hand-off is the Stage-3 spotlight sweeping between the two ends.

## Key architectural choice
Keep the ViewModel's `displayedHumanID` fixed at the **local/bottom** human (You). The existing
`GameViewState` (derived for You) already exposes everything the dual-ended view needs:
- You's hand = `vs.localHand` (bottom, interactive when You is current).
- Partner's hand = the partner seat's `visiblePartnerHand` (top, rotated, interactive when Partner
  is current) — partner hands are open by design, so this is already present and legal.
So no perspective-flip rework: one screen renders both ends from You's view state.

## Pieces
1. **`GameViewModel`**
   - `isPassAndPlay: Bool` — two `.human` players.
   - Explicit-actor intents: `play(_:as:)`, `drawCard(as:)`, `callSolo(as:)`, `chooseColour(_:as:)`,
     `chooseTarget(_:as:)`, `passTeamCard(_:as:)`, `resolveDrawFourChallenge(_:as:)` (wrap the
     presenter's existing `as playerID:` params).
   - `decisionOwnerID: UUID?` + `currentHumanID: UUID?` so the view routes taps/overlays to the
     right end. Suppress the handoff (`pendingHandoffSeat`) when `isPassAndPlay`.
   - Move timer: apply to whichever **human** is current, not only `displayedHumanID`.
2. **`PassAndPlayTableView`** (new) — used by the app when `vm.isPassAndPlay`. Reuses
   `TableCenterView` (centre), `PlayerZoneView` (the two AI opponents), and the Stage-3 travel
   overlay. Layout: top partner half (rotated 180°), middle opponents + centre, bottom You half.
   Active half expands + lights (reuse the `.wpGlass`/spotlight tokens); inactive half is a
   `collapsedStrip`.
3. **Decision overlays, either end.** A decision owned by the top human renders its existing view
   (`ColourPickerView`, `TargetPickerView`, `TeamPassPickerView`, `DrawFourChallengeView`) **rotated
   180°** and dispatches as that human; owned by You, upright. One wrapper keyed on `decisionOwnerID`.
4. **App routing** — `WildPairsApp` shows `PassAndPlayTableView` when `vm.isPassAndPlay`, else
   `GameTableView`. Two-player launch hook `--uitest-autostart-2p` already exists for verification.

## Adaptation
- iPhone portrait is primary (device flat, players at short ends).
- iPad: same two-ended split; the wider canvas gives each half a larger hand — no landscape-specific
  layout for v1 (portrait-first; landscape falls back to the same split).

## Accessibility / reduced motion
- VoiceOver reads both hands from their existing labels (the partner hand already has a spoken
  summary). Rotation is visual only — it does not change reading order.
- The hand-off sweep is the Stage-3 `TurnSpotlight`, already skipped under Reduced Motion.

## Out of scope (v1)
- No bespoke iPad-landscape two-ended layout (uses the portrait split).
- The single-perspective `GameTableView` and AI-partner games are unchanged.

## v1 status (built — `impl-active-half-beth-turn.png`)
Shipped: `PassAndPlayTableView` (both ends, active half expands + lights, waiting end collapses to
a rotated strip, no handoff); all decision overlays route to the owning end (rotated 180° for the
top human); move timer follows the current human. Verified on iPhone via `--uitest-autostart-2p`.

Deferred (v2, noted, not blocking):
- No visible move-timer / round-timer bar in the dual view (the timer still runs and forces a move).
- The Stage-3 cross-table travel/spotlight overlay is not ported into the dual view — the
  expand/collapse animation carries the hand-off instead.
- Swipe-to-play (C1) works upright (bottom); the rotated top hand is tap-only (gesture translation
  is in screen space).
- Forced-pickup auto-draw fires for the bottom human; the top human taps the draw pile (which is
  enabled for them via the acting-perspective centre).
