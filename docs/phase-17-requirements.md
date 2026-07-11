# Phase 17 — Requirements: Playability & UX Pass

Source: user playtest feedback, 2026-07-10. Shaped into requirements below, grouped by
category, with references to the existing canonical docs each item touches. Clarifications
already resolved with the user are noted inline; open questions for the next design pass are
flagged **[NEEDS DESIGN]**.

---

## Delivery status (updated 2026-07-11)

**Shipped & merged to `main`** (each stage verified; see the per-commit notes and
`docs/phase-17-design/stage3-motion/` for captured proof of the play choreography):

- **A1, A2, A3** — draw-stack legality centralised + stack-total display fixed; scoring display/docs corrected.
- **B1** — optional decline-to-stack. **B2** — Draw Four challenge (opt-in, default off). **B3** — Side-to-Side partner-after-human default. **B4a** — Colour Burst → Standard. **B4b** — Draw Eight (Advanced, escalation stacking).
- **C1** swipe-to-play · **C2+** stronger direction chip · **C3** skip/draw seat cues · **C4** opponent card piles · **C5** colour picker off the hand · **C7** persistent Solo! · **C8** hand sort (already present, verified) · **C9** iPad-landscape fit · **C10** 10s/5s move timer.
- **Stage 3 (heavier half)** — **3.1** cross-table played-card travel · **3.3** turn hand-off spotlight · **3.4** "Reversed!" callout · **3.5** count-scaled draw travel.
- **E** — card art replaced outright with the Solo asset pack (image skin + procedural back + Draw Eight stand-in).

**In progress:**

- **D1 partner-view (pass-and-play) table redesign** — design-led; being explored via design-direction-lab (2–3 directions) before building the winner. See §D below. **[NEEDS DESIGN]**

**Accessibility check (Phase 17, verified by inspection):** VoiceOver is **intact** for the new
image skin — `CardView`'s accessibility lives on the skin-independent shell
(`CardView.swift:56–59`), deriving the label from the engine `Card` (colour + type +
`accessibilityDescription` + pattern name), so swapping to `soloArt` cannot lose it. Two residual
notes for a fuller audit pass: (1) the Solo art bakes the colour-blind pattern in **always-on**,
so the `patternFills` setting no longer changes the *visual*, yet the spoken "…pattern" suffix is
still gated on `showPattern` — harmless (VoiceOver users rely on the always-present spoken
colour+type) but worth reconciling; (2) confirm the baked patterns + corner symbols still read at
the smallest two-row hand sizes — recommend a visual QA sweep in colour-blind mode.

---

## A. Correctness bugs (fix engine to match documented rules)

**A1. Stacking total display is inconsistent.**
When a Draw Two/Four penalty stacks, the pending-total indicator must always show the correct
cumulative total (e.g. +2 → +6 when a Draw Four is added), regardless of which card type
started the stack. Confirmed bug: the display currently computes this inconsistently depending
on stack origin. Fix in the view layer reading `RuleProfile`/pending-stack state — the engine's
accumulated total (`game-rules.md` §Draw Stacking) is already the source of truth; audit
wherever the UI independently re-derives or caches the total instead of reading it directly.

