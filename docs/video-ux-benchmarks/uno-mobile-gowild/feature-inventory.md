# Feature Inventory — UNO Mobile "GoWild ×8 2v2"

Produced by `/video-ux-analysis`. Evidence unit is the observed frame, not the transcript.

| Field | Value |
|---|---|
| Source | YouTube `SvKL7SAWqGA` — "Day 201 – UNO Mobile Gameplay \| Pixelstreak \| Road to 300 Begins" |
| Duration | 112 s (analysed from 0:08 per request) |
| Game | UNO Mobile (Mattel163) — the commercial app |
| Mode observed | **GoWild ×8, 2v2 teams** (confirmed on the results banner, 1:32) |
| Acquisition | User-supplied local 640×290 file (YouTube blocked datacenter download) |
| Frames read | 27 scan (0:08→1:52, 4 s cadence) + 8 zoom (0:35–0:37 @2 fps, 1:00–1:02 @1 fps) |

**Legal note:** this catalogues *interaction patterns and behaviours*, never UNO's artwork, names, mascots, or trade dress. Entries describe what the UI does, not how it is branded.

---

## Navigation & IA
- **Persistent HUD frame** — settings gear (top-right), soft-currency coin/gift icons (top-right), a help "?" (bottom-right), a "Chat"/emote button (bottom-left) sit in fixed corners around the table the whole match. `08s–1:12s`. *High confidence.*

## Table layout & hierarchy
- **4 seats, human anchored bottom.** Human ("ecortv") hand fanned across the bottom; opponents top-left ("Xacobe"), right ("Odette"), and a top-centre seat behind the deck; each opponent shown as an **avatar portrait + a fanned stack of card-backs**. `08s`. *High.*
- **Central table focus = draw deck + discard pile** side by side in the middle, deck labelled with the game's back art. `08s–1:12s`. *High.*
- **Opponent hand size is legible from the back-fan width** and a small count; the fan visibly grows/shrinks as they draw/play. `16s, 44s`. *High.*

## Turn flow & feedback (the strongest area)
- **Large central turn-timer numeral** — a big gold "4" counts down in the dead-centre of the table on a turn. `08s`. *High.*
- **Active-player highlight** — the current player's avatar gets a pulsing gold frame; it visibly hands off between seats. `16s (Xacobe), 35.5s (Odette lit), 60s (ecortv lit)`. *High.*
- **Turn hand-off light-sweep** — a light streak sweeps across the table from the finishing seat toward the next as the turn passes. `35.0s→35.5s`. *High.*
- **Cards physically fly hand→pile along a curved arc with a motion trail**; a red card lands on the discard with an orange curved-arrow trail. `28s, 35.5s→36.5s`. *High.*
- **Draw animation** — cards arc back from the deck toward a seat. `throughout`. *Medium (motion inferred from stills + trails).*

## Action-card moments
- **Skip** throws an oversized red ⊘ into the table centre as feedback. `20s, 24s`. *High.*
- **Draw penalty stamps a red "⊘ +4" badge directly on the victim's avatar**, not in a log. `44s, 48s, 1:08s`. *High.*
- **Wild colour picker** — playing a wild blooms a large **3D four-colour cube (green/blue/red/yellow blocks)** in the table centre, ringed by a rotating gold glow; the active player taps a block. `40s, 1:00s–1:02s`. *High.*
- **Colour-chosen confirmation** — a big red **"Red"** splash fills the centre once the colour is picked. `1:12s`. *High.*

## HUD (scores, timers, indicators)
- **"CALL UNO" button** — permanent red circular button, bottom-right; the one-card call is a physical race-to-tap. `08s–1:12s`. *High.*
- **Coin reward counter animates up** mid-play (a "+41" style coin tick near the currency). `1:04s`. *Medium.*
- **A "Winner" ribbon/tag** sits near the top-centre seat throughout — likely a season/leaderboard flag ("Road to 300"). `08s–1:16s`. *Low (meaning inferred).*

## Dialogs & prompts
- **Quick-chat / canned emote bubbles** pop over a player's avatar: "Hi!", "Hit UNO!", and post-game "Thanks to you! Another round?". `16s, 20s, 52s, 1:40s`. *High.*
- A finger/tap cursor is the streamer's own recording overlay, not game UI. `1:04s`. *High (excluded from analysis).*

## Endgame & celebration (elaborate — ~30 s of the 112 s)
- **Achievement toast** — "Achievement 'Proof Of Strength' unlocked!" banner fires mid-sequence. `1:16s`. *High.*
- **Per-player points tally animates in** over the table (POINTS −0 / −242 / −91 / −22). `1:16s`. *High.*
- **"SUPER WIN" coin-fountain payout** — big blue ribbon + coins raining, a coin total counting up (1,589 → 1,992), "Tap to Skip". `1:20s, 1:24s`. *High.*
- **Rewards claim screen** — "CONGRATULATIONS": **Coins ×50, Pass Points ×5, Puzzle Pieces ×5**, a "DAILY TASK" line, green **Claim** button. `1:28s`. *High.*
- **Ranked results scoreboard** — mode header "GoWild ×8 2v2"; 1st/2nd **trophy ranks**; rows for Winner / ecortv / Odette / Xacobe with a Coins column and **"Daily double bonus +16" / "×8 mode bonus +4"**; a **"PROFESSIONAL" tier badge** with a countdown ("02d 15h 11m") and per-player level + progress bar; per-row **thumbs-up / add-friend** icons; share/export icons; a market/shop icon. `1:32s–1:48s`. *High.*
- **One-tap rematch** — **"Play again"** and **"Play again with teammate"** buttons; a cross-promo banner ("…Let's GO even WILDER!"). `1:40s–1:48s`. *High.*

## Motion / juice summary
Every state change is *shown*: timer numeral, avatar glow hand-off, light-sweep, arced card flight with trails, oversized effect symbols, penalty badges on the target, colour-cube bloom, coin fountains, confetti-grade celebration. Nothing changes silently.

## What was NOT observable
- Match *setup* (the earlier "CHOOSE ITEMS" multiplier lobby, seen only as corrupted storyboard before the file was supplied) — not in this 0:08→end window.
- Loading, error, disconnect, and empty states (promotional gameplay hides them).
- Exact animation *durations* (inferred from 2 fps sampling, not frame-accurate).
- Audio/haptics (no signal from video).
