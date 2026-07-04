# Phase 12 — "Elemental Live" Visual Redesign Plan

**Status:** Approved for implementation (this document is the gate).
**Scope:** Visual design only. Engine, rules, layout mechanics, and accessibility behaviour are frozen.
**Prototype source:** `docs/phase-12-redesign/prototypes/` — direction **04 · Elemental Live**, fused with
the glass chrome of **01 · Liquid Glass**.

## 1. Direction and rationale

The game's entire identity is elemental — Fire / Rain / Earth / Wind. A modern premium card game's
table is *alive*: the environment reacts to game state instead of sitting behind it as wallpaper.
Direction 04 does exactly that — the whole scene tints to the **active colour**, with drifting
elemental motes and glowing chrome — and it is the only prototype that turns an existing game
mechanic (the current colour, which players must constantly track) into the hero of the visual
design. Glass surfaces from direction 01 give the HUD a native, current-iOS feel without inventing
a foreign design language.

What this buys, in modern-game terms:

| Modern-game checklist item | How this plan delivers it |
|---|---|
| Living, reactive environment | Scene background re-tints to the active element on every colour change |
| Ambient particles | 7 drifting elemental motes (Canvas), colour-matched to the active element |
| Glass HUD chrome | Round chip, scores, pause, partner panel, prompt, timers on one glass style |
| Turn spotlighting | Active seat gets an element-tinted glow ring + existing pulse |
| State-change feedback | Colour pill pulse (existing) + full-scene tint crossfade (new) |
| Celebration moments | Round/game win overlay keeps its card burst; gains team-colour glow wash |
| Consistent elevation | One glass recipe, one shadow scale (`Theme.Elevation`) everywhere |
| Accessibility fallbacks | Reduced Visual Effects / Reduce Motion → static neutral gradient, no motes, no pulses |

## 2. Design tokens (added to `Theme`)

### 2.1 Element scene palettes — `Theme.Element`

One `ScenePalette` per `CardColour` plus a **neutral** palette for menus and wild state.
All colours are dark-first; the base must keep white body text ≥ 7:1.

| Element | `base` (scene floor) | `aurora` blobs | `glow` (chrome accent) |
|---|---|---|---|
| Fire (`crimson`) | `#1F0A06` | `#FF5A3C` @ .22, `#FF8A5B` @ .16 | `#FF8A5B` |
| Rain (`cobalt`) | `#050F22` | `#2F8BFF` @ .22, `#4FD2F0` @ .16 | `#4FD2F0` |
| Earth (`jade`) | `#06190F` | `#16E89A` @ .22, `#3CFFB4` @ .16 | `#5EFFBF` |
| Wind (`amber`) | `#1C1405` | `#FFC83D` @ .20, `#FFE08A` @ .14 | `#FFD34D` |
| Neutral (menus/wild) | `#0D0820` (existing `Felt.baseDark`) | accent teal @ .18, violet `#7A5CFF` @ .12 | `Palette.accent` |

Aurora blobs are two radial gradients anchored lower-left / mid-right (per prototype 04),
drawn behind a radial centre highlight and in front of the base. Vignette (existing) stays on top.

### 2.2 Glass surface — `.wpGlass(cornerRadius:tint:)`

Single recipe used by every piece of chrome:
`ultraThinMaterial` base → black .25 wash (keeps it dark over bright auroras) → 1px stroke
`white .16` (or element tint .35 when highlighted) → inner top highlight (`white .18`, top edge)
→ `Elevation.resting` shadow. Reduced Visual Effects swaps material for flat `black .45`.

### 2.3 Motes

7 motes, 5–6pt rounded squares rotated 45°, element-glow colour, `blur(0.5)` + soft shadow,
rising bottom→top over 8–13s with fade-in/out, driven by `TimelineView(.animation)` + `Canvas`.
Skipped entirely under Reduced Visual Effects or Reduce Motion.

### 2.4 Motion

- Scene tint crossfade on colour change: `easeInOut(duration: 0.8)`.
- Colour pill: existing change-pulse retained; glow shadow now uses element `glow` colour.
- Everything else keeps `Theme.Motion` as-is. No new springs.

## 3. Per-screen breakdown and acceptance criteria

### 3.1 Game table (iPhone) — the hero screen
- **Background** becomes element-reactive (`vs.currentColour`); menus keep neutral.
  *AC: playing a colour-changing card visibly re-tints the whole scene within 1s; under Reduced
  Visual Effects the background is a static neutral gradient with no motes.*
- **HUD row** (round chip / team scores / pause) → glass pills, one consistent height.
  *AC: legible over all four element tints; never wraps.*
- **Partner panel** → glass card with `PARTNER · N CARDS` micro-tag header (tracked caps).
  *AC: partner mini-cards unchanged and readable; panel reads as one grouped surface.*
- **Opponent avatars** → glass circles; active/thinking seat rings and glows in the element colour.
  *AC: whose-turn is readable at arm's length.*
- **Colour pill** → filled with element gradient, ink per contrast rule, glow in element colour.
  *AC: the pill is the single brightest chrome element on the table.*
- **Prompt banner** → glass with soft element-tint border.
  *AC: identical copy, `game-prompt` identifier intact.*
- **Points-at-risk pill** → reword "Team at risk: N pts" → **"On the table: N pts"** (the original
  critique flagged the wording as alarming). Accessibility label keeps the full explanation.
- **Timers** (round badge, move bar) → glass capsule / tinted bar; behaviour unchanged.
- **Hand & cards:** card faces are already the strongest asset (Phase 11) — unchanged, except the
  playable-glow ring now uses the element glow of the card's own colour (already suit-tinted; keep).

### 3.2 Home
- Neutral aurora background + motes; wordmark suit symbols each glow in their own element colour.
- Menu buttons: primary stays accent-filled; secondary buttons become glass (not outline).
  *AC: reads as a game title screen, not a settings form; all identifiers intact.*

### 3.3 New game flow
- Section groups sit on glass cards; `NeonSegmented` track becomes glass.
  *AC: centred column layout (shipped fix) unchanged.*

### 3.4 Pause menu / Round end
- Panels → glass; round/game win overlay gains a team-colour glow wash behind the existing content.
  *AC: loss desaturation behaviour unchanged.*

### 3.5 Decision sheets (colour / target / team-pass)
- Neutral aurora background; colour tiles keep element gradients + glow (already close); target
  rows → glass.

### 3.6 iPad (second pass, after iPhone is verified)
- Same tokens apply automatically; verify aurora/motes scale on the 13" canvas.
- **iPad home density fix** (flagged in the last critique): menu buttons form a 2-column grid
  within the centred column so the screen stops reading as a stretched phone.
  *AC: table block, settings/rules reading columns, new-game centring — all shipped fixes intact.*

## 4. Non-goals (must not change)
- Engine vocabulary: `crimson/cobalt/jade/amber` case names and raw values.
- Zone layout mechanics shipped through `ea7d8b5` (fan clamping, centred blocks, timer thresholds).
- Accessibility identifiers, labels, VoiceOver phrasing (except the reworded pill's *visible* text).
- No new dependencies, no assets requiring network, no `AVFoundation`/etc. (enterprise constraints).
- Colour-blind patterns and `displayName` sourcing.

## 5. Verification gate (per form factor)
1. `bash scripts/quality_light.sh` passes.
2. `xcodebuild build` for the target simulator passes.
3. App installed + launched on simulator; screenshots of home, new-game, table (≥2 element states),
   and one sheet captured to `docs/phase-12-redesign/screenshots/`.
4. Design critique of the screenshots against §3 acceptance criteria: no major findings.
