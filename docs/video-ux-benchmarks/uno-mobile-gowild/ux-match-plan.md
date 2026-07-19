# UX Match Plan — informed by UNO Mobile "GoWild ×8"

Prioritised by player-visible impact ÷ effort. Each item names target files, the *behaviour*
to build (a pattern, never UNO's art/brand), risks, and its verification route. This is a
**proposal** — implementation starts only on the items you pick.

Grounding: the [gap analysis](./gap-analysis.md) shows Solo already matches UNO's in-round
feel. So this plan is deliberately short and avoids re-building what exists. Everything here
respects CLAUDE.md's offline / no-IAP / no-network / no-GameKit constraints.

---

## Tier 1 — high impact, contained effort

### 1. Opponent identity (avatar portraits for AI seats)
- **Gap:** MISSING. Solo's opponents are a name + card-back pile; UNO's have portraits, which
  is most of why its table feels *populated*.
- **Behaviour:** give each AI a bundled, offline avatar (abstract/elemental crest, not people —
  fits the Fire/Rain/Earth/Wind identity) shown in the seat, glowing on their turn like the
  human's frame already does.
- **Targets:** `PlayerZoneView.swift:90` `seatContent` (add avatar above the pile);
  a small `AIProfile` (name + crest) sourced where seats are built in `GameViewModel`.
- **Risk:** iPad landscape height is scarce (`GameTableView.swift:76`) — avatar must be
  optional/compact there. Colour-blind: crest must not rely on colour alone.
- **Verify:** `/simulator-verify` iPhone→iPad; `/accessibility-audit` (new visual affordance);
  `/swiftui-quality-review`.

### 2. End-of-game rank ceremony + fast rematch
- **Gap:** PARTIAL. `RoundEndView` is tasteful but the *game-over* moment offers only "Back to
  Home"; UNO's rank ceremony + one-tap rematch is a big retention/feel win.
- **Behaviour:** on game over, (a) a brief rank reveal — winning team's trophy, final scores,
  and the **score multiplier already in the engine** dramatised ("×8 — toughest AI bonus",
  from CLAUDE.md Difficulty multipliers) as a *bonus breakdown* line; (b) a **"Play again"**
  button that restarts a full game with the *same opponents, mode, and teammate* without a trip
  through New Game setup.
- **Targets:** `PauseMenuView.swift:55` `RoundEndView` (game-over branch, currently `:152`
  "Back to Home"); a `restartWithSameConfig()` on `GameViewModel` reusing the prior
  `GameConfiguration`.
- **Risk:** don't fake a currency payout — dramatise *score*, not coins. Keep the ceremony
  skippable (tap-to-continue) and under Reduced Motion.
- **Verify:** `/simulator-verify`; `/ux-review` (HIG, celebration restraint); regression that
  "Play again" preserves mode + difficulty + team layout.

## Tier 2 — cheap prominence tweaks (borrow the *drama*, keep our restraint)

### 3. Elevate the per-move timer at the crunch
- **Gap:** PARTIAL. UNO's big central numeral vs Solo's thin `MoveTimerBar`.
- **Behaviour:** in the final seconds (it already flags urgent ≤3 s, `DecisionViews.swift:330`),
  add a brief central countdown numeral or a stronger pulse so time pressure is *felt*. Keep
  the calm bar for the non-urgent majority.
- **Targets:** `DecisionViews.swift:325` `MoveTimerBar` + a small central overlay in
  `GameTableView` on the local turn.
- **Risk:** must not obscure the hand/table; respect Reduced Motion. **Verify:** `/simulator-verify`.

### 4. Wild colour-pick: a touch more theatre
- **Gap:** PARTIAL. Compact swatch grid vs UNO's glowing cube + "Red" splash.
- **Behaviour:** keep the accessible swatch grid (`DecisionViews.swift:10`) but add a short
  confirmation flourish on choose — a colour wash from the picker into the discard-tint pulse
  that already exists (`TableCenterView.swift:173`). No full-screen takeover.
- **Risk:** low; purely additive motion, gated by Reduced Motion. **Verify:** `/simulator-verify`.

### 5. AI-personality reactions (the compliant analogue to quick-chat)
- **Gap:** DIVERGENT (player chat is out). But UNO's bubbles make opponents feel *alive*.
- **Behaviour:** occasional, difficulty-scaled canned reaction bubbles from AI seats on notable
  events (caught your Solo!, hit you with +4, went out) — e.g. a wry line over the AI's avatar.
  Purely local flavour text, off by a setting, never during calm play.
- **Targets:** new lightweight reaction on `PlayerZoneView` seat; event hooks off existing
  `seatCue`/turn events in `GameViewModel`.
- **Risk:** annoyance/pacing — must be rare, skippable, and settings-gated. Tone per
  `docs/ux-spec.md` voice. **Verify:** `/ux-review`; `/promoter-score-review` (does it delight
  or grate across personas?).

## Explicit non-goals (DIVERGENT-BY-DESIGN — do not build)
Coins / soft-currency payouts · "SUPER WIN" reward fountains · battle-pass Pass Points ·
puzzle-piece collections · daily tasks · store/IAP · matchmaking / online play · friends /
thumbs-up / add-friend · GameKit achievements & leaderboards · seasons ("Road to 300").
Every one requires network, accounts, IAP, or telemetry — forbidden by CLAUDE.md Enterprise
Constraints. The compliant substitutes are already noted (dramatise *score* not coins; a local
"personal best" toast instead of GameKit achievements).

---

## Recommended sequence
Tier 1 first (items 1 → 2): they close the only real gaps and carry the most player-visible
weight. If pursued as a redesign of the seat and end-of-game surfaces, route through
`/design-direction-lab` (prototype the avatar seat + rank ceremony in HTML before SwiftUI).
Tier 2 (3 → 4 → 5) are independent polish, each shippable alone. Before coding Tier 1, run
`/premortem` then `/promoter-score-review` per `.claude/ROUTER.md`.
