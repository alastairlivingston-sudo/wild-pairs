# Claude Code task — apply the project-aware Solo table redesign

Work on a clean branch. Read `CLAUDE.md`, then `docs/EXACT_PROJECT_CONFLICT_REPORT.md` and `docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md` before editing.

## Phase 1 — inspect

1. Confirm the repository contains the real paths listed in `repo-overlay`.
2. Run `git status --short` and stop if unrelated changes are present.
3. Compare the current versions of the nine modified Swift files with the overlay.
4. Search for pre-existing symbols/assets that overlap:
   - `Theme.Table`
   - `SoloPenaltyEvent`
   - `game-turn-rail`
   - `solo_table_card_back`
   - `solo_table_direction_ring_clockwise`
   - `solo_table_crest_`
5. Produce a conflict report using the template in `CLAUDE.md`.

## Phase 2 — apply

On the matching baseline:

```sh
git apply --check patch/solo-table-project-aware-v2.patch
git apply patch/solo-table-project-aware-v2.patch
```

If that fails because files have moved forward, semantic-merge the corresponding files from `repo-overlay` using these rules:

- The current engine and view-model state remain authoritative.
- Preserve all existing overlays, pending-decision flows, anchor reporting, accessibility identifiers, and tests.
- Reapply visual intent inside `CardBackView`, `TableCenterView`, `PlayerZoneView`, `TableBackground`, and `GameTableView`; do not install parallel components.
- Keep all new parameters defaulted where the overlay does so.
- Keep internal colour cases and Codable values unchanged.
- Do not add quick-chat UI.

## Phase 3 — build and repair only real conflicts

1. Build the app target for an iOS 17 simulator.
2. Fix type/API conflicts by adapting the patch to current project APIs, not by deleting current behaviours.
3. Run all unit tests.
4. Run `WildPairsUITests`, including `testRedesignedTableChromeIsPresent`.
5. Run `tools/verify_solo_table_integration.sh <repo-path>`.

## Phase 4 — visual and accessibility review

Execute the complete matrix in `docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md`.

At minimum capture screenshots for:

- local, partner, left-opponent, and right-opponent turns;
- clockwise and counter-clockwise;
- each of Lava, Sky, Grass, and Sun;
- Solo disabled and urgent;
- catch available and caught;
- iPhone 375-point width, modern Pro size, and iPad landscape;
- default Dynamic Type and AX3;
- Reduce Motion and Reduced Visual Effects.

## Phase 5 — report

Return:

1. Files changed.
2. Every conflict found and the chosen resolution.
3. Build/test results.
4. Screenshots or paths to them.
5. Completed 100-point rubric.
6. Any unresolved blocker.

Do not claim 10/10 until all critical gates pass and the score is at least 95/100 with no category below 90%.
