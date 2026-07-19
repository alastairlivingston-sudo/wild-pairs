---
name: video-ux-analysis
description: Analyse a YouTube gameplay video for observable UX features and behaviours (not the transcript), compare them against Solo's current design and build, and produce a gap analysis plus a prioritised plan to match the video's UX. Invoke when the user shares a game video link with intent like "match this UX", "why does this game feel better", "analyse this gameplay video", or "benchmark against this".
---

# Skill: Video UX Analysis

## Purpose
Turn a YouTube video of a card/board game into design evidence: a catalogue of what the
video's UI actually *does* — layout, feedback, animation, turn flow, affordances — mapped
against Solo's current spec and SwiftUI build, ending in a prioritised match plan. The
transcript is explicitly secondary; the unit of evidence is the frame.

## When to Invoke
- User shares a game video and wants its UX understood, compared, or matched
- Benchmarking before a redesign phase (feeds `/design-direction-lab` with concrete references)
- NOT for judging our own app's screenshots — that is `/design-critique`

## Inputs Required
- A YouTube URL, or a local video file path (the fallback when download fails)
- Optional but valuable (each one cuts token cost): focus areas ("card play feedback",
  "menus"), known-interesting timestamp ranges, target platform of the filmed game

## Token-Efficiency Contract
Frames are read as **timestamped contact sheets** (one image read = 4–16 frames), never as
raw video or per-frame reads. Budgets per analysis, absent user instruction otherwise:
- Pass 1 (scan): ≤ 8 sheet reads — 3×3 tiles @480px, legible for overall layout
- Pass 2 (zoom): ≤ 12 sheet reads — 2×2 tiles @800px, legible for HUD text and micro-UI
- Full-resolution single frames only when a specific detail is unreadable on a zoom sheet
- Videos > 20 min: use chapters/user focus to pick segments; never scan uniformly
- All intermediates live in the scratchpad; the inventory markdown is the persistent record,
  so a re-run never re-reads what is already written down

## Steps

1. **Fetch.** `scripts/fetch_video.sh <url-or-local-file> <scratch-dir> [--max-height 720] [--section "*MM:SS-MM:SS"]`
   — installs yt-dlp/ffmpeg if missing, writes `meta.json` (title, duration, chapters), and
   walks the acquisition ladder: **local file (best)** → HLS m3u8 (works when exposed) → DASH/
   progressive (usually 403 here) → storyboard (last resort, ~396x180, HUD-unreadable).
   Reality check (proven 2026-07): YouTube gates real streams behind a PO token this
   datacenter IP cannot mint, so **many videos will not download here at all** — the reliable
   path is the user downloading the video on their machine and re-running with the file path.
   Ask for the file the moment only the storyboard is reachable; do not fight the wall
   further or try to analyse UX from storyboard glitch.

2. **Plan the sampling** from `meta.json`: duration and chapter titles decide scan interval
   and which segments matter. State the plan in one paragraph before extracting.

3. **Pass 1 — scan.** `scripts/extract_frames.sh scan <video> <dir> [--frames 54]`
   (or `scenes` mode for menu-heavy footage). Read each sheet; keep a running timeline log:
   timestamp → screen/moment → what is visible. Output of this pass: the list of segments
   worth zooming, each with a one-line reason.

4. **Pass 2 — zoom.** For each chosen segment:
   `scripts/extract_frames.sh zoom <video> <dir> --start T --end T [--fps 2]`.
   This is where *behaviour* is observed, not just layout: what changes between consecutive
   frames (what animates, what highlights, what a tap produced), element order, timing
   feel (how many frames a transition spans at the known fps), feedback loops (play card →
   what confirms it), empty/error/edge states if filmed.

5. **Write the feature inventory** at `docs/video-ux-benchmarks/<slug>/feature-inventory.md`.
   Group by: Navigation & IA · Table layout & hierarchy · Hand/card interaction · Turn flow
   & feedback · Action-card moments · HUD (scores, timers, indicators) · Dialogs & prompts ·
   Onboarding/help · Endgame & celebration · Settings · Accessibility signals · Motion/juice.
   Every entry: timestamp(s), observed behaviour in one or two sentences, confidence
   (video evidence is partial — mark inferences as inferences).

6. **Gap analysis** at `docs/video-ux-benchmarks/<slug>/gap-analysis.md`. Compare each
   inventory entry against `docs/ux-spec.md`, `docs/design-system.md`, and the actual
   SwiftUI views. Verdict per feature: **MATCHED / PARTIAL / MISSING / DIVERGENT-BY-DESIGN /
   NOT-APPLICABLE** (different mechanics), each with evidence (`file:line` or spec section).
   Do not soften: "we have a settings screen" is not a match for "settings edits apply live
   behind the sheet".

7. **Match plan** at `docs/video-ux-benchmarks/<slug>/ux-match-plan.md`. Prioritised by
   player-visible impact vs effort; each item names the target views/files, the behaviour to
   build (pattern, not pixels), risks, and its verification route (`/simulator-verify`,
   `/ux-review`). Features that conflict with standing constraints (network play, telemetry,
   store) get an explicit non-goal entry with the offline-compliant alternative. A large
   resulting plan routes through the normal process: `/premortem` → `/promoter-score-review`
   before implementation.

8. **Checkpoint.** Present the inventory highlights and the plan's top items to the user.
   The plan is a proposal — implementation starts only when the user picks items.

## Outputs
- `docs/video-ux-benchmarks/<slug>/feature-inventory.md` — observed features with timestamps
- `docs/video-ux-benchmarks/<slug>/gap-analysis.md` — verdict per feature with evidence
- `docs/video-ux-benchmarks/<slug>/ux-match-plan.md` — prioritised, verifiable match plan

## Legal & Constraint Guardrails
- **Patterns, not property.** The video may show trademarked games (possibly UNO itself).
  Catalogue interaction patterns and behaviours; never copy artwork, names, mascots, sounds,
  or distinctive trade dress. Inventory entries describe behaviour ("drawn cards arc from
  deck to hand with a bounce"), never brand ("make it look like UNO's").
- **No video frames in the repo.** Frames stay in the scratchpad; committed docs carry the
  URL + timestamps so evidence is re-derivable. Keeps the repo clean of third-party imagery.
- **Network tooling is session tooling.** Downloading happens in the remote Claude Code
  container (or the user supplies a file). Nothing here touches the app target, and the
  enterprise constraints in CLAUDE.md (no networking in the app, no new permissions) bind
  every item that lands in the match plan.

## Common Pitfalls
- Reading frames one at a time — always tile; a sheet costs the same as a single frame
- Cataloguing static layout only and missing behaviour — pass 2 exists to diff consecutive
  frames; "what happened between 12.0s and 12.5s" is the whole point
- Trusting the video too much: promotional footage hides loading, errors, and edge states;
  mark what was *not observable* so the plan doesn't assume it
- Uniformly scanning a 40-minute let's-play instead of asking the user which minutes matter
- Writing the match plan as pixel-copying instead of behaviour-matching — that way lies both
  legal trouble and a design that ignores our own design system
