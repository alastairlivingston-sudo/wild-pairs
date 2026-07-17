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
2. **Design elements come from ChatGPT** (owner decision, 2026-07-17), replacing the
   `/design-direction-lab` HTML-prototype step. **One prompt**, in
   [`chatgpt-design-brief.md`](./chatgpt-design-brief.md) (same folder), with the LATEST
   screenshots attached (`docs/phase-17-design/stage3-motion/*.png` +
   `partner-view/impl-active-half-beth-turn.png`, all 2026-07-11 — not the older
   `current-ux` set). The prompt demands directly usable output: mockups, transparent-PNG
   assets, and a compiling `TableRedesignKit.swift` (SwiftUI, iOS 17) plus integration
   notes. The implementing session adapts that file to the MVVM/reducer structure and
   keeps the `/simulator-verify` parity checks exactly as before.
3. Rule/behaviour changes travel as a unit (engine + game-rules.md + CLAUDE.md + tests).
4. Verify every visual change with `/simulator-verify` (iPhone → iPad, checkpoint between),
   then `/swiftui-quality-review` and `/accessibility-audit` for anything with new affordances.
5. Commit per item; do not open a PR unless I ask.

## Work items (from ux-match-plan.md + owner playtest 2026-07-17)
**Tier 0 (bug fixes — before or parallel to design work; route via `/playtest-fix`):**
a. Round timer resets every turn instead of counting down once per round (should be a single
   3-minute round-long countdown).
b. Skip does not resolve correctly in partner/Side-to-Side mode.
c. Draw Four challenge prompt sometimes offers only "Accept", never "Decline".
d. Thermal/battery: device runs hot during play — instrument frame + energy load
   (continuous animation/timer/redraw suspects); route performance-reliability-lead.

**Tier 1 (do first):**
1. Opponent identity — bundled offline avatar/elemental crest per AI seat, glowing on their
   turn. Targets: `PlayerZoneView.swift` seat content; an `AIProfile` where seats are built in
   `GameViewModel`. Must stay compact on iPad landscape and not rely on colour alone.
2. End-of-game rank ceremony + one-tap "Play again" that restarts the full game with the same
   opponents/mode/teammate. Targets: `RoundEndView` game-over branch in `PauseMenuView.swift`;
   `restartWithSameConfig()` on `GameViewModel`. Skippable + Reduced-Motion safe.
3. Table centre + presence redesign (promoted from playtest feedback, was "Q5") — draw pile
   becomes a **stacked physical deck** (not the translucent "WP" panel); opponents show
   **fanned card backs**, not a bare count circle; the direction-of-play indicator is
   **always visible**, flips on Reverse, and whose-turn signalling gets markedly stronger.
   Targets: `TableCenterView.swift` (draw pile + direction chip at `:238`),
   `PlayerZoneView.swift` (opponent fans). Visuals come from the ChatGPT deliverables.

**Tier 2 (independent polish):**
3. Elevate the per-move timer in the final seconds (central numeral / stronger pulse; keep the
   calm bar otherwise). `MoveTimerBar` in `DecisionViews.swift` + a `GameTableView` overlay.
4. Colour-pick confirmation flourish (colour wash into the existing discard-tint pulse); keep
   the accessible swatch grid.
5. Optional AI-personality reaction bubbles (difficulty-scaled, rare, settings-gated) — the
   offline analogue to UNO's quick-chat. Run `/promoter-score-review` on this one.

Start with the Tier-0 bug fixes, then Tier 1. Show me the ChatGPT mockups/assets and stop
for my sign-off before building.

## Other issues I'm noticing (ADD YOURS HERE)
<!-- Template per issue: Screen/flow · what you saw · why it feels off · video timestamp if any -->
<!-- Playtest feedback from owner, 2026-07-17. Mix of bugs (B) and enhancements (E).
     Open questions Q1–Q6 were resolved with the owner on 2026-07-17; decisions inline. -->

- **(E) Solo! enhancements** — the one-card-left ("Solo!") mechanic wants more polish.
  **Decision (Q1): all three strands.** (a) Call-moment drama — bigger, more satisfying
  Solo! button + call animation/sound; (b) catching flow — clearer window and affordance to
  catch an AI that forgot, with a visible +2 penalty moment; (c) AI seats visibly react to
  calls/catches (ties into Tier-2 item 5). [new work item; design via ChatGPT mockups]
- **(B/perf) Device runs hot** — phone heats up during play; suspected too battery-intensive.
  Likely continuous animation/timer/redraw load. Needs a performance pass
  (route: performance-reliability-lead / instrument frame + energy). **Now Tier-0 item d.**
- **(B+E) Partner mode** — (1) Skip is not resolving correctly in partner/Side-to-Side play
  (bug, **now Tier-0 item b**); (2) still want a small peek at my partner's hand.
  **Decision (Q2): the peek exists but is too small/hidden in this mode** — make it clearer
  and bigger without dominating the screen (partner hands are open by design per CLAUDE.md).
- **(E) Turn-order + whose-turn clarity** — the direction-of-play indicator (clockwise /
  anticlockwise) should be **always visible** and flip when order reverses; and more broadly
  it's **too subtle whose turn it is**. **Decision (Q3): folded into the new Tier-1 item 3**
  (table centre + presence redesign), alongside Tier-1 item 1's active-seat identity.
- **(E) Quick-chat** — small chat with pre-programmed phrases the player can tap
  (e.g. "Play +2", "Change colour"). **Decision (Q4): approved as a local, same-device,
  canned-phrase strip — and tapping a phrase is a REAL hint the AI partner weighs in its
  next-move heuristics** (not just cosmetic). This supersedes the match plan's "player chat"
  non-goal for the local case only; networked chat remains out. [new work item]
- **(B/E) Middle-of-table redesign** — the centre is poorly designed (see
  `docs/phase-17-design/current-ux/iphone-02-table-autostart.png`). The draw pile should look
  like a **stack of physical cards**, not the current translucent panel; and I should see the
  **backs of opponents' cards** (fanned hand), not just a count.
  **Decision (Q5): promoted to Tier-1 item 3.**
- **(B) Challenge flow** — the challenge prompt (Draw Four challenge, Phase 17 B2) does not
  reliably offer both choices; sometimes only "Accept" is available, never "Decline". Bug,
  **now Tier-0 item c.**
- **(E) Colour renaming** — **Decision (Q6): confirmed mapping** — `crimson` → **Lava** (red),
  `cobalt` → **Sky** (blue), `jade` → **Grass** (green), `amber` → **Sun** (yellow), replacing
  Fire/Rain/Earth/Wind. Display-only via `CardColour.displayName`; internal names, raw values,
  and save files never change (same pattern as the Phase 11 retheme). Update the symbols/
  patterns doc row + VoiceOver strings that read through `displayName`.
- **(B) Round timer resets** — the 3-minute *total* round timer is being reset after every
  turn instead of counting down for the whole round. Bug — it should be a single round-long
  countdown. **Now Tier-0 item a.**

<!-- Candidate observations from the analysis — keep, edit, or delete:
- Wild colour picker is a flat 2x2 swatch grid; feels less satisfying than the video's
  centre-stage pick. (Partly covered by item 4 — decide if you want more.)
- Opponent hand shows as a card-back *pile* with a count chip, not a fanned hand; the video's
  fanned backs read more like real held cards. Decide if the pile should fan.
- The per-move timer as a thin bar above the hand is easy to miss; item 3 addresses urgency
  but you may want the timer more present the whole turn.
-->
