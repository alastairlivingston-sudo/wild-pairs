# Gap Analysis — UNO Mobile "GoWild ×8" vs Solo (current build)

Each observed feature is judged against `docs/ux-spec.md`, `docs/design-system.md`, and the
shipped SwiftUI views. Verdicts: **MATCHED** · **PARTIAL** · **MISSING** ·
**DIVERGENT-BY-DESIGN** (deliberately different; usually the offline/no-IAP constraint) ·
**N/A** (different mechanics).

**Headline:** Solo already matches the great majority of UNO Mobile's *in-round game feel*.
The build is mature — cross-table travel, turn hand-off sweep, active-seat glow, stack pops,
seat cues, direction spin, playable-card lift and confetti are all present. The genuine gaps
are narrow: **opponent identity/personality**, **endgame celebration intensity + one-tap
rematch**, and a few **micro-affordances**. Roughly half of the video's UX is a
monetisation/online-meta layer that is correctly out of scope.

---

## Turn flow & feedback

| Video feature | Verdict | Evidence in Solo |
|---|---|---|
| Cards fly hand→pile on an arc with a trail | **MATCHED** | `CardTravelOverlay.swift:53` `FlyingCardView`, launched from `GameTableView.swift:438` `launchFlight`; arc via `Theme.Motion.playArc` |
| Turn hand-off light-sweep between seats | **MATCHED** | `CardTravelOverlay.swift:117` `TurnSpotlightView`; `GameTableView.swift:472` `launchSpotlight` sweeps orb old→new seat |
| Active-player highlight (pulsing frame) | **MATCHED** | `PlayerZoneView.swift:150` `glowColor` + `:166` `triggerArrivalPop` (pulse + arrival scale pop) |
| Draw animation (cards arc from deck) | **MATCHED** | `CardTravelOverlay.swift:86` `FlyingBackView`; `GameTableView.swift:452` staggers by count so a big penalty reads longer |
| Large **central** turn-timer numeral | **PARTIAL** | Solo has a per-move timer as a *thin bar* above the hand (`DecisionViews.swift:325` `MoveTimerBar`), not a big central countdown. Information parity; lower prominence/drama |
| Direction indicator, reverse felt | **MATCHED (exceeds)** | `TableCenterView.swift:238` always-on direction chip; `:286` spins 360° + "Reversed!" flash on reverse |

## Action-card moments

| Video feature | Verdict | Evidence in Solo |
|---|---|---|
| Skip shows an oversized central symbol | **PARTIAL** | Solo stamps "SKIPPED" *on the skipped seat* (`PlayerZoneView.swift:129`) rather than a big table-centre symbol — arguably clearer (shows *who*), but less spectacle |
| Draw penalty badge on the victim | **MATCHED** | `PlayerZoneView.swift:136` `.drew(n)` red "+N" cue stamped on the seat; escalating stack pop `TableCenterView.swift:326` |
| Wild colour picker | **PARTIAL** | `DecisionViews.swift:10` `ColourPickerView` is a compact 2×2 swatch grid (in-table overlay, colour-blind pattern + name support). UNO's is a large 3D cube with glow — Solo's is more restrained/accessible, less theatrical |
| Colour-chosen confirmation splash | **PARTIAL** | Solo re-prints the wild in the chosen colour with a pulse (`TableCenterView.swift:173`) + colour-chip pulse (`:271`); no full-screen "Red" splash |

## HUD & indicators

| Video feature | Verdict | Evidence in Solo |
|---|---|---|
| One-card call as a permanent race-to-tap button | **MATCHED** | `GameTableView.swift:302` always-visible **Solo!** button, enabled only at the legal moment; catch-out via tapping a seat (`PlayerZoneView.swift:71`) |
| Opponent hand-size readable at a glance | **MATCHED (exceeds)** | `PlayerZoneView.swift:212` `opponentPile` footprint grows with count; `:43` `countTint` turns caution/critical at 2/1 cards |
| "Points at risk" surfaced live | **MATCHED (Solo-only)** | `GameTableView.swift:322` "On the table: N pts" — Solo has this; UNO does not surface it |
| Coin reward tick during play | **DIVERGENT-BY-DESIGN** | Solo is offline, no soft currency (CLAUDE.md Enterprise Constraints) — no coins to tick |

## Opponent identity & social

| Video feature | Verdict | Evidence in Solo |
|---|---|---|
| Opponent **avatar portraits** with names | **MISSING** | Solo shows a name label + card-back pile only (`PlayerZoneView.swift:90`); AI opponents have no visual identity/portrait |
| Quick-chat / canned emote bubbles | **DIVERGENT-BY-DESIGN** | Human↔human chat is an online-social feature; Solo is offline same-device. An *AI-personality reaction* is the compliant analogue (see match plan), not player chat |
| Thumbs-up / add-friend per player | **DIVERGENT-BY-DESIGN** | Social graph — no accounts, no network (CLAUDE.md) |

## Endgame & celebration

| Video feature | Verdict | Evidence in Solo |
|---|---|---|
| Win celebration (confetti + glow) | **MATCHED** | `PauseMenuView.swift:88` `RoundEndView` — trophy, confetti, team-colour win wash; reduced-motion static badge |
| Round/game scoreboard | **MATCHED** | `PauseMenuView.swift:124` per-team score rows + "WON" tag; round-award line `:115` |
| **Escalating "SUPER WIN" payout / reward fountain** | **DIVERGENT-BY-DESIGN** | Coin/pass/puzzle rewards are IAP-economy; no offline analogue for *rewards*. The *escalation feel* (a bigger win reads bigger) is a legitimate borrow, minus currency |
| **Ranked results with trophies / tiers / bonuses** | **PARTIAL** | Solo shows team scores but no per-round *rank ceremony* (1st/2nd trophy, "×N mode bonus" breakdown). Solo does have a score multiplier by toughest AI (CLAUDE.md Difficulty) that is *not* dramatised at round end |
| **One-tap "Play again" / "Play again with teammate"** | **PARTIAL** | Solo has "Next round" within a game (`PauseMenuView.swift:146`) but **no fast rematch of the whole game with the same opponents/teammate** from the game-over screen (only "Back to Home") |
| Achievement toast | **DIVERGENT-BY-DESIGN** | No GameKit/achievements (CLAUDE.md forbids GameKit). A local "personal best" toast is a possible compliant analogue |

## Meta / progression (whole-app, mostly out of scope)

| Video feature | Verdict |
|---|---|
| Battle-pass "Pass Points", puzzle-piece collection, daily tasks, soft-currency store, matchmaking, seasons/leaderboards ("Road to 300") | **DIVERGENT-BY-DESIGN** — every one depends on network, accounts, IAP, or telemetry, all forbidden by CLAUDE.md Enterprise Constraints. Not gaps; deliberate non-goals |

---

## Summary counts
- **MATCHED (incl. exceeds):** 10 — the in-round core.
- **PARTIAL:** 6 — prominence/spectacle deltas, not missing capability.
- **MISSING:** 1 — opponent avatar identity.
- **DIVERGENT-BY-DESIGN:** 7 — the monetisation/online layer.

The takeaway for the match plan: **don't rebuild the engine feel — it's there.** Invest in the
two places Solo reads flatter than UNO for reasons unrelated to the offline constraint:
**opponent personality** and the **end-of-game moment (rank ceremony + fast rematch)**, plus a
short list of cheap prominence tweaks.
