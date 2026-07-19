# Claude Code integration contract — Solo table redesign v2

Read this file before changing the project.

## Objective

Integrate the supplied table redesign into the existing SwiftUI app while preserving the existing rules engine, presenter, view-model ownership, animation anchors, accessibility identifiers, and tests.

## Source-of-truth order

When documents or code disagree, use this order:

1. The current checked-out game engine and tests.
2. The current checked-out `GameViewModel`, `GameViewState`, and existing view APIs.
3. This integration package and its conflict report.
4. Older product/design prose.

Do not rename the internal `CardColour` enum cases. Only player-facing `displayName` values become Lava, Sky, Grass, and Sun.

## Integration mode

Prefer the binary patch on the matching baseline:

```sh
git apply --check patch/solo-table-project-aware-v2.patch
git apply patch/solo-table-project-aware-v2.patch
```

If the patch conflicts because the repository has advanced, do not overwrite whole files blindly. Use `repo-overlay` as a semantic reference and follow `docs/EXACT_PROJECT_CONFLICT_REPORT.md`.

## Hard ownership boundaries

The following remain authoritative in the existing project:

- `GameState` and the engine: all rules and legal moves.
- `GamePresenter`: intent handling and effects.
- `GameViewModel`: timers, current perspective, AI scheduling, pause/resume, state publication, animation events.
- `GameViewState`: display projection and legal UI flags.
- `TableCenterView`: draw/discard interaction and table anchors.
- `PlayerZoneView`: partner/opponent seat presentation and catch interaction.
- `CardBackView`: the single shared card-back renderer.
- `GameTableView`: composition and overlay ordering.

Never add a parallel timer, active-player property, direction property, pile count, Solo eligibility flag, catch flag, or score model.

## Conflict protocol

For every conflict, write a short report before editing:

```text
Conflict:
Current owner:
Redesign intent:
Why both versions cannot remain unchanged:
Options considered:
Chosen resolution:
Files changed:
Files intentionally preserved:
Regression risk:
Validation:
```

Use these resolution priorities:

1. Preserve engine and view-model semantics.
2. Preserve public/internal APIs used by other files.
3. Preserve accessibility identifiers and table anchors.
4. Reapply the visual intent inside the existing owner.
5. Omit a proposed visual if it would require duplicating state or breaking input flow.

## Specific merge rules

- If `Theme.Table` already exists, merge the constants; do not create another token namespace.
- If `CardBackView` has changed, keep its current API and replace only its visual body with the namespaced asset.
- If `TableCenterView` has new draw states, preserve them and add the 24-point gap/orbit around the current logic.
- If `PlayerZoneView` has new status badges or gestures, preserve them and integrate the fan/crest/brackets inside that view.
- If a transient Solo-penalty event already exists, map the caught badge to it and remove the duplicate event from this patch.
- If an asset with the same name already exists, compare content. Either keep the existing asset if it meets the contract or rename the new asset and update every matching `Image(...)` reference together.
- Keep `game-draw-card-button`, `game-round-timer`, `game-move-timer`, `game-pause-button`, `game-solo-button`, and `seat-<position>` identifiers.
- Keep `.reportTableAnchor(.drawPile...)`, `.reportTableAnchor(.discard...)`, and seat anchors attached to the actual visible objects.

## Quick chat

Do not add decorative quick-chat buttons. No supplied `GameAction`, state, or AI preference contract exists. Implement it only as a separately reviewed engine feature described in `docs/QUICK_CHAT_DECISION.md`.

## Required validation

1. Clean Xcode build for the iOS 17 target.
2. Existing unit tests and `WildPairsUITests` pass.
3. Verify all six imageset names resolve.
4. Run the device/state matrix in `docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md`.
5. Test VoiceOver, Dynamic Type AX3, Reduce Motion, Reduce Transparency/visual effects, and greyscale.
6. Confirm card-play and draw-flight animations still originate and land at the measured anchors.
7. Confirm iPad landscape does not clip the partner hand, state rail, centre, prompt, timers, Solo control, or local hand.

Do not declare the integration complete merely because it compiles. Completion requires the critical gates in the 10/10 rubric.
