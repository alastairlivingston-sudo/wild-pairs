# Paste this entire prompt into Claude Code

You are integrating an approved Solo Phase 19 UX change into the live GitHub repository. Work directly in the current repository, use the live tree as authoritative, build and test on macOS/Xcode, then commit and push the Phase 19 branch. Do not open a pull request unless I explicitly ask for one.

The hand-back bundle should be available at:

```text
WORKING_FILES/phase-19/solo-phase-19-github-integration/
```

If it is mounted elsewhere, locate the directory by `README_FIRST.md` and `PATCH/solo-phase-19-wave-a-backgrounds.patch`. Do not copy product source files out of the bundle manually before you inspect the live repository.

## Mission

Integrate exactly the approved **Phase 19 Wave A plus table-background amendment**:

1. fixed edge HUD with round time, exact scores, smaller top turn/direction information, a reserved move-timer slot, and the existing pause action;
2. move the timer out of hand space so it never shifts the hand or table;
3. equal non-colour active-seat framing for the local and Face-to-face acting human hand;
4. persistent central direction arrows with the text owned by the top HUD;
5. AX3+ automatic large human-hand cards without changing the saved Large Cards preference;
6. subtle background ambience that travels clockwise or counter-clockwise from the existing presenter-owned direction;
7. three built-in offline gameplay backgrounds: Felt, Aurora, and Contours;
8. clearer active Lava/Sky/Grass/Sun table state through the existing element tint plus the correct colour-blind pattern;
9. persisted background selection with backward-compatible `.felt` fallback;
10. the included persistence tests and design/accessibility/UX documentation updates.

This is not authorization to implement later Phase 19 workstreams. Do not add stable open Face-to-face shelves, new card-travel logic, Team Pass privacy changes, settlement/rematch, AI reactions, engine events, or rule changes in this integration.

## Non-negotiable product constraints

Read the live `CLAUDE.md` first and obey it. Also read `.claude/ROUTER.md` if present and the live versions of:

```text
docs/design-system.md
docs/ux-spec.md
docs/accessibility-plan.md
docs/game-rules.md
docs/ASSET_MANIFEST.md
```

Then read every Markdown file in this hand-back bundle, especially `HANDBACK_PROTOCOL.md`, `CHANGELOG.md`, `SOURCE_ANCHORS.md`, `CONSTRAINTS.md`, and `VERIFICATION.md`.

The following boundaries are absolute:

- Keep Solo fully offline and single-device. Add no networking, accounts, stores, currencies, IAP, analytics, GameKit, CloudKit, notifications, remote content, photo-library import, or new permissions.
- Do not change engine rules, turn order, direction ownership, timers, scoring, AI, Solo eligibility/catch/penalty, save-game semantics, or current-player ownership.
- Do not create a second game state, current-player field, timer store, direction store, hand model, table implementation, or presentation contract.
- Keep `GameViewState`, `GamePresenter`, and the engine authoritative.
- Keep internal/persisted colour cases `crimson`, `cobalt`, `jade`, and `amber` unchanged. User-facing names must continue to come from `CardColour.displayName`: Lava, Sky, Grass, Sun.
- Do not redesign cards. Do not change `CardView.swift`, `SoloArtFace.swift`, `CardSkin.swift`, card backs, card faces, corner indices, card layout, or card assets. The HTML/video cards are placeholders and are not an art specification.
- Preserve every existing accessibility identifier and meaning. The only new identifier in this package is `settings-table-background-picker`.
- Preserve iPhone portrait policy and iPad rotation behavior.
- Preserve system Reduce Motion, Solo Reduced visual effects, Dynamic Type, VoiceOver, colour-blind symbols/patterns, and existing no-handoff behavior.
- Do not add external dependencies or copied branding/trade dress.

If a requested visual result appears to require engine semantics or a forbidden capability, stop that part and report the exact blocker rather than silently changing rules.

## Repository safety and branch handling

1. Run `git status --short`, `git branch --show-current`, and inspect recent commits before editing.
2. Do not reset, clean, discard, or overwrite unrelated local work.
3. Use the current Phase 19 branch when one is already in use. Otherwise create:

```text
claude/phase-19-wave-a-backgrounds
```

from the current intended GitHub base.
4. Never force-push.
5. The patch was prepared against snapshot commit:

```text
5e3d18412502bfef5cc6922759e98f55579b407e
```

This is provenance only. Do not reset the live branch to that commit merely to make the patch apply.
6. Earlier Wave A and incremental-background packages are superseded. Use only the consolidated patch in this bundle.

## Inspect before applying

Open the live versions of all target files before changing them:

