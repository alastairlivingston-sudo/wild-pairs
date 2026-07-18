# Exact project conflict report

This report is based on the supplied repository copies rather than the earlier generic redesign kit.

## Executive decision

The existing project already has the correct state ownership and most of the required interaction plumbing. The redesign must be applied **inside the current owners**. Installing a parallel set of `DrawStackView`, `OpponentSeatView`, `DirectionRingView`, or table-state models would increase conflict risk and could break timers, AI turns, animation anchors, accessibility, and pending decisions.

## 1. `WildPairsCore/Presentation/GameViewState.swift`

### Current owner

`CardColour.displayName` is the single player-facing and VoiceOver-facing name mapping. Internal cases and Codable values remain `crimson`, `cobalt`, `jade`, and `amber`.

### Redesign action

Only the four returned strings change:

```text
crimson -> Lava
cobalt  -> Sky
jade    -> Grass
amber   -> Sun
```

### Conflict rule

Never rename enum cases, persistence values, rule data, switch cases, or asset IDs that are based on the internal vocabulary. If another branch has already changed `displayName`, retain one implementation and ensure the four outputs match the current product brief.

### Risk if merged incorrectly

Renaming cases can break saves, fixtures, tests, switch exhaustiveness, and encoded game data.

---

## 2. `WildPairsApp/Theme/Theme.swift`

### Current owner

The project already has a comprehensive `Theme` namespace for spacing, card sizes, colour palettes, motion, glass surfaces, and card-colour rendering.

### Redesign action

Adds only `Theme.Table`:

- `drawDiscardGap = 24`
- `directionOrbitOpacity = 0.30`
- `activeSeatBracketWidth = 2`
- `visibleOpponentBacks = 5`

Comments are updated to the new display vocabulary.

### Conflict rule

If `Theme.Table` now exists, merge these constants into it or rename only the colliding constants. Do not introduce a parallel `TableDesignTokens` type. Existing `Theme.Space`, `Theme.Radius`, `Theme.Motion`, and `Theme.CardSize` remain authoritative.

### Risk if merged incorrectly

Two token systems will drift and make responsive behaviour inconsistent.

---

## 3. `WildPairsApp/Theme/TableBackground.swift`

### Current owner

The existing view owns the full-screen table surface and already receives the active `CardColour`.

### Redesign action

Refines its rendering layers:

1. Dark physical base.
2. Broad, low-opacity active-element atmosphere behind the table centre.
3. Accessibility pattern tied to the active element:
   - Lava: diagonal hatch
   - Sky: horizontal lines
   - Grass: vertical lines
   - Sun: dot grid
4. Five sparse edge-biased motes at a capped 12 fps.
5. Protective vignette.
6. Static opaque fallback for Reduced Visual Effects and no mote/drift animation for Reduce Motion.

### Conflict rule

Preserve the existing initializer and call sites. If the current branch has new background state, add it to this owner rather than wrapping it with another full-screen background. There must be exactly one dominant table surface.

### Risk if merged incorrectly

Stacking old and new backgrounds produces muddy colour, extra GPU work, and hierarchy loss.

---

## 4. `WildPairsApp/Views/CardView.swift` — `CardBackView`

### Current owner

`CardBackView` is already the shared renderer used by opponent hands, the draw pile, and draw-flight animations.

### Redesign action

Keeps the existing type and `size` API, but renders `Image("solo_table_card_back")` with a production border and shadow. This removes the `WP` lettering everywhere at once.

### Conflict rule

Do not add a second card-back view. If the current `CardBackView` has gained configuration or effects, preserve those inputs and replace only the inner visual. Any fallback should still use this single shared type.

### Asset dependency

`WildPairsApp/SoloCards.xcassets/solo_table_card_back.imageset`

### Risk if merged incorrectly

Different card backs can appear in the draw deck, opponent fans, and flying draws, which immediately breaks physical credibility.

---

## 5. `WildPairsApp/Views/TableCenterView.swift`

### Current owner

This view already owns:

- draw legality and action forwarding;
- mandatory/optional/forced draw states;
- pending draw-stack badges;
- discard history;
- wild tint resolution;
- reverse feedback;
- draw and discard animation anchors;
- `game-draw-card-button` accessibility identity.

### Redesign action

- Retains the existing inputs and adds one defaulted `pileSpacing` parameter.
- Uses a physical three-layer draw deck.
- Enforces a minimum 16-point and default 24-point draw/discard gap.
- Places the count badge on the outside edge of the draw deck.
- Adds an always-visible, low-opacity direction orbit behind the piles.
- Mirrors the orbit for counter-clockwise play and provides a static Reduced Motion result.
- Keeps a small textual direction readout and one-shot `REVERSED` confirmation.
- Removes duplicate current-colour chrome from the centre because the colour now lives in the single state rail.

### Conflict rule

Never replace this view with a generic draw-stack component. Preserve every new draw state, accessibility label, anchor, and identifier in the current branch. Reapply the spacing/orbit around that logic.

### Layout constraint

At iPhone width, the visible pair width is approximately:

```text
0.85 * discardWidth + 24 + discardWidth
```

`GameTableView` therefore lowers the minimum side column to 72 points so the 96-point focal discard and 24-point gap fit on a 375-point-wide phone.

