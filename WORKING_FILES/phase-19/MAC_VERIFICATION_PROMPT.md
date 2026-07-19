# Phase 19 — Mac verification prompt

Paste the block below into a fresh Claude Code session on macOS (with Xcode) to finish
the Phase 19 Wave A + backgrounds verification. The integration is already committed and
pushed on branch `claude/phase-19-wave-a-backgrounds-nn0c5q`; the remaining work is the
Xcode/simulator/accessibility/performance gates that a Linux session could not run.

```text
You are finishing the verification and sign-off of an already-integrated Phase 19
UX change for the Solo (internal "Wild Pairs") offline iOS card game. The code is
already committed and pushed — your job is to VERIFY it on macOS/Xcode, fix only
what verification reveals, and report. Do not re-integrate or re-design anything.

## Context (already done, in a remote Linux session that had no Xcode)
- Branch: claude/phase-19-wave-a-backgrounds-nn0c5q  (check it out; do NOT create a new branch)
- Product commit: 6c1e607 "feat: add Phase 19 HUD and table backgrounds"
- Provenance commit: 9ec0631 (adds WORKING_FILES/phase-19/ hand-back bundle)
- The approved consolidated patch was applied cleanly (14 paths: 13 modified + 1 new
  WildPairsApp/Views/GameEdgeHUD.swift). No semantic-merge deviations.
- Static checks that already passed: git apply --check, git diff --check, brace/paren
  balance, symbol-resolution audit, dangling-ref scan, forbidden-API scan, identifier
  preservation, colour-case integrity. The hand-back reports 303 SwiftPM tests passing
  on Linux — but NO Xcode build, iOS SDK type-check, simulator, UI test, VoiceOver,
  motion, or performance check was ever run. That is your task.

## First, read and obey (source-of-truth order: live code > this bundle > older prose)
- CLAUDE.md and .claude/ROUTER.md
- docs/design-system.md, docs/ux-spec.md, docs/accessibility-plan.md, docs/game-rules.md
- WORKING_FILES/phase-19/solo-phase-19-github-integration/: VERIFICATION.md (the matrix
  you must complete), CONSTRAINTS.md, CHANGELOG.md, SOURCE_ANCHORS.md, FINAL_REPORT_TEMPLATE.md
- Review references only (do NOT copy their placeholder card art): PREVIEW/
  solo-phase-19-state-lab-backgrounds.html, the concept video, and PROOF/*.png

## Hard boundaries (do not cross — stop and report if a fix would require it)
- No engine/rules/presenter/GameViewState changes. Keep GameViewState, GamePresenter,
  and the engine authoritative. No second game state, timer store, direction store, or
  current-player field.
- Do NOT touch cards: CardView.swift, SoloArtFace.swift, CardSkin.swift, card faces/
  backs/assets/corner indices.
- Keep persisted colour cases crimson/cobalt/jade/amber; user-facing names come from
  CardColour.displayName (Lava/Sky/Grass/Sun).
- Preserve every existing accessibility identifier. Only new one: settings-table-background-picker.
- Offline/single-device only: no networking/accounts/IAP/analytics/GameKit/CloudKit/
  notifications/photo-library/new permissions/external dependencies.
- Scope is Wave A + backgrounds ONLY (P19-01, P19-02, P19-05, backgrounds). Do NOT add
  stable Face-to-face shelves, card-travel parity, Team Pass privacy, settlement/rematch,
  or AI reactions.

## Run the gates (use live scheme + available simulator names; list them first)
1. If the project uses xcodegen, regenerate from project.yml so GameEdgeHUD.swift is in
   the WildPairsApp target; confirm target membership. Avoid unrelated project churn.
2. ./scripts/quality_light.sh
3. swift test --package-path .
4. Clean iOS 17 build of the app (iPhone + iPad destinations).
5. Full Core/unit suite under Xcode; then WildPairsUITests.
6. ./scripts/quality_full.sh, check_no_network_usage.sh, check_permissions_minimal.sh,
   check_project_capabilities.sh, check_privacy_manifest.sh
7. Do NOT weaken, skip, or rename any existing test to get green.
8. Persistence: run the new TableBackgroundStyle tests AND launch with a REAL legacy
   settings JSON saved before tableBackgroundStyle existed — confirm every prior
   preference survives and style defaults to .felt; select Aurora/Contours, relaunch,
   confirm persistence; reset-all returns to Felt.

## Visual / accessibility / performance matrix (VERIFICATION.md §3–§7)
Capture screenshots for: 375pt + 390pt iPhone portrait; 11" + 13" iPad landscape + an
iPad portrait/rotation pass; standard + Face-to-face tables; local/partner/left/right
active seats; Face-to-face top-human/bottom-human/left-AI/right-AI; clockwise +
counter-clockwise incl. Reverse; Lava/Sky/Grass/Sun; Felt/Aurora/Contours; no/normal/
urgent(<=3s) move timer; normal/urgent round timer; default/AX3/AX5 type; Large Cards
off/on below AX3 and confirm returning below AX3 restores the saved preference (never
mutates UserSettings.largeCards); colour-blind mode + pattern fills; Solo normal/urgent/
called/caught; decision/pause/card-travel/round-end/game-over overlays; system Reduce
Motion, app Reduced visual effects, Animation speed Off, VoiceOver, Increased Contrast,
Button Shapes, grayscale.

Confirm specifically:
- The move-timer slot is width-reserved and its appearance NEVER shifts the table centre,
  hand, or pause; urgency changes inside the same slot (no modal, no geometry move).
- Exactly ONE semantic instance of each mirrored Face-to-face HUD identifier
  (game-turn-rail, game-round-timer, game-move-timer, game-pause-button) reaches VoiceOver;
  the rotated top HUD is accessibility-hidden. handoff-confirm stays ABSENT on the
  two-human path. Only the acting human shows the countdown.
- Timer ticks do not spam per-tick VoiceOver announcements.
- The ambient background arc travels in the real turnDirection, flips after Reverse,
  matches the HUD/central arrows, stays subordinate to cards, is accessibility-hidden,
  and freezes to a STATIC low-opacity trace under Reduce Motion / Reduced visual effects /
  Animation speed Off (direction context must remain, not disappear). No moving pulse
  outside the .playing phase.
- Active element reads through tint PLUS correct colour-blind pattern (Lava=diagonal
  hatch, Sky=horizontal, Grass=vertical, Sun=dots), with displayName + symbol chip as
  semantic truth. Grayscale still conveys turn ownership + direction via brackets, text,
  and arrow geometry.
- Sustained play with the 15 fps ambient TimelineView on >=1 iPhone and >=1 iPad: check
  for hitches, stepping, heat, and interference with card travel/overlays. If tuning is
  needed, LOWER opacity/update-rate only — never remove the static fallback or alter the
  semantic HUD.

## If verification finds bugs
Fix them minimally, within the boundaries above; if a fix needs engine semantics or a
forbidden capability, STOP and report the exact blocker instead. Re-run affected gates.
Suggested skills if available: /simulator-verify, /accessibility-audit, /swiftui-quality-review.

## Finish
- Commit any verification fixes to the SAME branch with clear messages; never force-push.
- Do NOT open a pull request unless I explicitly ask.
- Report using WORKING_FILES/phase-19/solo-phase-19-github-integration/FINAL_REPORT_TEMPLATE.md:
  exact build/test/UI-test/quality results (real output, not assumed), screenshot paths
  and state coverage, VoiceOver/Dynamic Type/Reduce Motion/colour-blind findings,
  persistence migration + reset results, ambient performance findings, deviations, and
  remaining risks. Do not claim a pass for any check you did not actually run.
```

## Getting onto the branch locally

```bash
git fetch origin claude/phase-19-wave-a-backgrounds-nn0c5q
git checkout claude/phase-19-wave-a-backgrounds-nn0c5q
```
