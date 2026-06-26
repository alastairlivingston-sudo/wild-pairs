# Wild Pairs — Design System

> *Canonical sources: this document is authoritative for visual tokens, colour names, animation durations, and typography. For data models, `technical-architecture.md` §Model Reference is canonical. For game rules, `game-rules.md`. Where any other document disagrees with this document on visual tokens, this document wins.*

**Version:** 1.0  
**Status:** Draft  
**Audience:** iOS engineers, designers  
**Platform:** iOS 17+, SwiftUI, Universal (iPhone + iPad)  
**Last updated:** 2026-06-21

---

## 1. App Name

### Working title: Wild Pairs

**Wild Pairs** is the working title and is used throughout all documentation, code, and assets until a final name is selected.

### Five original alternatives

| Name | Reasoning |
|---|---|
| **Chromatic** | Evokes colour and precision. Short, memorable, distinctive. Works well as an App Store title. No obvious trademark conflict. Risk: may feel more design-tool than card-game. |
| **Paired Up** | Directly communicates the 2v2 team mechanic. Friendly, approachable tone. Distinct from existing card game names. Risk: slightly generic. |
| **Colour Clash** | Communicates the colour-matching mechanic and the competitive element. Energetic. Slightly more aggressive in tone — works for the competitive angle. Risk: "clash" implies conflict which understates the teamwork. |
| **Fourplay** | Wordplay on four-player and "fair play." Witty, memorable. Risk: double-meaning may cause App Store content flags. Use with caution. |
| **Spectrum Run** | Evokes colour (spectrum) and the race to empty your hand (run). Original compound with no obvious conflict. Works as a distinctive App Store name. Risk: "Run" may suggest a running/fitness app to some users. |

**Recommendation: Chromatic** — distinctive, memorable, strong App Store search value, evokes colour without literal wordplay, no trademark conflict found at time of writing. Verify with formal trademark search before committing.

Until a name decision is made, use **Wild Pairs** throughout.

---

## 2. Tone of Voice

### Principles

**Clear and direct.** Action prompts tell the player exactly what to do. No passive constructions, no hedging language.

- Do: `"Play a Cobalt card, a 7, or a wild card."`
- Don't: `"Please select an eligible card from your hand to play."`

**Friendly, never condescending.** The app assumes the player is intelligent. It explains rules when needed but does not over-explain things the player already knows.

- Do: `"That card doesn't match — needs Jade, a 5, or a wild card."`
- Don't: `"Invalid selection. The rules require colour or number matching."`

**Celebratory on wins.** Win moments are enthusiastic but proportionate. Reserve the biggest celebrations for the biggest moments.

- Round win: `"Your team wins this round!"`
- Game win: `"Your team wins the game!"`
- Close win: `"What a finish! Your team wins!"`

**Sympathetic on losses.** Losses are never mocked, never shamed. The app is on the player's side.

- Round loss: `"Opponents win this round."`
- Close loss: `"So close! Opponents edge it."`
- Heavy loss: `"Better luck next round."`

**Never mechanical or robotic.** The app has a personality — warm, game-night-host energy. Short, human sentences. Contractions are fine (`"you're"`, `"let's"`, `"don't"`).

### Vocabulary reference

| Use this | Not this |
|---|---|
| "Play a card" | "Select a card to play" |
| "Draw Card" | "Draw" / "Pick up" |
| "Solo!" | "UNO" (never — legally distinct) |
| "Your turn is skipped" | "Skip applied" |
| "That card doesn't match" | "Invalid move" |
| "Cobalt" | "Blue" |
| "Crimson" | "Red" |
| "Jade" | "Green" |
| "Amber" | "Yellow" |
| "Partner" | "Ally" / "Teammate" |
| "Left Opponent" / "Right Opponent" | "AI 1" / "AI 2" |
| "Round ends" | "Game over" (unless it genuinely is) |
| "New Game" | "Restart" / "Reset" |
| "Continue Game" | "Resume" (on home; "Resume" is fine within pause menu) |

---

## 3. Typography Scale

Wild Pairs uses **SF Pro** exclusively — the system font for iOS and iPadOS. No custom fonts are required. SF Pro is pre-installed, requires no licence, no bundling, and scales automatically with Dynamic Type.

Use SwiftUI font system styles, not hardcoded point sizes, so all text scales with Dynamic Type automatically.

