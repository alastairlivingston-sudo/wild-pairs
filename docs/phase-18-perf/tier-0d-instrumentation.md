# Tier-0d — Thermal / battery instrumentation (Phase 18)

Owner: performance-reliability-lead. Scope split per **ruling R7**:

- **Now (this doc):** instrument the *timer / redraw* suspects — they survive the redesign patch.
- **After the patch lands:** run the animation / energy profiling. Do **not** profile the current
  aurora/weave `TableBackground` — the patch deletes it and ships a restrained replacement
  (5 edge motes, 12 fps cap, Reduce-Motion / Reduced-Visual-Effects static fallbacks), which is
  expected to be a net energy win and is what we measure.

The owner-reported symptom is "device runs hot" during play (playtest 2026-07-17).

## Redraw / timer suspects (from code, `WildPairsApp/ViewModels/GameViewModel.swift`)

1. **Countdown tick — 5 Hz, continuous during a live round.** `startTickingIfNeeded()` sleeps
   200 ms in a loop and republishes `roundTimeRemaining` **and** `moveTimeRemaining`, both
   `@Published`. It runs the entire time either deadline is set. After **Tier-0a**, the round
   deadline is now continuously live for the whole round (a single countdown, not a per-turn
   reset), so `roundTimeRemaining` genuinely changes on every tick — meaning any view observing it
   invalidates ~5×/second for the full round, not just near a deadline. This is the prime suspect.
2. **`publishViewState()` — once per action, animated.** Re-projects the entire `GameViewState`
   from the engine and swaps it inside `withAnimation(...)`. Cost scales with how much of the tree
   diffs; fine per-action, but worth measuring under AI-heavy / draw-stack bursts.
3. **The animated background** — *excluded now* (R7): the patch replaces it. Profile the
   replacement, not the current one.

## What was instrumented (DEBUG-only, offline-safe)

A tiny `PerfSignpost` helper (bottom of `GameViewModel.swift`) emits `os_signpost` **Points of
Interest** events, compiled out entirely in release (`#if DEBUG`) and using on-device `os` logging
only — no telemetry, no network (CLAUDE.md §Enterprise Constraints stay intact):

- `publishViewState` — one event per view-state publish (suspect 2).
- `timerTick` — one event per 200 ms countdown tick (suspect 1).

In Instruments these appear on the **os_signpost** track, so tick cadence and publish frequency are
directly countable and can be correlated with CPU spikes and Core Animation commits on the timeline.

## Post-patch profiling plan (do after Tier-1 item 1)

Run on a **physical device** where possible (simulator energy figures are not representative), via
Instruments (`Time Profiler` + `SwiftUI` + `os_signpost` + `Energy Log` / `Animation Hitches`):

- **Scenarios:** (a) idle live round with no one acting — isolates the tick + background cost;
  (b) AI-heavy round (four AIs, fast think-delay) — publish burst cost; (c) a draw-stack storm.
- **Key question to answer for suspect 1:** is the 5 Hz timer republish *scoped*, or does the whole
  `GameTableView` body re-evaluate 5×/second because it reads `vm.roundTimeRemaining` /
  `vm.moveTimeRemaining` directly? If the latter, the cheap fix is to move the countdown readout
  into a small leaf view that alone observes those `@Published` values, so the table isn't
  invalidated by the tick. Confirm/refute with the SwiftUI instrument's body-evaluation counts.
- **Compare** the new background's energy against a build with the background disabled, to confirm
  R7's expectation that it is a net win.
- **Targets:** steady-state CPU and Core Animation commits during an *idle* live round should be low
  (the countdown alone should not keep the CPU busy); no sustained thermal-state escalation.

Record results and any applied fix in this folder; only then close Tier-0d.
