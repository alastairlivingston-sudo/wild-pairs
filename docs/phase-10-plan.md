# Phase 10 — UX Perfection (Neon Arcade visual overhaul)

> Goal: take the playable Universal app from "functional but visually weak" to App-Store-quality.
> This phase is **purely presentational** — no game-rules, engine, AI, or persistence changes.
> The `WildPairsCore` package and all reducer/effect logic are out of scope and must not change.

## 1. Problem statement (from review of the current build)
1. **Card faces look low-quality** — flat, generic, weak hierarchy.
2. **Cards run off-screen** — hand and seat cards clip at the device edges; you can't see all of your own or opponents' cards.
3. **Wasted empty space** — large dead zones on the table; loose, ungrouped elements.
4. **Score header wraps to two rows** — `Round / Team A / Team B` breaks the top bar.
5. **Hand + opponent presentation is unclear** — overlapping fans of identical card backs read as clutter.

## 2. Locked design direction
**Neon Arcade** — dark arcade canvas, suit-coloured glow on cards, teal (`#36E0C8`) accent.
Reference mockups (open in a browser):
- `docs/phase-10-design/options.html` — the 10 explored directions (archive).
- `docs/phase-10-design/neon-refinements.html` — the 6 table variations (archive).
- `docs/phase-10-design/neon-final.html` — **the canonical spec**: all 5 screens, locked composition.

### Locked composition
| System | Choice | Why |
|---|---|---|
| Theme | Neon Arcade | High-energy, premium, strong colour-blind contrast on dark |
| Score header | **Center pill** — `R2` · `●A 0 · ●B 640` · pause, single row | Kills the two-row wrap; compact; team colour dots |
| Your hand | **Straight row** — flat overlap, all 7 visible, playable card lifts + glows | Max legibility, nothing clips |
| Opponents | **Avatar + count** — circle (L/R) + count badge, thinking-state glow | Removes repetitive back-fans; instant read |

## 3. Design tokens (to add to `WildPairsApp/Theme/Theme.swift`)
Replace the felt palette mood with a Neon palette (keep the token *structure*; swap values).
- Background field: radial `#1A1242 → #0D0820 → #05030F`.
- Accent: `#36E0C8` (teal). `onAccent` text: `#04130F`.
- Surface (panels): `white @ 6%`. Borders: `white @ 8–12%`.
- Ink: `#EEF0FF`. Muted: `#9B9AC6`.
- Suit faces (gradient `[highlight, base]`), light/dark unified bright variants:
  - crimson `#FF6B8E → #FF2E63`, cobalt `#5FA8FF → #2E7BFF`, jade `#5CFFB4 → #16E08A`, amber `#FFD45E → #FFB01F` (amber uses dark ink `#3A2A02`).
  - wild face: `#3A1A6A → #1A0C3A`.
- Team colours: A = jade `#16E08A`, B = crimson `#FF2E63`.
- Card glow: `0 0 14px <suitHighlight>@40%`; playable ring: 3px teal + `0 0 20px teal`.
- **Reduced visual effects** (`AppSettings.reducedVisualEffects`) must disable all glow/confetti and fall back to flat fills + solid borders.

## 4. Scope by screen → file
| Screen | File(s) | Work |
|---|---|---|
| Card face | `Views/CardView.swift` | New face: gradient + suit watermark + corner pip (value **and** suit — fix missing value), inner gloss, suit-glow shadow. Keep `CardBackView` (WP monogram) for draw pile. Preserve all accessibility labels & colour-blind pattern overlay. |
| In-game table | `Views/GameTableView.swift` | Center-pill score in `.principal` toolbar (single `HStack`, `nowrap`); balance vertical space with paired spacers around the table centre; bottom padding so the hand never clips. |
| Your hand | `Views/HandView.swift` | Straight overlapped row sized from `GeometryReader` to fit width; playable card lifts + glows; selected pops. No off-screen scroll wrapper. |
| Opponents | `Views/PlayerZoneView.swift` | Avatar (initial + count badge) for left/right seats; thinking-state glow ring + dots. Partner stays an open mini-fan in a grouped panel. |
| Table centre | `Views/TableCenterView.swift` | Larger discard card, draw pile with count, direction affordance; tightened to fill centre. |
| Home | `Views/HomeView.swift` | Neon wordmark (existing 4-suit monogram, glow), teal primary button, surface ghost buttons. |
| New game | `Views/NewGameFlowView.swift` | Replace plain `Form`/`Picker` with neon segmented controls + blurbs + teal Start. |
| Round end | `Views/PauseMenuView.swift` (`RoundEndView`) | Neon trophy + confetti (respect reduced motion), scoreboard with WON badge, teal buttons. |
| Settings | `Views/SettingsView.swift` | Neon section labels, teal toggles, link rows. |
| Pause menu | `Views/PauseMenuView.swift` | Restyle to neon surfaces. |

## 5. Constraints to honour (do not regress)
- **Accessibility**: keep every VoiceOver label/hint; colour-blind mode + pattern fills still work; Dynamic Type still reflows without clipping; respect Reduced Motion / Reduced Visual Effects.
- **Enterprise**: no new dependencies, no network, no new Info.plist permissions. Pure SwiftUI.
- **Architecture**: views only render state + forward intents; no logic moves into views. `WildPairsCore` untouched.
- **Style**: views stay small (~≤80 lines); tokens live in `Theme`, never hard-coded in views.

## 6. Build order
1. Theme tokens (Neon palette) — foundation.
2. `CardView` face redesign (highest-impact; verify in isolation first).
3. Hand straight-row + table layout/score header.
4. Opponent avatars + partner panel.
5. Home / New game / Settings / Round-end restyle.
6. Pass over colour-blind + Dynamic Type + reduced-motion variants.

## 7. Quality gates (must pass before Phase 10 closes)
- `./scripts/quality_light.sh` after each Swift edit; `./scripts/quality_full.sh` at the end.
- `./scripts/check_no_network_usage.sh`, `check_permissions_minimal.sh`, `check_project_capabilities.sh`, `check_privacy_manifest.sh`.
- Skills: **swiftui-quality-review**, **ux-review**, **accessibility-audit** verdicts recorded; **phase-gate** to close.
- Simulator verification on iPhone + iPad (portrait), default + largest Dynamic Type, colour-blind on/off, reduced motion on/off — screenshot each core screen; confirm nothing clips.
- Brand check: `grep -r "UNO\|Mattel\|uno" docs/ WildPairsApp/` stays clean.

## 8. Risks
- Glow/shadow cost at large hand counts → cap glow to playable + selected cards; disable under Reduced Visual Effects.
- Straight-row overlap at AX Dynamic Type / small iPhone width → size overlap from `GeometryReader`, clamp min card width, verify on smallest device.
- Avatar opponents lose the "card count at a glance" feel → count badge is mandatory and high-contrast.