| Token | SwiftUI Style | Approx Size | Weight | Usage |
|---|---|---|---|---|
| `display` | `.largeTitle` | 34pt | Bold | App name on home, round win headline |
| `title1` | `.title` | 28pt | Semibold | Screen titles ("Choose a mode") |
| `title2` | `.title2` | 22pt | Semibold | Section headers, card glossary titles |
| `title3` | `.title3` | 20pt | Semibold | Card action names in glossary |
| `body` | `.body` | 17pt | Regular | Body text, action prompts, event log |
| `callout` | `.callout` | 16pt | Regular | Secondary info, card count badges |
| `subheadline` | `.subheadline` | 15pt | Semibold | Card numbers, mode labels on table |
| `footnote` | `.footnote` | 13pt | Regular | Fine print, statistics sub-labels |
| `caption` | `.caption` | 12pt | Regular | Small card text, pip indicators |
| `caption2` | `.caption2` | 11pt | Regular | Legal fine print, "local only" note |

### Dynamic Type guidelines

- All text elements use `.font(.system(...))` with explicit relative size, or map directly to system text styles.
- Never hard-code point sizes for text that must be readable at all accessibility sizes.
- Cards use `.subheadline` for numbers (scales); large card mode increases this to `.title3`.
- Cards may use `.minimumScaleFactor(0.75)` to prevent layout breakage at very large Dynamic Type sizes, but never below 0.7.
- At AX3 and above: large card mode is activated automatically (card dimensions increase as per card dimensions table).
- Test at xSmall (verify nothing is unreadably tiny) and AX5 (verify nothing clips or overflows).

---

## 4. Spacing Scale

Spacing values are expressed in SwiftUI point units. Use these tokens consistently.

| Token | Value | SwiftUI Usage | Usage |
|---|---|---|---|
| `space1` | 4pt | `.padding(4)` | Icon padding, hairline gaps, badge insets |
| `space2` | 8pt | `.padding(8)` | Component internal padding (button label to edge) |
| `space3` | 12pt | `.padding(12)` | Component-to-component spacing in dense layouts |
| `space4` | 16pt | `.padding(16)` | Section margins on iPhone, standard component padding |
| `space5` | 24pt | `.padding(24)` | Large section gaps, between-group spacing |
| `space6` | 32pt | `.padding(32)` | Screen-level margins on iPad, hero section margins |
| `space8` | 48pt | `.padding(48)` | Hero spacing on iPad, large whitespace |

### Application rules

- iPhone content margins: `space4` (16pt) on left and right.
- iPad content margins: `space6` (32pt) on left and right. Content constrained to max-width where appropriate (e.g., form content: 600pt max; narrative content: 720pt max).
- Between form rows: `space3` (12pt).
- Between major sections: `space5` (24pt).
- Cards in hand: horizontal gap `space2` (8pt) between cards; `space3` (12pt) between hand area and adjacent UI.
- Action prompt from hand: `space4` (16pt) minimum gap.
- Bottom safe area: always respected; never place interactive elements in the home indicator zone.

---

## 5. Corner Radius Scale

| Token | Value | SwiftUI | Usage |
|---|---|---|---|
| `radius1` | 4pt | `.cornerRadius(4)` | Badges, tags, count chips |
| `radius2` | 8pt | `.cornerRadius(8)` | Buttons, small interactive panels |
| `radius3` | 12pt | `.cornerRadius(12)` | Cards, event log panels, picker rows |
| `radius4` | 16pt | `.cornerRadius(16)` | Modals, bottom sheets, colour picker |
| `radiusFull` | 9999pt | `.clipShape(Capsule())` | Pills, circular elements, colour indicator chip |

### Application rules

- Game cards: `radius3` (12pt).
- Action buttons: `radius2` (8pt) for filled buttons; `radius2` for outlined buttons.
- Colour swatches in picker: `radius3` (12pt).
- Modal overlays (pause menu, round end): `radius4` (16pt) on top corners only (sheet presentation).
- Player zone containers: `radius3` (12pt) with a thin border.
- Badges (Solo!, Out!, card count): `radius1` (4pt) or `radiusFull` for circular count badges.

---

## 6. Card Dimensions

Cards maintain a 2:3 aspect ratio at all sizes.

| Context | Width | Height | Ratio | Notes |
|---|---|---|---|---|
| iPhone compact hand | 60pt | 90pt | 2:3 | Default hand card size on iPhone |
| iPhone selected/enlarged | 80pt | 120pt | 2:3 | When a card is tapped/selected |
| iPhone large card mode | 80pt | 120pt | 2:3 | User setting; same as selected size |
| iPad regular hand | 80pt | 120pt | 2:3 | Default hand card size on iPad |
| iPad selected/enlarged | 100pt | 150pt | 2:3 | Floating preview on tap |
| iPad large card mode | 100pt | 150pt | 2:3 | User setting |
| Rules / help display | 100pt | 150pt | 2:3 | Card illustrations in rules screen |
| AI player zone (card backs) | 44pt | 66pt | 2:3 | Smaller cards in opponent/partner zones |