**A2. AI stacks an illegal (non-matching) card onto a pending Draw Two/Four.**
User has observed an AI opponent playing a card that does not legally extend the stack (docs:
"A Draw Two may be answered with another Draw Two or a Draw Four... A Draw Four may only be
answered with another Draw Four"). Confirmed as an illegal-move bug, not intended behaviour.
Needs root-cause investigation in the AI move-generation/legality filter — likely the AI's
candidate-move list isn't being filtered against the stricter "pending stack" legality rules
that apply on top of normal colour/number/type matching. Add a regression test asserting the AI
never proposes a non-stacking move while a stack is pending.

**A3. Skip (and likely other non-Draw actions) playable on top of a pending Draw Two.**
Confirmed bug, same root cause family as A2: while a Draw Two/Four stack is pending, the *only*
legal plays are matching Draw Two/Four cards (per stacking rules) until a player draws instead.
Currently other action/number cards are apparently accepted. Fix the shared legal-move
predicate used by both human input validation and AI candidate generation so pending-stack
legality is enforced everywhere, not just in one path — this is very likely the same bug as A2
surfacing on two different move sources.

---

## B. New / changed house rules

**B1. Optional decline-to-stack.**
Even if a player holds a matching Draw Two/Four, they should have the option to decline
stacking and simply draw the pending total instead (today, if you hold a legal stacking card
you're presumably forced to play it, or the choice isn't offered). Add a `PendingDecision` for
"stack or draw" whenever a legal stacking card is available, mirroring the existing
`drawFourChallenge` scaffold pattern (`game-rules.md` §Rule Audit Findings). Applies to the
human player at minimum; AI difficulty heuristics decide whether AI ever declines (Hard/Expert
likely never decline if stacking is favourable — leave as an AI-strategy tuning question for
`ai-gameplay-engineer`).

**B2. Draw Four challenge.**
Implement the challenge flow that is already scaffolded but explicitly out of scope from Phase
11 (`PendingDecision.drawFourChallenge`, `RuleProfile.drawFourChallengeable` —
`game-rules.md` §Rule Audit Findings, §Draw Stacking). Requirement: the *first* time a Draw Four
is played against a player, they get the option to challenge. A challenge checks whether the
player who played the Draw Four had a legal same-colour (or otherwise legally playable) card
available at the time — if they did, the challenge succeeds (the played card is retracted, the
challenged player draws instead, or per standard convention draws a reduced/no penalty) and if
it fails the challenger draws the stack plus a penalty.

**BUILT (Phase 17 B2):** implemented per `docs/game-rules.md` §Draw Four Challenge. A caught
bluffer draws the 4; a wrong challenger draws 4 + 2 = 6; the challenge is offered to the immediate
target after the colour choice, before they stack/absorb. Correctness refinement made during the
build: **only a fresh Draw Four is challengeable** — a Draw Four legally stacked onto a pending
draw isn't, because a same-colour card was never a legal alternative there. Opt-in behind the
Settings toggle "Draw Four challenge" (`drawFourChallengeEnabled` → `RuleProfile.drawFourChallengeable`,
default off). Engine + AI heuristic + human overlay + 7 regression tests; verified on-device via
the `--uitest-drawfour-challenge` demo hook.

**B3. Side-to-Side turn order: partner immediately after human (new default).**
User decision: this becomes the new default order for `sideToSide` mode, replacing today's
alternating-opponent rotation, not an added toggle. Update `docs/game-rules.md` §Side-to-Side
Teams turn-order description and the state-machine's seat rotation logic. Animation work
(turn hand-off choreography, already a Tier-1 roadmap item) needs updating so the sweep follows
the new seat order rather than the old one.

**B4. Card sets: Advanced adds a +8 card; Colour Burst moves from Advanced to Standard.**
- New action card type in the Advanced set only: a "Draw Eight" (working name — confirm final
  in-game name/symbol with the design-system vocabulary before implementation), stacking rules
  extend naturally (Draw Two → Draw Four → Draw Eight, or however the stacking chain is
  specified — needs a game-engine-engineer pass on exact stacking compatibility, e.g. can a
  Draw Two stack onto a pending Draw Eight?).
- `discardColour` ("Colour Burst," per `docs/game-rules.md` — currently Advanced-only, 1 per
  colour) moves into the **Standard** set. Update the Card Sets table (`game-rules.md` §Card
  Sets, currently: Beginner / Standard / Advanced composition tables and the `DeckTests` count
  assertions) and re-verify exact per-set card counts once Draw Eight and the moved Colour Burst
  are both accounted for.

---

## C. New UI / UX features

**C1. Swipe-to-play, in addition to tap.**
Add a swipe gesture (card flicked toward the discard pile) as an alternative input to tapping a
card, reusing the existing play-arc travel animation (Phase 16 Living Table). Tap remains
supported; this is additive, not a replacement.

**C2. Persistent turn-direction indicator.**
Show which way play is currently moving (clockwise/counter-clockwise) at all times, not just
at the moment of a Reverse. Likely a small always-visible arrow/ring element near the table
centre that flips orientation on Reverse and is unaffected by which player currently has the
turn.

**C3. Skip/Reverse should visually call out the affected seat.**
When a Skip or Reverse resolves, show a visible cue at the skipped seat (or the seat whose turn
is reversed away from) — not just advance the turn silently. Ties into the existing Tier-1
roadmap "turn hand-off choreography" item; extend that animation work to cover the skipped-seat
case specifically, since today's choreography only covers normal hand-offs.

**C4. Opponent card piles reflecting hand size.**
Each AI opponent should show a small stacked-card pile whose height/count visually reflects how
many cards they're currently holding (mirrors the player's own hand, but face-down and
compact) — not just a numeric badge.

