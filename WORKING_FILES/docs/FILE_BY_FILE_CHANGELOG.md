# File-by-file changelog

## Added assets

Under `WildPairsApp/SoloCards.xcassets/`:

- `solo_table_card_back.imageset`
- `solo_table_direction_ring_clockwise.imageset`
- `solo_table_crest_lava.imageset`
- `solo_table_crest_sky.imageset`
- `solo_table_crest_grass.imageset`
- `solo_table_crest_sun.imageset`

All PNGs are RGBA. The card back is 1024×1434; all other assets are 1024×1024.

## `WildPairsCore/Presentation/GameViewState.swift`

- Changes only the four display strings to Lava, Sky, Grass, Sun.
- Updates comments to make the persistence boundary explicit.
- No model, initializer, or derivation logic changes.

## `WildPairsApp/Theme/Theme.swift`

- Adds `Theme.Table` constants for centre spacing, orbit opacity, bracket width, and visible fan count.
- Updates elemental comments to the new player-facing vocabulary.
- Leaves all existing palette values, card sizes, motion, glass, and shape APIs intact.

## `WildPairsApp/Theme/TableBackground.swift`

- Replaces the more prominent aurora/weave composition with restrained table-surface layers.
- Adds element-specific accessibility pattern rendering.
- Reduces motes to five and caps animation at 12 fps.
- Adds explicit Reduce Motion and Reduced Visual Effects paths.
- Retains the same `TableBackground(element:)` API.

## `WildPairsApp/Views/CardView.swift`

- Replaces only `CardBackView`'s procedural `WP` drawing.
- Uses `Image("solo_table_card_back")` while retaining `CardBackView(size:)`.
- Adds proportional border and shadow suitable for the existing sizes.
- Updates pattern comments to Lava/Sky/Grass/Sun.

## `WildPairsApp/Views/TableCenterView.swift`

- Keeps existing draw and discard inputs.
- Adds defaulted `pileSpacing`.
- Draw deck becomes a three-layer physical stack.
- Count/penalty badge moves to the outer edge.
- Adds a low-opacity direction ring and mirrored reverse state.
- Adds a textual direction readout and transient `REVERSED` confirmation.
- Preserves recent discards, wild tint, stack pop, draw hints, anchors, and `game-draw-card-button`.

## `WildPairsApp/Views/PlayerZoneView.swift`

- Adds defaulted `caughtPenaltyCount`.
- Opponent stacks become capped physical fans.
- Adds stable abstract crest assets.
- Partner hand receives an explicit shallow open-hand shelf.
- Adds white active-turn brackets and `UP NOW` flag.
- Adds visible `CATCH +2` affordance and native caught stamp.
- Preserves existing catch callback and seat identifier.
- Exposes `CaughtPenaltyStamp` at module scope so `GameTableView` can also show it for a local-player catch.

## `WildPairsApp/ViewModels/GameViewModel.swift`

- Adds `SoloPenaltyEvent` and a published one-shot event property.
- Remembers the exact local call-out target while the synchronous action is processed.
- Emits the presentation event from the existing `.soloCallMissed` effect.
- Uses the player list as a fallback for AI-originated catches that only provide a display name.
- Does not alter any rule or hand state.

## `WildPairsApp/Views/GameTableView.swift`

- Adds transient display state for `SoloPenaltyEvent`.
- Adds computed active-seat labels from existing view state.
- Inserts one unified state rail before the table centre.
- Removes the separate round-timer badge from the vertical stack; timer remains visible in the rail with the same identifier.
- Routes penalty stamps to partner/opponent zones and the local control area.
- Passes the 24-point pile spacing.
- Replaces the generic Solo button with a trailing native burst control.
- Lowers the minimum side column from 80 to 72 points so the expanded centre fits a 375-point-wide iPhone.
- Preserves all overlays, sheets, animations, anchors, and existing action closures.

## `WildPairsUITests/WildPairsUITests.swift`

- Adds `testRedesignedTableChromeIsPresent`.
- It verifies the state rail, draw button, Solo control, three non-local seats, and captures a screenshot.
- No existing test is weakened or removed.