### Card structure

Each card is a rounded rectangle (`radius3`) with:

```
┌─────────────────┐
│ [♦] [colour]    │  ← Top-left: suit symbol; top-right: number/action abbr.
│                 │
│                 │
│    [LARGE]      │  ← Centre: large number (0–9) or action symbol
│    [SYMBOL]     │
│                 │
│                 │
│ [number] [♦]    │  ← Bottom: mirrored from top (rotated 180°)
└─────────────────┘
```

- **Background:** Game colour fill (Crimson, Cobalt, Jade, Amber) for coloured cards; white/near-white for wild cards.
- **Number:** Large, bold, centred — `.display` font style.
- **Suit symbol:** Appears in all four corners (small) and can appear large behind the number as a watermark at reduced opacity (optional decorative element).
- **Action name:** Shown as abbreviated text at the top and bottom corners (e.g., "SKIP", "REV", "D2", "D4").
- **Wild card background:** White card face with the Wild Pairs wordmark or a distinctive multi-colour design (not rainbow — use a geometric pattern incorporating all four game colours).
- **Colour name label:** Always shown in colour-blind mode; can be optionally shown in normal mode via settings.

---

## 7. Colour Palette

### Game colours

These four colours define the game's visual identity. They are original, legally distinct from competitor products, and chosen to pass WCAG AA contrast requirements.

| Game Colour | Token | Hex (light mode) | Symbol | Colour-blind pattern |
|---|---|---|---|---|
| Crimson | `color.crimson` | `#C0392B` | Flame (🔥) | Diagonal hatching, 45° |
| Cobalt | `color.cobalt` | `#2471A3` | Wave (〰) | Horizontal lines |
| Jade | `color.jade` | `#1E8449` | Leaf (🍃) | Vertical lines |
| Amber | `color.amber` | `#D4AC0D` | Sun (☀) | Dots / circles |

**Dark mode adjustments for game colours:**
Game colours represent a physical card — they should remain vivid against both light and dark backgrounds. Lighten each game colour by 10% in dark mode to maintain contrast against dark backgrounds.

| Game Colour | Hex (dark mode) |
|---|---|
| Crimson | `#E74C3C` |
| Cobalt | `#2E86C1` |
| Jade | `#27AE60` |
| Amber | `#F1C40F` |

**Contrast verification (light mode, game colours on white `#FFFFFF`):**
- Crimson `#C0392B` on white: ~5.0:1 ✓ WCAG AA
- Cobalt `#2471A3` on white: ~5.1:1 ✓ WCAG AA
- Jade `#1E8449` on white: ~5.3:1 ✓ WCAG AA
- Amber `#D4AC0D` on white: ~2.8:1 ✗ — Amber requires white or near-white text on card backgrounds, not dark text. Use `.white` for text on Amber cards. Verify contrast of white on Amber: #FFFFFF on #D4AC0D = ~4.6:1 ✓

### UI colours

Use system semantic colours for all chrome/UI elements. This ensures automatic correct behaviour in light mode, dark mode, high-contrast mode, and across iOS versions.

| Token | SwiftUI Color | Light appearance | Dark appearance | Usage |
|---|---|---|---|---|
| `color.background` | `.background` (`.systemBackground`) | White | Near-black | App background |
| `color.surface` | `.secondarySystemBackground` | Off-white | Dark grey | Cards, panels, form rows |
| `color.primary` | `.primary` (`.label`) | Black | White | Primary text |
| `color.secondary` | `.secondary` (`.secondaryLabel`) | Medium grey | Medium grey | Secondary text, captions |
| `color.accent` | `.indigo` (system) | Indigo | Indigo | Interactive elements, selected states, buttons |
| `color.success` | `.green` (system) | Green | Green | Playable card indicator, win states |
| `color.warning` | `.orange` (system) | Orange | Orange | Solo! alerts, nearly out warning |
| `color.error` | `.red` (system) | Red | Red | Illegal move shake, destructive actions |
| `color.tableSurface` | Custom | Warm off-white `#F5F0E8` | Dark slate `#1C2526` | Game table background (not system colour) |