**C5. Colour-choice popover shouldn't block the hand.**
When choosing a new colour after a Change Colour/Draw Four, the picker must not visually cover
the player's own hand or the visible partner hand. This is already a tracked open item in the
Wild Pairs design-fix initiative — surface it in that initiative's item list rather than
duplicating tracking.

**C6. Draw pickup animation scales with card count.**
Extend the existing card-travel animation (Phase 16) to cover *drawing* — when any player picks
up cards, animate them arriving one after another (or as a scaled sequence) with duration
proportional to how many cards were drawn, so a 6-card stacked-penalty draw reads visibly
differently from a single forced draw.

**C7. Persistent "Solo!" button.**
Add a visible Solo! declaration control available throughout the round (not only contextually
surfaced near one card remaining), so the player can proactively call Solo! at the moment
they're required to (holding two cards, about to play down to one) without hunting for a prompt.

**C8. Hand auto-sort: colour, then ascending rank.**
Newly dealt hands (and hands after any draw) should always be displayed sorted by colour first,
then lowest-to-highest within colour. Confirm sort order for action/wild cards relative to
numbers within a colour group (e.g. does Skip sort before or after numbers of its colour?) —
flag to ux-lead/game-engine-engineer for a precise sort-key spec.

**C9. Smaller iPad landscape requires scrolling.**
On smaller iPad models in landscape, the table currently requires vertical scrolling — it
should fit without scroll. This is the existing Tier-3 roadmap item "Landscape + Stage Manager"
(`docs/phase-13-roadmap.md` #11); treat as a targeted layout-fit bug against smaller iPad
landscape specifically rather than the full landscape redesign, unless the redesign is already
in flight.

**C10. Move timer: 5-second limit in the final minute.**
Round timer stays 3 minutes total; per-move limit is documented as 10 seconds
(`RuleProfile.moveTimeLimitSeconds`) but should drop to 5 seconds once the round enters its
final minute. New requirement — `RuleProfile` needs a second, time-remaining-conditional move
limit; UI countdown must reflect the shortened window once the round timer crosses the
2:00 mark.

---

## D. Full redesign — flagged for a separate design pass

**D1. Partner-view (pass-and-play) table redesign.**
User decision: scope this as a full redesign, not a minimal tweak. Concept: assume the two
teammates are physically holding the device at opposite ends — the partner's cards (today
rendered small/face-down/summarised) should be shown large and upside-down at the "far" end of
the table so the partner can read their own hand right-side-up from their physical position.
Whose turn it is should be conveyed by which end's cards are enlarged/active and other
persistent visual cues (see C2 turn-direction indicator, C3 skip/reverse callouts) — replacing
today's turn-change popup dialog entirely.

This changes core table layout/zone assumptions (`docs/ux-spec.md` table zones, Living Table
work from Phase 16) and interacts with C2/C3/C4 above. **Recommended next step:** run this
through `design-direction-lab` to produce a few concrete visual directions before any
implementation, since it's a structural change to the primary game screen, not an incremental
fix.

---

## E. Card face redesign — "Hyper Sweep V3"