```text
WildPairsApp/Theme/TableBackground.swift
WildPairsApp/Theme/Theme.swift
WildPairsApp/Views/DecisionViews.swift
WildPairsApp/Views/GameTableView.swift
WildPairsApp/Views/PassAndPlayTableView.swift
WildPairsApp/Views/PlayerZoneView.swift
WildPairsApp/Views/SettingsView.swift
WildPairsApp/Views/TableCenterView.swift
WildPairsCore/Persistence/UserSettings.swift
WildPairsTests/UnitTests/PersistenceTests.swift
docs/accessibility-plan.md
docs/design-system.md
docs/ux-spec.md
```

Also check whether `WildPairsApp/Views/GameEdgeHUD.swift`, `TableBackgroundStyle`, or `settings-table-background-picker` already exists. Existing equivalent work means you must semantic-merge rather than double-apply.

Compare the live files with `SOURCE_ANCHORS.md` and the patch. The live repository wins where newer unrelated work has landed.

## Apply or semantic-merge

First run:

```bash
git apply --check WORKING_FILES/phase-19/solo-phase-19-github-integration/PATCH/solo-phase-19-wave-a-backgrounds.patch
```

When it applies cleanly and the feature is not already partially present, apply it:

```bash
git apply WORKING_FILES/phase-19/solo-phase-19-github-integration/PATCH/solo-phase-19-wave-a-backgrounds.patch
```

When the check fails or files have moved, do not force the patch and do not use `--reject`. Semantic-merge the intent into the live files. Keep views small and idiomatic, retain surrounding code conventions, and report every deviation from the supplied patch.

The consolidated patch should result in these repository paths being changed, including one new file:

```text
WildPairsApp/Theme/TableBackground.swift
WildPairsApp/Theme/Theme.swift
WildPairsApp/Views/DecisionViews.swift
WildPairsApp/Views/GameEdgeHUD.swift
WildPairsApp/Views/GameTableView.swift
WildPairsApp/Views/PassAndPlayTableView.swift
WildPairsApp/Views/PlayerZoneView.swift
WildPairsApp/Views/SettingsView.swift
WildPairsApp/Views/TableCenterView.swift
WildPairsCore/Persistence/UserSettings.swift
WildPairsTests/UnitTests/PersistenceTests.swift
docs/accessibility-plan.md
docs/design-system.md
docs/ux-spec.md
```

Do not change other production files merely for cleanup. Changes outside this list require a concrete live-repo reason and must be disclosed.

## Required implementation behavior

### Fixed HUD

- The standard table has one shallow fixed top HUD.
- It contains round number/time, exact scores, the smaller approved turn plus full `CLOCKWISE`/`COUNTER-CLOCKWISE` treatment, a width-reserved move-timer slot, and the existing pause action.
- When no human move timer is active, the timer slot remains measured but exposes no misleading countdown.
- At three seconds or less, urgency changes inside the same slot; it does not create a modal or move any table geometry.
- `game-turn-rail`, `game-round-timer`, `game-move-timer`, and `game-pause-button` retain their existing meanings.

### Turn and direction

- The physical active seat/hand is the primary turn cue.
- The local hand and acting Face-to-face human use the existing shape-coded active brackets.
- The central direction orbit remains in table coordinates and subordinate to cards.
- Duplicate persistent direction text below the piles is removed; the short `REVERSED` confirmation remains.
- A grayscale still must retain understandable turn ownership and direction through brackets, text, and arrow geometry.

### Face-to-face

- Continue using the existing `PassAndPlayTableView`, engine configuration, and one game state.
- Render orientation-correct top and bottom HUD visuals.
- Expose only one semantic HUD/identifier set to VoiceOver.
- Keep one actual pause control.
- Do not reintroduce a handoff screen.
- Do not redesign the existing active/collapsed hand geometry in this change; that remains later P19-04 work.

### AX3+ cards

- Effective large-card mode is true when the saved setting is true or Dynamic Type is `.accessibility3` or larger.
- Do not write this derived value back into `UserSettings.largeCards`.
- Returning below AX3 must return to the user's explicit saved preference.
- Scale human-readable hand cards only according to the supplied implementation; do not reskin cards.

### Directional background ambience

- Source direction only from the existing `GameViewState.turnDirection`.
- During active play, show a broad low-opacity elliptical trace with a short illuminated arc.
- The arc completes one orbit in approximately 14 seconds and updates at a capped 15 fps.
- Clockwise and counter-clockwise travel must match the HUD and central arrows and flip after Reverse.
- The ambient opacity remains subtle and cannot compete with cards, counts, prompts, timers, or decisions.
- The background is decorative, noninteractive, and accessibility-hidden.
- System Reduce Motion, Solo Reduced visual effects, and Animation speed Off must freeze it into a static low-opacity trace rather than remove direction context.
- Do not show the moving pulse outside the `.playing` phase.

### Background choices and active element