**Table surface custom colours (game table background):**
- Light mode: `#F5F0E8` — warm off-white, evokes felt/paper table surface
- Dark mode: `#1C2526` — dark slate, evokes a darker felt surface
- These are the only non-system UI colours used outside the four game colours.

### Felt palette (Phase 9 — premium dark felt mood)

Phase 9 replaced the flat table-surface colour above with a textured felt surface used
behind every screen (`TableBackground`, not just the game table), dark-first per the Phase 9
design direction:

| Token | Hex | Usage |
|---|---|---|
| `felt.baseDark` | `#0B2C26` | Dark-mode felt base (primary) |
| `felt.baseDarkHighlight` | `#163F35` | Dark-mode radial highlight toward screen centre |
| `felt.baseLight` | `#1F5C4B` | Light-mode felt base |
| `felt.baseLightHighlight` | `#2C7A63` | Light-mode radial highlight |
| `felt.vignette` | `black @ 55%` | Edge vignette (radial, outer ring) |
| `felt.gold` | `#D9B872` | Warm accent — replaces system indigo as `Theme.Palette.accent`; used for borders, primary buttons, suit-symbol watermarks |
| `felt.cream` | `#F3ECD9` | Warm light text/wordmark colour on felt |

`TableBackground` composes these as: solid felt base → radial highlight (centre-out) → a
faint diagonal weave texture at 5% opacity → a radial vignette (clear centre, dark edges).
The game table view (and all menu screens) lock `.preferredColorScheme(.dark)` so text/icon
contrast tokens stay deterministic regardless of the device's system appearance setting —
this is a deliberate "dark-first" choice, not a light-mode regression.

---

## 8. Colour-blind Safe Palette

### Default design (colour-blind safe without the toggle)

The base design is colour-blind safe by default:
- Every card always shows its suit symbol (Flame, Wave, Leaf, Sun) prominently.
- The current colour indicator always shows the colour name as text alongside the colour chip.
- No game-critical information is conveyed only by colour in the default layout.

### Colour-blind mode (toggle in settings)

When enabled, adds additional redundancy:

| Enhancement | Normal mode | Colour-blind mode |
|---|---|---|
| Card colour name | Not shown (optional in settings) | Always shown in all-caps (e.g., "CRIMSON") |
| Suit symbol size | Large, centred | Even larger, always prominent |
| Pattern fill | Off | Optional overlay (diagonal lines, dots, etc.) |
| Colour indicator | Colour chip + symbol | Colour chip + symbol + text name |
| Event log colours | Colour chip | Colour chip + text name |
| Tooltip colour references | Colour chip | Colour chip + text name |

### Deuteranopia (red-green) considerations

Crimson (red) and Jade (green) are the most problematic pair for deuteranopic players. Mitigation:
- Crimson symbol is Flame (diagonal organic shape); Jade symbol is Leaf (distinct leaf shape). These are visually distinct even without colour.
- Colour-blind mode adds pattern fills: Crimson = diagonal hatching (45°), Jade = vertical lines. These are never the same pattern.
- Colour names always present in colour-blind mode.
- Amber (yellow) is distinct from both red and green even with deuteranopia.
- Cobalt (blue) is fully distinct under all common colour blindness types.

### Pattern fill specifications

| Game colour | Pattern | SVG/SwiftUI approach |
|---|---|---|
| Crimson | Diagonal hatching 45°, 4pt spacing | `Path` with diagonal lines, clipped to card shape |
| Cobalt | Horizontal lines, 4pt spacing | `Path` with horizontal lines |
| Jade | Vertical lines, 4pt spacing | `Path` with vertical lines |
| Amber | Dot grid, 6pt spacing | `Circle` shapes at grid positions |

Pattern fills are rendered at 30% opacity over the solid colour background, so they add texture without obscuring the card content.

---

## 9. Button Styles

### Style definitions

| Style | Token | Use | Height | Appearance | SwiftUI |
|---|---|---|---|---|---|
| Primary | `.primary` | Main actions (Play, Start, Continue, Next) | 50pt | Filled, `color.accent`, radius2, white text | `.buttonStyle(.borderedProminent)` |
| Secondary | `.secondary` | Supporting actions (Draw Card, Cancel, Back) | 50pt | Outlined, `color.accent`, radius2, accent text | `.buttonStyle(.bordered)` with `.tint(.accent)` |
| Ghost | `.ghost` | Tertiary (Skip tutorial, Rules link) | 44pt | Text only, `color.accent` | `.buttonStyle(.plain)` with accent tint |
| Destructive | `.destructive` | Danger (Reset data, End game) | 50pt | Filled, `color.error`, radius2, white text | `.buttonStyle(.borderedProminent)` with `.tint(.red)` |
| Icon | `.icon` | Icon-only (Pause, Settings gear) | 44×44pt | Icon only, no background, `color.accent` | `.buttonStyle(.plain)` |

