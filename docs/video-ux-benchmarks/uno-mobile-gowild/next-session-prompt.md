# Task: Implement the UNO-Mobile-informed UX improvements for Solo (Wild Pairs)

> Paste-ready brief for a fresh session. Assumes you start cold.

## Context (read these first)
- Repo: `alastairlivingston-sudo/wild-pairs`. Work on branch `claude/game-ux-video-analysis-29ddem`
  (branch from latest default if it's already merged).
- Read `CLAUDE.md` (identity, offline/no-IAP/no-network/no-GameKit enterprise constraints,
  design vocabulary) and `.claude/ROUTER.md` (skill/agent routing) before doing anything.
- Read the benchmark under `docs/video-ux-benchmarks/uno-mobile-gowild/`:
  `feature-inventory.md`, `gap-analysis.md`, `ux-match-plan.md`. The match plan is the spec
  for this task.
- Key finding to respect: **the in-round game feel is already built** (cross-table card
  travel, turn hand-off sweep, active-seat glow, stack pops, seat cues, playable-card lift,
  confetti). Do NOT rebuild it. The real gaps are opponent identity and the end-of-game moment.
- Hard boundary: anything needing network, accounts, IAP, telemetry, or GameKit is a
  non-goal (see the match plan's non-goals list). Dramatise *score*, never coins.

## Process (per .claude/ROUTER.md)
1. Before coding the Tier-1 items, run `/premortem` then `/promoter-score-review`.
2. For the seat + end-of-game redesign, use `/design-direction-lab` (HTML prototypes → my
   pick → SwiftUI with parity) rather than implementing by eye.
3. Rule/behaviour changes travel as a unit (engine + game-rules.md + CLAUDE.md + tests).
4. Verify every visual change with `/simulator-verify` (iPhone → iPad, checkpoint between),
   then `/swiftui-quality-review` and `/accessibility-audit` for anything with new affordances.
5. Commit per item; do not open a PR unless I ask.

## Work items (from ux-match-plan.md)
**Tier 1 (do first):**
1. Opponent identity — bundled offline avatar/elemental crest per AI seat, glowing on their
   turn. Targets: `PlayerZoneView.swift` seat content; an `AIProfile` where seats are built in
   `GameViewModel`. Must stay compact on iPad landscape and not rely on colour alone.
2. End-of-game rank ceremony + one-tap "Play again" that restarts the full game with the same
   opponents/mode/teammate. Targets: `RoundEndView` game-over branch in `PauseMenuView.swift`;
   `restartWithSameConfig()` on `GameViewModel`. Skippable + Reduced-Motion safe.

**Tier 2 (independent polish):**
3. Elevate the per-move timer in the final seconds (central numeral / stronger pulse; keep the
   calm bar otherwise). `MoveTimerBar` in `DecisionViews.swift` + a `GameTableView` overlay.
4. Colour-pick confirmation flourish (colour wash into the existing discard-tint pulse); keep
   the accessible swatch grid.
5. Optional AI-personality reaction bubbles (difficulty-scaled, rare, settings-gated) — the
   offline analogue to UNO's quick-chat. Run `/promoter-score-review` on this one.

Start with Tier 1. Show me the prototypes/screenshots and stop for my pick before building.

## Other issues I'm noticing (ADD YOURS HERE)
<!-- Template per issue: Screen/flow · what you saw · why it feels off · video timestamp if any -->
-
-
-

<!-- Candidate observations from the analysis — keep, edit, or delete:
- Wild colour picker is a flat 2x2 swatch grid; feels less satisfying than the video's
  centre-stage pick. (Partly covered by item 4 — decide if you want more.)
- Opponent hand shows as a card-back *pile* with a count chip, not a fanned hand; the video's
  fanned backs read more like real held cards. Decide if the pile should fan.
- The per-move timer as a thin bar above the hand is easy to miss; item 3 addresses urgency
  but you may want the timer more present the whole turn.
-->
