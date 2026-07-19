# Senior iPhone game-design 10/10 acceptance gates

“10/10” is not a subjective declaration. The integration passes only when every critical gate is satisfied, the weighted score is at least 95/100, and no category scores below 90% of its available points.

## Critical gates — any failure blocks release

- No duplicate game state, timer, direction, pile count, Solo eligibility, catch legality, or scoring owner.
- Clean iOS 17 build with no new warnings attributable to the patch.
- Existing unit and UI tests pass; the new redesign smoke test passes.
- Draw and discard anchors still drive card-flight and draw-flight animations correctly.
- `game-draw-card-button`, `game-round-timer`, `game-move-timer`, `game-pause-button`, `game-solo-button`, and `seat-<position>` remain discoverable.
- All six asset names resolve in the app target.
- The table fits without unintended clipping or horizontal scrolling on a 375-point-wide iPhone.
- The table centre remains usable in iPad landscape compact height.
- Active turn, direction, active element, catch availability, and Solo urgency are understandable in greyscale.
- VoiceOver can identify every seat, current turn, direction, draw state, round time, Solo availability, and caught penalty.
- Reduce Motion and Reduced Visual Effects have deliberate static fallbacks.
- Player-facing colour names are Lava, Sky, Grass, Sun; persisted enum cases are unchanged.
- No fake quick-chat interaction is shipped.

## Weighted review — 100 points

### 1. Visual hierarchy — 15 points

Full score requires:

- Cards are the highest-contrast and most visually substantial objects.
- One state rail communicates element, turn owner, and round time.
- Prompt and move timer are clearly secondary.
- The direction orbit sits behind the piles and never reads as a button.
- Glows are reserved for current/urgent states, not applied to every panel.
- No “panel soup”: partner, opponents, centre, prompt, controls, and hand read as one table composition.

Evidence: screenshots in local, partner, left-opponent, and right-opponent turns at default and AX3 Dynamic Type.

### 2. Game-state clarity — 15 points

Full score requires a first-time player to answer in under two seconds:

- Whose turn is it?
- Which element is active?
- Which way is play moving?
- Can I draw?
- Can I call Solo?
- Can I catch someone?

The answer must not depend on colour alone. Reverse must visibly change the orbit and explicit direction label.

### 3. Physical card-table credibility — 10 points

Full score requires:

- Draw deck reads as multiple face-down cards.
- Played pile reads as a separate stack with recent-discard memory.
- Opponents hold fanned backs, not generic rectangles.
- All face-down cards use the same back artwork.
- Shadows and offsets are consistent with one light source.
- The 24-point draw/discard gap remains visible at phone scale.

### 4. Interaction ergonomics — 10 points

Full score requires:

- All controls have at least a 44×44-point effective hit target.
- Draw and discard are not visually or interactively conflated.
- Solo occupies a stable trailing-thumb location.
- Catch affordance is attached to the correct seat.
- Disabled Solo remains learnable but is not mistaken for active.
- No overlay blocks hand selection, draw, colour choice, target choice, challenge, pause, or round-end actions.

### 5. Accessibility and inclusive design — 15 points

Full score requires:

- Element name + symbol + pattern are available.
- Active turn uses text and white brackets, not glow alone.
- Direction has arrows and a spoken/text label.
- Exact card counts are spoken even though only five backs are drawn.
- Dynamic Type works through AX3 without losing essential controls.
- VoiceOver order follows score/state, partner, opponents/centre, prompt/timer, controls, hand.
- Reduce Motion removes repeated pulses, drifting motes, and animated flips while preserving final state.
- Reduced Visual Effects uses opaque, legible surfaces.
- Contrast is checked with Accessibility Inspector, not assumed.

### 6. Responsive iPhone and iPad layout — 10 points

Test at minimum:

- iPhone SE / 375×667 points.
- iPhone 15 Pro / approximately 393×852 points.
- Pro Max class.
- 11-inch iPad portrait.
- 11-inch iPad landscape.
- iPad split view or the project’s minimum supported regular-width window.

Full score requires the state rail to compact before the cards become unreadably small, no partner-card clipping, and no centre collision with side seats.

### 7. Motion, feedback, and performance — 10 points

Full score requires:

- Turn handoff, card travel, draw travel, Reverse, Solo, and caught feedback have distinct purposes.
- No two large effects compete at once.
- Background animation remains below gameplay salience and is capped.
- No continuous animation runs under Reduce Motion.
- Instruments shows no sustained layout thrash or avoidable offscreen-rendering spike caused by the redesign.
- Scrolling is not required during ordinary play on supported devices.

### 8. Integration safety and maintainability — 15 points

Full score requires:

- Existing owners are evolved rather than duplicated.
- New API parameters are defaulted where possible.
- Assets are namespaced.
- Engine/persistence vocabulary remains stable.
- Presentation-only `SoloPenaltyEvent` never mutates game state.
- Comments explain ownership boundaries rather than narrating obvious syntax.
- Current UI tests remain meaningful and no assertion is weakened.
- Conflict decisions are documented.

## Required state matrix

Capture or inspect each of these:

1. Local turn, clockwise, each of Lava/Sky/Grass/Sun.
2. Partner turn.
3. Left opponent turn.
4. Right opponent turn.
5. Counter-clockwise after Reverse.
6. Draw legal, draw illegal, forced pickup, pending stack.
7. Solo disabled, Solo urgent, Solo called.
8. Catch available, catch resolved, local player caught.
9. Colour choice, target choice, team pass, Draw Four challenge.
10. Round end, game end, pause, handoff.
11. Default text size and AX3.
12. Reduce Motion on/off and Reduced Visual Effects on/off.
13. Colour-blind mode/pattern fills on/off.

## Scoring sheet

```text
Visual hierarchy:                    /15
Game-state clarity:                  /15
Physical card-table credibility:     /10
Interaction ergonomics:              /10
Accessibility/inclusive design:      /15
Responsive layout:                   /10
Motion/feedback/performance:          /10
Integration safety/maintainability:   /15
Total:                               /100
Critical gates passed: yes/no
Lowest category percentage:
Unresolved blockers:
Evidence links/screenshots:
```

A compile-only result cannot exceed 70/100. A simulator-only result without VoiceOver, Dynamic Type, Reduced Motion, and iPad review cannot exceed 85/100.