### Phase 9 implementation (code: `PrimaryButtonStyle` / `SecondaryButtonStyle` / `GhostButtonStyle` / `DestructiveButtonStyle`)

The "SwiftUI" column above described stock modifiers (`.borderedProminent` etc.); Phase 9
replaced these with dedicated `ButtonStyle` types in `Theme.swift` so every screen renders
consistently against the dark felt background instead of relying on the system accent colour:

| Style | Background | Foreground | Min height |
|---|---|---|---|
| `.wpPrimary` | `Theme.Palette.accent` (felt gold) fill | Dark felt text | 50pt |
| `.wpSecondary` | Transparent, gold 1.5pt stroke | `Theme.Palette.accent` | 50pt |
| `.wpGhost` | None | `Theme.Palette.accent` | 44pt |
| `.wpDestructive` | `Theme.Palette.error` fill | White | 50pt |

All four scale their pressed state by reducing fill/stroke opacity (`PrimaryButtonStyle` also
applies a slight `scaleEffect`), and all meet the 44×44pt minimum tap target from this section.

### Button minimum tap targets

- All buttons minimum **44×44pt** touch target.
- Primary buttons preferred **50pt height**.
- Full-width primary buttons on iPhone preferred.
- On iPad: buttons constrained to a comfortable width (not stretched edge-to-edge); 280pt max for standalone buttons.

### Disabled state

- All button styles at 40% opacity when disabled.
- Do not simply remove buttons when unavailable — disable them (with accessibility trait `.isEnabled = false`) so VoiceOver can inform the user why the button is not active.

---

## 10. Icon Style

### SF Symbols (primary)

Use SF Symbols throughout the app for all chrome/navigation icons. SF Symbols scale with Dynamic Type, match system conventions, and require no licence.

| Icon use | SF Symbol name |
|---|---|
| Pause | `pause.fill` |
| Resume / Play | `play.fill` |
| Settings | `gearshape.fill` |
| Rules / Help | `questionmark.circle.fill` |
| Statistics | `chart.bar.fill` |
| Back | `chevron.left` |
| Close | `xmark` |
| Card draw | `rectangle.stack.fill` |
| Solo! badge | `exclamationmark.circle.fill` |
| Out! badge | `checkmark.circle.fill` |
| Direction arrow | `arrow.clockwise` / `arrow.counterclockwise` |
| Partner link | `link` |
| Warning | `exclamationmark.triangle.fill` |
| Destructive action | `trash.fill` |

Always use `Image(systemName:)` and set `.symbolRenderingMode(.hierarchical)` or `.monochrome` as appropriate.

### Custom suit symbols (Flame, Wave, Leaf, Sun)

These four symbols appear on every card and in all colour indicators. They must be custom because SF Symbols does not have exact equivalents that match the game's visual identity.

**Implementation approach:**
- Draw each symbol as a SwiftUI `Shape` using `Path` (not as image assets, so they scale perfectly at all sizes).
- Each symbol is designed on a 24×24pt grid at 1x, scalable to any size.
- Symbol weight visually matches SF Symbol "regular" weight at equivalent sizes.
- Symbols are used only in foreground colour (no fills required — they are outlines/silhouettes).

**Phase 9 implementation:** `SuitSymbolShape` (a `Shape` conformance, switching on `CardColour`
to draw the flame/wave/leaf/sun `Path`s described below) and `SuitSymbol` (a `View` wrapper
applying a `StrokeStyle` with rounded caps/joins, default `lineWidth: 1.6`). Used in three
places per card: the corner index (small), a large faint (16% opacity) centre watermark behind
the number/action glyph, and the `CardBackView`/colour-indicator/colour-picker chips. This
replaced the SF Symbols placeholders (`flame.fill`, `water.waves`, `leaf.fill`, `sun.max.fill`)
that `CardColour.symbolName` still exposes for VoiceOver/legacy reference only — visuals never
use them anymore.

| Symbol | Shape description |
|---|---|
| Flame (Crimson) | Teardrop flame shape, slightly tilted, with a small inner flame curl |
| Wave (Cobalt) | Two overlapping sine-wave arcs, flowing left to right |
| Leaf (Jade) | Oval leaf with a central vein line, slightly pointed at the tip |
| Sun (Amber) | Circle with 8 short radiating lines (rays) |