User has supplied a design spec for a new card-face visual direction, saved at
`docs/phase-17-design/hyper-sweep-v3-design.json` (token/catalogue spec) and
`docs/phase-17-design/hyper-sweep-v3-gallery.html` (an HTML gallery viewer for browsing the
set). **No actual card artwork (PNG/SVG) was supplied** — both files reference image paths
(`cards_png/*.png`, `cards_svg/*.svg`) that don't exist anywhere in the repo, so the gallery
currently renders broken images. Treat the JSON as a design-token/content spec to implement
against, not a drop-in asset pack.

**What the spec describes** (superseding the Phase 16 "Ink & Foil" deck skin if adopted):
- Real printed/laminated card production look: warm-white laminated rim with bevel shadow,
  saturated colour field with diagonal "hyper sweep" gradient bands, one gloss sheen pass, and
  the existing colour-blind pattern overlay (diagonal hatching / horizontal lines / vertical
  lines / dot grid for Fire/Rain/Earth/Wind — patterns unchanged from current vocabulary).
- Single large "hero mark": a raised white-to-silver slab shape with a black keyline and a
  dark drop-extrusion offset down-right, plus a soft cast shadow — replaces whatever the
  current dominant face mark is.
- Mirrored miniature corner index (mark + suit symbol) in two opposite corners only — no
  caption text anywhere on the face; numerals and symbolic marks only (consistent with the
  existing "no face captions" convention already in the corrections log).
- Suit symbols per colour unchanged: Fire→Flame, Rain→Wave, Earth→Crystal, Wind→Gust.
- Wild cards: charcoal/black stock, never a single colour, four-chip Fire/Rain/Earth/Wind
  motif.
- Per-action iconography fully specified in the JSON's `actions` block (e.g. Skip = a player
  token inside a no-entry strike ring, Reverse = two chunky arrows chasing in a circle,
  Colour Burst = three same-colour cards swept away by one ejection arrow, etc.) — this is a
  ready-to-use icon brief per card type, useful regardless of whether the rest of the visual
  system is adopted wholesale.
- Card master resolution specified as 900×1350px (2:3 aspect) if regenerated as raster masters.

**Requirement:** evaluate this as a candidate reskin of the existing deck art (same scope class
as Phase 16's Ink & Foil work). Given it's a full visual system change to every card face,
**recommend routing through `design-direction-lab`** alongside D1 (partner-view) rather than
implementing directly from the JSON — that gives a side-by-side comparison against the current
Ink & Foil deck before committing. At minimum, the action-iconography table in the JSON is
useful as a content reference even if the surrounding production-material styling isn't adopted.

**RESOLVED (Phase 17 Stage 5 E):** replace Ink & Foil outright. A full 75-image asset pack was
supplied (`docs/solo_swiftui_asset_pack.zip`) and integrated: downscaled to 500×750 into
`WildPairsApp/SoloCards.xcassets` (`scripts/prepare_solo_card_assets.sh`), rendered by a new
image-based `.soloArt` `CardSkin` (`SoloArtFace`), with procedural stand-ins for the card back
(dark-glass) and Draw Eight (no supplied art). `Theme.activeCardSkin = .soloArt`; `.inkFoil`
kept as rollback. Colour-blind patterns are baked into the art (always on) — run an
accessibility-audit to confirm legibility at small hand sizes.

---

## Suggested sequencing

1. **Bugs first (A1–A3):** these are correctness issues affecting every game today: they should
   land before new rules are added on top of a stacking engine that isn't fully trustworthy.
2. **House rules (B1–B4):** B2 (challenge) and B4 (card sets) need a short engine-spec pass
   (exact numbers/stacking chain) before implementation; B1 and B3 are more mechanical.
3. **UX features (C1–C10):** mostly additive/independent; C6 and C3 should probably land
   together with A1–A3 since they touch the same stacking-animation code paths.
4. **D1 partner-view redesign and E (Hyper Sweep V3 card reskin):** run both through
   design-direction-lab separately; don't block the above on either. These two could reasonably
   be evaluated together since both are visual/design-lab-scoped, but are independent of each
   other in scope.

Each item above should get its own phase-gate-style acceptance criteria once picked up, per the
usual `docs/release-checklist.md` pattern — this document is the requirements shaping, not the
implementation plan.
