# Validation report

## Input audited

```text
Archive: solo-ui-context(1).zip
SHA-256: 1a61aec362234652da0bd1c63acacf2c5e400861220c6bd0a560c4e97500dec7
```

The archive included the relevant SwiftUI views, view model, platform-agnostic view state, models, UI tests, asset-catalog examples, and project design/architecture documents.

## Patch integrity

```text
Patch: patch/solo-table-project-aware-v2.patch
SHA-256: 3796d6338f66dea2c93a020aa0496ad476df999e18a9b60ac8059de4988bcfd9
```

The binary patch was generated from a Git baseline containing the supplied files at the real repository paths. It was then applied to a fresh copy with:

```sh
git apply --check solo-table-project-aware-v2.patch
git apply solo-table-project-aware-v2.patch
```

Every applied file was SHA-256 compared with the expected `repo-overlay`; the result was an exact match.

## Swift syntax parsing

`swiftc -frontend -parse` succeeded for all modified Swift files:

- `WildPairsApp/Theme/TableBackground.swift`
- `WildPairsApp/Theme/Theme.swift`
- `WildPairsApp/ViewModels/GameViewModel.swift`
- `WildPairsApp/Views/CardView.swift`
- `WildPairsApp/Views/GameTableView.swift`
- `WildPairsApp/Views/PlayerZoneView.swift`
- `WildPairsApp/Views/TableCenterView.swift`
- `WildPairsCore/Presentation/GameViewState.swift`
- `WildPairsUITests/WildPairsUITests.swift`

## Asset validation

All six imageset `Contents.json` files parsed as JSON. Every referenced PNG exists and has RGBA alpha:

```text
solo_table_card_back                 1024 x 1434 RGBA
solo_table_direction_ring_clockwise  1024 x 1024 RGBA
solo_table_crest_lava                1024 x 1024 RGBA
solo_table_crest_sky                 1024 x 1024 RGBA
solo_table_crest_grass               1024 x 1024 RGBA
solo_table_crest_sun                 1024 x 1024 RGBA
```

## Static integration checks

Confirmed in the patched source:

- `CardBackView` remains the only shared face-down card renderer.
- `game-draw-card-button` remains attached to the draw `Button`.
- draw and discard anchors remain attached to the visible piles.
- `seat-<position>` identifiers remain in `PlayerZoneView`.
- `game-round-timer` remains present inside the new state rail.
- `game-solo-button` remains on the Solo `Button`.
- the state rail has `game-turn-rail`.
- `pileSpacing` defaults to `Theme.Table.drawDiscardGap` and is clamped to at least 16 points.
- no `GameState` or `GameAction` file is modified.
- no quick-chat UI is added.

## What cannot be validated in this environment

This environment does not contain Apple’s iOS SwiftUI SDK, the real Xcode project file, its complete asset catalog, or the project’s full dependency graph. Therefore the following remain required in the repository:

1. Swift type-check and link in Xcode.
2. Target-membership and asset-resolution verification.
3. Existing unit/UI test execution.
4. Simulator/device layout review.
5. VoiceOver and Accessibility Inspector review.
6. Instruments review for animation and rendering cost.
7. Actual card-flight and draw-flight endpoint review after layout changes.

The package is syntax- and patch-validated, not falsely claimed to be Xcode-runtime validated.