---

## 11. Shadow / Elevation

Shadows in Wild Pairs are subtle. They suggest depth and interactivity without creating a heavy visual hierarchy.

| Level | Token | Usage | Shadow spec |
|---|---|---|---|
| Flat | `elevation0` | Cards at rest in hand (not selected) | None |
| Resting | `elevation1` | Cards (default), panels | `shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)` |
| Active | `elevation2` | Selected card, active interactive element | `shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)` |
| Floating | `elevation3` | Modals, bottom sheets, popovers | `shadow(color: .black.opacity(0.20), radius: 16, x: 0, y: 4)` |

### Rules

- Cards in the AI player zones: `elevation0` (no shadow — they are not interactive).
- Human hand cards (not selected): `elevation1`.
- Human hand card (selected): `elevation2`.
- Pause menu overlay, colour picker: `elevation3`.
- Button shadows: none (relying on colour and border for depth, not shadow).
- Do not stack multiple shadow modifiers on the same element — use one elevation level per element.

### Phase 9 update — dark-felt elevation values

The shadow opacities above were tuned for a light/near-white table surface. Against the
Phase 9 dark felt background, those values are nearly invisible, so `Theme.Elevation` uses
stronger dark-mode-appropriate values instead (defined in code as `Theme.Elevation.flat` /
`.resting` / `.active` / `.floating`):

| Level | Token | Shadow spec |
|---|---|---|
| Flat | `elevation0` | None |
| Resting | `elevation1` | `shadow(color: .black.opacity(0.28), radius: 4, x: 0, y: 2)` |
| Active | `elevation2` | `shadow(color: .black.opacity(0.38), radius: 10, x: 0, y: 4)` |
| Floating | `elevation3` | `shadow(color: .black.opacity(0.45), radius: 18, x: 0, y: 6)` |

The usage rules above (which level applies to which element) are unchanged — only the
opacity/radius/y-offset values were recalibrated for the dark surface.

---

## 12. Animation Durations

All durations are defined as named constants in a shared `AnimationTokens` enum (or equivalent).

| Token | Duration | Easing | Fast mode | Reduced motion | Usage |
|---|---|---|---|---|---|
| `instant` | 0s | n/a | 0s | 0s | Reduced motion fallback; forced immediate transitions |
| `microFast` | 0.1s | `easeOut` | 0.05s | 0s | AI thinking (fast mode) |
| `fast` | 0.15s | `easeOut` | 0.08s | 0s | Card play (fast mode), quick transitions |
| `normal` | 0.3s | `spring(response: 0.3, dampingFraction: 0.7)` | 0.15s | 0s | Card play (normal mode), colour change |
| `moderate` | 0.5s | `easeInOut` | 0.2s | 0s | Solo! badge pop, skip/reverse animation |
| `slow` | 0.6s | `easeInOut` | 0.2s | 0s | Deal animation per card, celebration |
| `celebrationTotal` | 1.5s | n/a | 0.5s | 0s | Full win celebration sequence |
| `aiThinkEasy` | 0.3s | n/a | 0.1s | 0s | Easy AI thinking delay |
| `aiThinkMedium` | 0.6s | n/a | 0.1s | 0s | Medium AI thinking delay |
| `aiThinkHard` | 0.9s | n/a | 0.1s | 0s | Hard AI thinking delay |
| `aiThinkExpert` | 1.2s | n/a | 0.1s | 0s | Expert AI thinking delay |
| `tooltipDismiss` | 2.5s | n/a | 2.5s | 2.5s | Illegal-move tooltip hold duration |
| `toastDismiss` | 3.0s | n/a | 3.0s | 3.0s | Mode summary toast duration |

### Phase 9 motion tokens (code: `Theme.Motion`)

In addition to the named durations above, `Theme.Motion` defines reusable `Animation` values
used directly by views/view models (rather than every call site hand-rolling a spring):