- The built-in styles are exactly Felt, Aurora, and Contours with stable raw values `felt`, `aurora`, `contours`.
- They are offline SwiftUI-rendered surfaces; no photo picker, imported image, downloadable pack, store, or remote content.
- The selected style changes paint only; it must not move table anchors or controls.
- Each surface shares the authoritative active-element field and pattern:
  - Lava: diagonal hatch;
  - Sky: horizontal lines;
  - Grass: vertical lines;
  - Sun: dots.
- Keep `CardColour.displayName` and the existing symbol/element chip as semantic truth. Background colour is supplementary.
- Reduced visual effects may lower intensity and remove motion but must not replace the active element with a neutral table.

### Settings and persistence

- Add an Appearance section with one `Table background` picker.
- Preserve the new identifier `settings-table-background-picker`.
- Persist `TableBackgroundStyle` in `UserSettings`.
- Missing keys from older settings files decode as `.felt` without resetting any other saved preference.
- Reset-all should return the preference to Felt through existing settings reset behavior.

## Target membership and project generation

The baseline `project.yml` includes the `WildPairsApp` source directory, but verify the live project includes the new `GameEdgeHUD.swift` in the application target. Run the repository's normal project-generation step only when required by the live setup. Do not make unrelated project-file churn.

## Build and automated verification

Use the live repository's documented commands and available simulator names. At minimum:

1. run the light quality script after edits if present;
2. run:

```bash
swift test --package-path .
```

3. list schemes/destinations and perform a clean iOS 17 app build;
4. run the complete Core/unit suite under Xcode where applicable;
5. run `WildPairsUITests`;
6. run the full quality and enterprise checks from `CLAUDE.md`, including no-network, minimal-permission, capabilities, and privacy-manifest checks;
7. do not weaken, skip, or rename existing tests to get green results;
8. run the new background-style persistence tests and test a real legacy settings file.

The hand-back environment already passed Swift parsing and all 303 SwiftPM tests, but that is not a substitute for your Xcode/iOS results.

## Visual and accessibility verification

Follow `VERIFICATION.md` completely. Capture evidence for:

- 375-point and current 390-point iPhone portrait;
- 11-inch and 13-inch iPad landscape and an iPad portrait/rotation pass;
- standard and Face-to-face tables;
- local, partner, left, and right active seats;
- top human, bottom human, left AI, and right AI Face-to-face states;
- clockwise and counter-clockwise, including Reverse;
- Lava, Sky, Grass, and Sun;
- Felt, Aurora, and Contours;
- no/normal/urgent move timer and normal/urgent round timer;
- default type, AX3, and AX5;
- Large Cards off/on below AX3 and return below AX3;
- colour-blind mode and pattern fills;
- Solo normal/urgent/called/caught;
- decision, pause, card-travel, round-end, and game-over overlays;
- system Reduce Motion, app Reduced visual effects, Animation speed Off, VoiceOver, Increased Contrast, Button Shapes, and grayscale.

Confirm at runtime that there is exactly one semantic instance of each mirrored Face-to-face HUD identifier. Confirm timer updates do not generate per-tick VoiceOver announcement spam.

Use the included HTML and video only to understand hierarchy and movement. Do not copy their placeholder card artwork.

## Performance

Run sustained gameplay with the 15 fps ambient view on at least one iPhone and one iPad simulator/device. Check for redraw cost, stepping, hitches, heat, and interference with card travel or overlays. If tuning is required, reduce opacity or update rate while preserving the static accessibility fallback and semantic HUD.

## Review before commit

Before committing:

- inspect `git diff --check`;
- inspect the complete diff path list;
- confirm no card, engine, presenter, capability, permission, network, or external-dependency file slipped in;
- search for copied branding and forbidden APIs per `CLAUDE.md`;
- confirm all existing identifiers remain;
- compare screenshots with `PREVIEW/solo-phase-19-state-lab-backgrounds.html` and `PROOF/`;
- document every semantic-merge deviation.

## Commit and push

Once the build, tests, UI tests, accessibility checks, persistence checks, visual matrix, and enterprise checks pass:

1. commit with a clear message, recommended:

```text
feat: add Phase 19 HUD and table backgrounds
```

2. push the current Phase 19 branch to origin with no force;
3. do not open a pull request unless I explicitly ask for one.

## Final response

Use `FINAL_REPORT_TEMPLATE.md`. Report:

- branch and pushed commit SHA;
- file-by-file final changelog;
- whether the patch applied cleanly or was semantic-merged;
- exact build/test/UI-test/quality results;
- simulator/device screenshots and state coverage;
- VoiceOver, Dynamic Type, Reduce Motion, and colour-blind findings;
- persistence migration and reset results;
- ambient animation performance findings;
- deviations and remaining risks;
- explicit confirmation that cards, engine semantics, saved colour cases, identifiers, and forbidden capabilities remain untouched.

Do not claim a pass for any check you did not actually run.
