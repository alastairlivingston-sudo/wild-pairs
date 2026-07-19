# Claude Code verification matrix

Claude Code must reopen the live repository, semantic-merge when needed, and complete this matrix before committing.

## 1. Repository and integration

1. Read live `CLAUDE.md`, `.claude/ROUTER.md` if present, `docs/design-system.md`, `docs/ux-spec.md`, `docs/accessibility-plan.md`, `docs/game-rules.md`, `docs/ASSET_MANIFEST.md`, and this bundle.
2. Inspect `git status`, current branch, recent commits, and existing partial Phase 19 work. Never reset, discard, or force-overwrite unrelated changes.
3. Do not reset to the patch baseline. The live branch is authoritative.
4. Run `git apply --check` on the one consolidated patch.
5. If it applies cleanly and no equivalent work is already present, apply it. Otherwise reopen every target file and semantic-merge. Do not use `--reject`, force, or both old and new packages.
6. Confirm the new Swift file is part of the app target. Regenerate from `project.yml` only when that is the repository's current workflow.
7. Search for stale duplicate `MoveTimerBar`, `TableStateRail`, direction readout, or duplicate runtime identifiers.

## 2. Build and automated checks

- run the repository's light quality script after edits;
- run `swift test --package-path .`;
- run a clean iOS 17 app build using the live scheme and available simulators;
- run the full Core/unit suite under Xcode where applicable;
- run `WildPairsUITests`;
- run the repository's full quality, no-network, minimal-permissions, capability, and privacy-manifest checks;
- preserve all existing tests; do not weaken assertions to make the change pass;
- verify the new persistence tests and a real pre-change settings JSON;
- verify reset-all returns the background preference to Felt.

## 3. Standard-table visual matrix

Inspect at minimum:

- 375-point and current 390-point iPhone portrait;
- 11-inch and 13-inch iPad landscape, plus an iPad portrait pass;
- local, partner, left, and right active seats;
- clockwise and counter-clockwise;
- Lava, Sky, Grass, and Sun;
- Felt, Aurora, and Contours;
- no move timer, normal move timer, and urgent `<= 3s` timer;
- normal and urgent round timer;
- default type, AX3, and AX5;
- explicit Large Cards off/on below AX3;
- colour-blind mode and pattern fills on/off;
- decisions, pause, card travel, Solo normal/urgent/called/caught, round settlement, and game-over overlays.

Confirm:

- timer appearance never moves the table centre, hand, or pause action;
- the top turn/direction text is small but readable and never the only turn cue;
- the local hand has the same non-colour active bracket language as other seats;
- returning below AX3 restores the explicit preference rather than mutating it;
- the central orbit remains subordinate to cards;
- the compact element chip uses the real display name and symbol;
- the ambient arc moves in the actual direction and flips after Reverse;
- the active element is clearer through tint plus the correct pattern family;
- every background keeps cards, counts, decisions, prompts, and touch targets dominant;
- changing style never moves an anchor or control.

## 4. Face-to-face matrix

Verify on iPhone portrait and iPad landscape:

- top human active, bottom human active, left AI active, and right AI active;
- both visual HUDs are upright for their physical viewer;
- only one semantic turn, round timer, move timer, and pause control exists;
- `YOUR TURN`, `PARTNER`, `LEFT`, and `RIGHT` remain perspective-correct;
- only the acting human gets the visible countdown;
- the one pause action remains reachable and does not overlap an AI seat or catch target;
- `handoff-confirm` remains absent from the two-human no-handoff path;
- the legacy active/collapsed geometry is not accidentally redesigned in this change;
- mid-game iPad rotation preserves anchors, timers, decisions, orientation, and touch mapping;
- background direction does not imply a different physical direction to the top player.

## 5. Accessibility and motion

Verify independently:

- iOS Reduce Motion;
- Solo Reduced visual effects;
- Animation speed Off;
- VoiceOver;
- Increased Contrast;
- Button Shapes;
- grayscale;
- default, AX3, and AX5 Dynamic Type.

Confirm:

- the moving ambient arc becomes a static low-opacity trace under each motion-off path;
- direction remains explicit through text and arrows;
- the background remains accessibility-hidden;
- the mirrored top HUD is accessibility-hidden;
- `game-turn-rail` announces element, owner, and full direction once;
- timer values update without per-tick announcement spam;
- score text is meaningful without coloured dots;
- element communication includes `CardColour.displayName`, symbol, and pattern—not tint alone;
- all existing identifiers keep their meanings:
  - `game-turn-rail`
  - `game-round-timer`
  - `game-move-timer`
  - `game-pause-button`
  - `game-draw-card-button`
  - `game-solo-button`
  - `seat-<seatPosition>`
  - `roundend-next`
- new picker identifier is `settings-table-background-picker`.

## 6. Persistence

- launch with a settings file saved before `tableBackgroundStyle` existed;
- confirm every previous preference survives and style defaults to Felt;
- select Aurora and Contours, terminate, relaunch, and confirm persistence;
- reset all local data and confirm Felt returns;
- confirm game snapshots and game-state schema are unchanged.

## 7. Performance

On at least one iPhone and one iPad simulator/device:

- sustain normal play with the 15 fps ambient `TimelineView` active;
- check card travel, decisions, timer updates, and overlays for hitches;
- inspect energy/heat qualitatively and use existing profiling practices if available;
- if tuning is needed, lower ambience opacity/update rate before altering semantic HUD or static fallbacks.

## 8. Git and report

- keep the work on the current Phase 19 branch, or create `claude/phase-19-wave-a-backgrounds` from the intended base when no Phase 19 branch exists;
- never force-push;
- commit only after the verification above is complete;
- recommended commit message: `feat: add Phase 19 HUD and table backgrounds`;
- push the Phase 19 branch to origin;
- do not open a pull request unless the user explicitly requests one;
- report branch, commit SHA, changed files, exact build/test results, screenshots, VoiceOver/motion observations, persistence result, deviations, and remaining risks.