| Token | Definition | Usage |
|---|---|---|
| `cardPlay` | `.spring(response: 0.3, dampingFraction: 0.7)` | Card lift/playability change |
| `fast` | `.easeOut(duration: 0.15)` | Shake-reject, fast-mode transitions |
| `moderate` | `.easeInOut(duration: 0.5)` | Solo! badge, skip/reverse |
| `deal` | `.easeInOut(duration: 0.6)` | Deal-in sequence |
| `playArc` | `.spring(response: 0.35, dampingFraction: 0.75)` | Card hand→discard motion |
| `draw` | `.spring(response: 0.4, dampingFraction: 0.8)` | Card deck→hand motion |
| `turnPass` | `.easeInOut(duration: 0.3)` | General state-change animation driving `GameViewModel.publishViewState()` |
| `celebration` | `.spring(response: 0.6, dampingFraction: 0.65)` | Round/game win |
| `micro` | `.easeOut(duration: 0.1)` | Smallest UI feedback (selection ticks) |
| `dealStagger` | `0.06` (seconds, not an `Animation`) | Per-card delay multiplier when dealing a hand |

`GameViewModel.publishViewState()` wraps every engine-state republish in `Theme.Motion.turnPass`
(or `.fast` in Fast mode), unless Reduced Motion or `AnimationSpeed.off` is active, in which case
the new state is published with no animation at all. `HandView` and `PlayerZoneView` card fans
add `.transition(.scale.combined(with: .opacity))` (or `.identity` under Reduced Motion) so cards
animate in/out of the hand and seats instead of snapping.

### Fast mode

Fast mode (Settings → Animation speed → Fast) multiplies all animation durations by 0.5 (capped at minimum useful durations). AI thinking delays reduce to `microFast` (0.1s for all difficulty levels).

### Animation constraints

- No animation may block user input for more than 0.5s.
- The Pause button is always tappable, even during animations.
- Chain animations queue; they do not overlap in ways that cause visual confusion.
- Deal animation is the longest blocking sequence; it blocks input for the full duration but includes a "Skip deal" gesture (tap anywhere during deal to complete it instantly).

---

## 13. Haptic Patterns

All haptics use `UIImpactFeedbackGenerator`, `UINotificationFeedbackGenerator`, and `UISelectionFeedbackGenerator` as appropriate. Haptics are wrapped in a `HapticEngine` singleton that checks whether the user has enabled haptics in settings before firing.

| Token | Trigger | Generator | Style | Notes |
|---|---|---|---|---|
| `cardSelect` | Human taps a card to select it | `UIImpactFeedbackGenerator` | `.light` | Fires on every card tap, playable or not |
| `cardPlay` | Card successfully plays (leaves hand) | `UIImpactFeedbackGenerator` | `.medium` | Fires as card begins arc animation |
| `illegalCard` | Human taps an unplayable card | `UINotificationFeedbackGenerator` | `.error` | Fires simultaneously with shake animation |
| `colourSelected` | Colour chosen in colour picker | `UIImpactFeedbackGenerator` | `.light` | Confirmation of choice |
| `targetChosen` | Target player selected | `UIImpactFeedbackGenerator` | `.medium` | Confirmation of choice |
| `soloCall` | Solo! called (human) | `UIImpactFeedbackGenerator` | `.heavy` | Major moment |
| `roundWin` | Human team wins a round | `UINotificationFeedbackGenerator` | `.success` | Celebration |
| `roundLoss` | Opponent team wins a round | `UINotificationFeedbackGenerator` | `.warning` | Sympathetic, not punishing |
| `drawPenalty` | Human receives draw penalty | `UINotificationFeedbackGenerator` | `.warning` | Fires once for the penalty event |
| `cardDrawn` | Single card drawn from deck | `UIImpactFeedbackGenerator` | `.light` | Fires as card enters hand |

### Rules

- All haptics check `HapticEngine.isEnabled` (user setting) before firing.
- Haptics also check `UIAccessibility.isSwitchControlRunning` — if Switch Control is active, suppress haptics to avoid accidental presses.
- No game-critical information is conveyed only through haptics. Every haptic event has a corresponding visual or VoiceOver equivalent.
- Never use haptics inside a loop or tight repeat that would create a buzzing sensation. Draw penalties fire one haptic for the event, not one per card drawn.

---

## 14. Dark Mode

### Strategy

- All app chrome uses system semantic colours (`.background`, `.label`, etc.) which adapt automatically to dark mode.
- Game colours (Crimson, Cobalt, Jade, Amber) use slightly lightened values in dark mode (see §7) to maintain contrast against dark backgrounds.
- The game table background uses custom colours (`#F5F0E8` light / `#1C2526` dark) defined as named `Color` assets in the asset catalogue with separate light and dark values.
- Card faces: colour cards retain their saturated game colour in both modes. Wild cards use `.systemBackground` as their face colour, adapting automatically.
- Text on game-coloured cards: use `.white` for Crimson, Cobalt, and Jade cards (contrast ✓). Use `.white` for Amber cards (see §7 contrast note). Do not invert text colour in dark mode for game cards — the card face colour changes slightly; text always stays white.

