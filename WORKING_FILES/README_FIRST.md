# Solo table redesign — project-aware integration v2

This package was built after reading the supplied Swift files, view-state projection, UI tests, design system, technical architecture, and asset-catalog conventions. It is not a second standalone table framework. It changes the existing owners of the relevant UI in place.

## Recommended path

1. Create a clean branch from the revision that produced `solo-ui-context(1).zip`.
2. Read `CLAUDE.md` and `docs/EXACT_PROJECT_CONFLICT_REPORT.md`.
3. Run:

```sh
git apply --check patch/solo-table-project-aware-v2.patch
git apply patch/solo-table-project-aware-v2.patch
```

4. Open the real Xcode project and build the iOS app.
5. Run the existing `WildPairsUITests` target, including the added table-redesign regression.
6. Review the state/device matrix in `docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md`.

The patch includes binary assets, so use `git apply`; do not copy the patch text through a chat window.

## What it changes

- Renames player-facing colour labels to **Lava, Sky, Grass, Sun** while keeping the persisted enum cases `crimson`, `cobalt`, `jade`, and `amber` unchanged.
- Replaces the procedural `WP` card back through the existing `CardBackView` API. Every opponent hand, draw deck, and draw-flight animation therefore stays consistent.
- Separates the draw deck from the played-card pile by **24 points** and moves the count badge to the outside edge of the draw deck.
- Adds a quiet, always-visible direction orbit behind the piles and mirrors it for counter-clockwise play.
- Turns each opponent into a small physical fan of card backs topped by an elemental crest, without replacing `PlayerZoneView` or its existing game-state inputs.
- Makes the partner hand explicitly read as `PARTNER · OPEN HAND` without turning it into a large dashboard panel.
- Adds non-colour active-turn brackets and an `UP NOW` flag.
- Replaces separate colour/turn/round-time pills with one compact state rail.
- Reworks the Solo control as a native SwiftUI thumb-zone call button, with Reduced Motion behaviour.
- Adds a transient `+2 CAUGHT` presentation event derived from existing `GameEffect.soloCallMissed`; no penalty rule is reimplemented.
- Refines the table background into a dark physical surface with restrained active-element atmosphere, low-contrast accessibility patterns, sparse motes, and a vignette.
- Adds six namespaced imagesets to the existing `SoloCards.xcassets` catalog.
- Adds a UI regression test for the state rail, draw deck, seats, and Solo control.

## What it deliberately does not change

- No `GameState`, `GameAction`, `GameEngine`, presenter, AI, scoring, timer, draw, reverse, Solo, catch, or turn rule is replaced.
- No second view model or parallel direction/timer state is introduced.
- No generic `TableRedesignKit.swift` is installed.
- No fake quick-chat buttons are added. The supplied project has no action/state/AI contract for partner instructions; see `docs/QUICK_CHAT_DECISION.md`.
- No Xcode project-file edit is required for the six imagesets because they are added inside the existing asset catalog.

## Interactive end-to-end preview

`solo_project_aware_end_to_end_preview.html` is a self-contained offline prototype aligned to the project-aware integration. It demonstrates iPhone/iPad layout, all four active elements, all four turn owners, clockwise/counter-clockwise play, Solo urgency, catch availability, the caught badge, and Reduced Motion. It is a visual review surface only and does not replace the Swift rules engine.

## Package layout

```text
README_FIRST.md
CLAUDE.md
patch/
  solo-table-project-aware-v2.patch
repo-overlay/
  WildPairsApp/...
  WildPairsCore/...
  WildPairsUITests/...
docs/
  COMPONENT_AND_STATE_CONTRACTS.md
  EXACT_PROJECT_CONFLICT_REPORT.md
  FILE_BY_FILE_CHANGELOG.md
  QUICK_CHAT_DECISION.md
  TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md
  VALIDATION_REPORT.md
tools/
  apply_solo_table_patch.sh
  verify_solo_table_integration.sh
```

The `repo-overlay` folder contains complete replacement copies at their real repository paths. It is the fallback for semantic merging when the current branch has diverged and a clean patch no longer applies.
