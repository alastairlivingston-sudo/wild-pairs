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
<!-- Playtest feedback from owner, 2026-07-17. Mix of bugs (B) and enhancements (E).
     Cross-refs to the Tier work items above noted in [brackets]. -->

- **(E) Solo! enhancements** — the one-card-left ("Solo!") mechanic wants more polish.
  Scope TBD — see open question Q1. [related to HUD Solo! button, not yet in a work item]
- **(B/perf) Device runs hot** — phone heats up during play; suspected too battery-intensive.
  Likely continuous animation/timer/redraw load. Needs a performance pass
  (route: performance-reliability-lead / instrument frame + energy). Not in any work item yet.
- **(B+E) Partner mode** — (1) Skip is not resolving correctly in partner/Side-to-Side play
  (bug); (2) still want a small peek at my partner's hand. Note: CLAUDE.md says partner hands
  are *open by design* and the human should already see the AI partner's hand — so this reads
  as the peek affordance being missing/too hidden in this mode. See Q2.
- **(E) Turn-order + whose-turn clarity** — the direction-of-play indicator (clockwise /
  anticlockwise) should be **always visible** and flip when order reverses; and more broadly
  it's **too subtle whose turn it is**. Overlaps Tier-1 item 1 (active-seat identity) and the
  existing direction chip (`TableCenterView.swift:238`) — but current prominence is judged
  insufficient by the owner. See Q3.
- **(E) Quick-chat** — want a small chat with pre-programmed phrases the player can tap
  (e.g. "Play +2", "Change colour"). NOTE potential conflict: the plan lists *player* chat as a
  DIVERGENT non-goal and offers only AI-personality reactions (Tier-2 item 5). A local,
  same-device, canned-phrase chat needs no network, so it may be compliant — needs a decision.
  See Q4.
- **(B/E) Middle-of-table redesign** — the centre is poorly designed (see attached screenshot).
  The draw pile should look like a **stack of physical cards**, not the current translucent
  panel; and I should see the **backs of opponents' cards** (fanned hand), not just a count.
  Overlaps the two "candidate observations" below (fan the opponent pile; pick-up pile look).
  This is arguably a new Tier-1 item. See Q5.
- **(B) Challenge flow** — the challenge prompt (Draw Four challenge, Phase 17 B2) does not
  reliably offer both choices; sometimes only "Accept" is available, never "Decline". Bug.
- **(E) Colour renaming** — rename the displayed colours: sky (blue), grass (green), sun
  (yellow), lava (red). NOTE: Solo's colours are the elemental Fire/Rain/Earth/Wind set
  (internal `crimson`/`cobalt`/`jade`/`amber`), a display-only theme; this is a request for a
  *new* display theme via `CardColour.displayName` (internal names never change). Mapping needs
  confirming — see Q6.
- **(B) Round timer resets** — the 3-minute *total* round timer is being reset after every
  turn instead of counting down for the whole round. Bug — it should be a single round-long
  countdown.

<!-- Candidate observations from the analysis — keep, edit, or delete:

<!-- Candidate observations from the analysis — keep, edit, or delete:
- Wild colour picker is a flat 2x2 swatch grid; feels less satisfying than the video's
  centre-stage pick. (Partly covered by item 4 — decide if you want more.)
- Opponent hand shows as a card-back *pile* with a count chip, not a fanned hand; the video's
  fanned backs read more like real held cards. Decide if the pile should fan.
- The per-move timer as a thin bar above the hand is easy to miss; item 3 addresses urgency
  but you may want the timer more present the whole turn.
-->