### Testing checklist for dark mode

- [ ] Home screen: all text legible; no bleed-through of light mode colours.
- [ ] Game table: table surface in dark mode feels like a dark felt surface, not a generic dark screen.
- [ ] All four card colours visible and distinct against the dark table surface.
- [ ] Colour indicator chip readable against dark backgrounds.
- [ ] Event log (iPad): text legible in dark mode.
- [ ] Pause menu overlay: blur effect works correctly in both modes.
- [ ] Round end overlay: legible in both modes.
- [ ] Settings and Statistics: all rows legible.

---

## 15. Device-specific Layout Decisions

### Phase 9 — portrait-only lock

Phase 9 locked the app to **portrait only** on both iPhone and iPad (`Info.plist
UISupportedInterfaceOrientations` / `~ipad`, both reduced to `UIInterfaceOrientationPortrait`).
The landscape guidance below (iPhone landscape, iPad landscape side panel) is **historical and
superseded** — there is no landscape code path in `GameTableView` or anywhere else in
`WildPairsApp` as of Phase 9. The portrait game-table layout is a fixed `GeometryReader` grid:
partner zone top-centre (full width), then a row of (left opponent, table centre, right
opponent) each given an explicit width fraction of the available screen width — never a
horizontal `ScrollView`, so seats cannot clip off-screen at any Dynamic Type size. Hand and
seat card fans use width-aware overlap (see `HandView`/`PlayerZoneView`) to fit any device
width from iPhone SE to iPad Pro 13" without scrolling, falling back to a scrollable row only
at extreme card counts.

### Size class strategy

| Horizontal size class | Vertical size class | Device context | Layout used |
|---|---|---|---|
| Compact | Regular | iPhone portrait (any size) | iPhone compact layout |
| Compact | Compact | iPhone landscape | iPhone compact landscape (supported, not primary) |
| Regular | Regular | iPad portrait and landscape | iPad regular layout |
| Compact | Regular | iPad Split View narrow | Compact fallback (mirrors iPhone) |

Wild Pairs uses `@Environment(\.horizontalSizeClass)` and `@Environment(\.verticalSizeClass)` to switch between layouts. The game table is fully functional at any size class.

### Per-device guidance

| Device | Portrait strategy | Landscape strategy | Notes |
|---|---|---|---|
| iPhone SE (4.7") | All controls in bottom 60%; partner/opponent zones minimal | Supported; layout tightens; no content removed | Minimum supported iPhone size. Test at every milestone. |
| iPhone standard (6.1") | Baseline layout | Supported | Reference design device. |
| iPhone Pro Max (6.7") | More card visibility; slightly wider hand fan | Supported | Enjoy the extra space — don't just stretch. |
| iPad mini (8.3") | Regular layout (smaller) | Full regular layout | Treat as compact-regular hybrid initially. |
| iPad Air 11" | Full regular layout | Full with side panel | Side panel available in landscape. |
| iPad Pro 13" | Full regular layout | Full with side panel + wider | Maximum canvas; most spacious layout. |
| iPad Split View narrow | Compact fallback | n/a | Must remain fully playable. No content removed. |
| Stage Manager | Any width | n/a | `GeometryReader` adaptive; all widths 320pt–1024pt supported. |

### iPhone landscape

iPhone landscape is supported but not the primary design. The game table adapts:
- Hand area shrinks slightly (cards slightly smaller or fewer visible).
- Partner zone moves to right side or reduces to a narrow strip.
- Opponent zones compress to count-only display.
- All controls remain reachable.
- No features are disabled in landscape on iPhone.

### iPad portrait vs landscape

iPad portrait is a first-class layout (not just rotated iPhone):
- Game table uses more vertical space.
- Side panel (event log) is hidden in portrait on smaller iPads; visible in landscape.
- On iPad Pro 13" portrait: side panel can appear.

iPad landscape is the widest layout:
- Side panel is always visible.
- Cards are wider in the hand.
- More of the table is visible simultaneously.

### GeometryReader adaptive principles

- Use `GeometryReader` to read available width and height.
- Breakpoints: < 400pt wide = compact; 400–768pt = intermediate; > 768pt = regular.
- Never use fixed pixel coordinates for game table elements — all positions are fractions of the available canvas.
- All player zones scale proportionally with available space.
- Minimum usable game table: 320×480pt (iPhone SE landscape as absolute minimum).