### Risk if merged incorrectly

Draw taps can become available at illegal times, forced pickup can appear tappable, or flight animations can start/end at stale locations.

---

## 6. `WildPairsApp/Views/PlayerZoneView.swift`

### Current owner

The view already receives `PlayerSeatViewState` and owns partner open-hand rendering, hidden opponent counts, thinking state, cue overlays, catch interaction, and seat accessibility.

### Redesign action

- Opponent: up to five visibly fanned card backs with exact count badge.
- Partner: shallow shelf headed `PARTNER · OPEN HAND`, face-up cards retained.
- Stable abstract crest chosen from the existing absolute `seatPosition`.
- Active turn: white corner brackets, explicit `UP NOW` flag, small arrival pop, and restrained element glow.
- Catch: visible `CATCH +2` affordance while preserving the whole-seat catch action.
- Caught result: native SwiftUI `+N CAUGHT` stamp.
- Adds one defaulted `caughtPenaltyCount` presentation input.
- Keeps `seat-<seatPosition>` identifiers and a single VoiceOver summary.

### Conflict rule

If this view now contains additional badges, gestures, or seat roles, preserve them. Integrate fan/crest/brackets in this view rather than wrapping it in a new seat view. If the crest mapping needs to come from a future player profile, replace the local mapping with that authoritative field; do not maintain two identities.

### Risk if merged incorrectly

Catch taps, partner open information, or pass-and-play seat rotation can be broken.

---

## 7. `WildPairsApp/ViewModels/GameViewModel.swift`

### Current owner

The view model already consumes `GameEffect`, publishes view state, owns timers and AI scheduling, and emits one-shot presentation events for card flight, draw flight, and seat cues.

### Redesign action

Adds a matching one-shot `SoloPenaltyEvent` containing only:

- target seat ID;
- penalty count;
- monotonically increasing token.

The event is emitted when the existing `.soloCallMissed` effect is handled. The actual penalty remains entirely inside the engine.

### Conflict rule

If the current branch already exposes a caught-Solo presentation event, use it and remove this duplicate. Never add penalty cards, change hand counts, or infer catch legality here. If effect payloads now contain a player ID, use that ID and remove the display-name fallback.

### Risk if merged incorrectly

A UI-only animation can accidentally become a second rules path and double-apply penalties.

---

## 8. `WildPairsApp/Views/GameTableView.swift`

### Current owner

The root table already composes all seats, the centre, hand, prompts, decision overlays, timers, pause state, card-flight overlays, draw-flight overlays, handoff spotlights, and table anchors.

### Redesign action

- Adds local transient state for the currently displayed Solo penalty stamp.
- Introduces one private `TableStateRail` combining active element, turn owner, thinking state, and round timer.
- Removes the separate round-timer pill from the vertical stack while keeping `game-round-timer` on the timer inside the rail.
- Passes caught-penalty presentation state into the existing seat views.
- Displays a local caught stamp beside the Solo control if the local player is the target.
- Uses the new 24-point centre gap.
- Replaces the generic bordered Solo button with a native SwiftUI burst control aligned to the trailing thumb zone.
- Preserves all existing overlays, sheets, timers, prompts, anchors, and flight event handling.
- Sets the minimum opponent side column to 72 points to prevent a 375-point-wide phone from clipping the expanded centre pair.

### Conflict rule

This file is the most likely semantic conflict. Do not replace a newer root body wholesale. Merge these intents into the current composition in this order:

1. Keep every current modal, overlay, sheet, and anchor listener.
2. Keep the current device and card-size calculations.
3. Add the state rail near the centre stage.
4. Remove only genuinely duplicated colour/turn/timer pills.
5. Pass the optional penalty count into current seat call sites.
6. Keep the Solo action wired to `vm.callSolo()` and its existing identifier.

### Risk if merged incorrectly

The app can compile while silently losing colour-choice, target, handoff, challenge, round-end, flight, or timer behaviour.

---

## 9. `WildPairsUITests/WildPairsUITests.swift`

### Current owner

The UI test target already protects draw interaction, seats, timers, Dynamic Type, and major gameplay paths.

### Redesign action

Adds one semantic smoke test for:

- `game-turn-rail`;
- `game-draw-card-button` hittability;
- `game-solo-button` stable existence;
- seats 1, 2, and 3;
- a retained screenshot attachment.

### Conflict rule

Place the test anywhere within the existing test class. If helper launch/start APIs change, adapt only those lines. Do not weaken existing tests to make the redesign pass.

---

## 10. Asset catalog

### Added names

```text
solo_table_card_back
solo_table_direction_ring_clockwise
solo_table_crest_lava
solo_table_crest_sky
solo_table_crest_grass
solo_table_crest_sun
```

### Conflict rule

Because they are nested in the existing `SoloCards.xcassets`, Xcode normally requires no project-file change. If any name already exists, compare hashes and visual contract. Keep one authoritative asset and update all references atomically if renamed.

The previous Solo-burst and caught-badge PNGs are intentionally not included. Their wording did not meet the final brief; both controls are rendered natively in SwiftUI so Dynamic Type and accessibility remain correct.
