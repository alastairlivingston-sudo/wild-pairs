# Phase 10 — Implementation plan (design → app)

Companion to [phase-10-plan.md](phase-10-plan.md). That doc is the *what/why*; this is the
*how* — an ordered, commit-sized, verifiable build sequence to land the locked **Neon Arcade**
direction (Center-pill header · Straight-row hand · Avatar opponents) in the SwiftUI app.

Canonical visual spec: `docs/phase-10-design/neon-final.html`.

## Guiding facts (why this is less work than it looks)
- **Tokens cascade.** Buttons, badges, toggles, and the table background all read from
  `Theme.Palette.accent` / `Theme.Felt`. Re-point those and most chrome reskins itself.
- **The hand is already right.** `HandView` is already a width-aware overlapping straight row
  with a scroll fallback and no clipping ([HandView.swift:34](../WildPairsApp/Views/HandView.swift)).
  We restyle, not rebuild.
- **The card already shows value + suit in the corner.** `CardView.corner` renders both
  ([CardView.swift:80](../WildPairsApp/Views/CardView.swift)); the corner-value bug was only in
  the HTML mock. The card work is palette + glow, not structure.
- **Scope is presentational only.** No file under `WildPairsCore/` changes. View-models are
  touched only to add `teamA/teamB` colour lookups if needed.

## Pre-flight
1. Branch: `phase-10-neon` off `main`.
2. Baseline: `swift build` + `swift test` green; capture "before" simulator screenshots of all 5
   screens (iPhone 15) for the PR.
3. Keep `.preferredColorScheme(.dark)` everywhere (neon is dark-first).

---

## Step 1 — Token foundation  ·  `Theme/Theme.swift`, `Theme/TableBackground.swift`
The reskin backbone. Do this first; expect a transient "mixed" look until later steps land.

**`Theme.Palette`**
| Token | From | To |
|---|---|---|
| `accent` | `0xD9B872` gold | `0x36E0C8` teal |
| `onAccent` *(new)* | — | `0x04130F` (text/icon on accent) |
| `teamA` *(new)* | — | `0x16E08A` (jade) |
| `teamB` *(new)* | — | `0xFF2E63` (crimson) |
| `cream` | `0xF3ECD9` | `0xEEF0FF` (neon ink) |
| `success` | keep `0x4CAF6D` | keep (used by "Out!") |

**`Theme.Felt` → neon field** (names kept so `TableBackground` needs no edit):
- `baseDark 0x0B2C26 → 0x0D0820`, `baseDarkHighlight 0x163F35 → 0x1A1242`.
- Set the `baseLight*` pair to the same neon values (dark is locked, but keep them safe).
- `vignette` → `Color.black.opacity(0.6)`.

**Button styles** ([Theme.swift:92](../WildPairsApp/Theme/Theme.swift)): replace the hard-coded
`Color(hex: 0x0B2C26)` foreground in `PrimaryButtonStyle` with `Theme.Palette.onAccent`. Add an
optional accent glow `shadow(color: accent.opacity(0.5), radius: 14)` gated on a `glow` flag
(disabled under reduced motion — see Step 8).

**`CardColour.fillColor` / `highlightColor`** ([Theme.swift:269](../WildPairsApp/Theme/Theme.swift)) →
neon, scheme-independent bright stops:
| Colour | `fillColor` (base) | `highlightColor` (top) |
|---|---|---|
| crimson | `0xFF2E63` | `0xFF6B8E` |
| cobalt | `0x2E7BFF` | `0x5FA8FF` |
| jade | `0x16E08A` | `0x5CFFB4` |
| amber | `0xFFB01F` | `0xFFD45E` |
Make `highlightColor` return these explicit stops (instead of the white-blend) so faces read as
neon, not pastel.

**Verify:** build; screenshot Home — background is the neon field, primary button is teal. No
test changes expected (colours aren't asserted).

---

## Step 2 — Card face  ·  `Views/CardView.swift`
Structure stays; upgrade the finish.
- Add `var reducedMotion: Bool = false` to `CardView` (thread from all call sites in Steps 3–6).
- Replace the flat black `shadow` ([CardView.swift:71](../WildPairsApp/Views/CardView.swift)) with a
  **suit-coloured glow** when `isPlayable || isSelected` and `!reducedMotion`
  (`faceHighlight.opacity(0.55)`, radius 10–14); otherwise the existing subtle black resting shadow.
- `borderColor` for a playable card: `Theme.Palette.success` → `Theme.Palette.accent` (teal ring),
  keep 3px.
- Wild face: keep the dark plum; it reads well on neon.
- Leave watermark, corner pip (value+suit), centre glyph, action `readableName`, colour-blind
  pattern overlay, and all accessibility labels **unchanged**.

**Verify:** add a SwiftUI `#Preview` rendering one of each `CardType` per colour + wild; eyeball
the neon faces and glow. Build.

---

## Step 3 — Score header (center pill)  ·  `Views/GameTableView.swift`
Kills the two-row wrap.
- Remove the three `toolbar` items (`Round N`, `scoreChip`, pause) at
  [GameTableView.swift:83](../WildPairsApp/Views/GameTableView.swift) and hide the nav bar
  (`.toolbar(.hidden, for: .navigationBar)`).
- Add a custom top bar overlay inside the `ZStack`, pinned under the safe area:
  `[ Round chip ]  ·····  [ ●A {score} · ●B {score} ] pill  ·····  [ pause ]`, single `HStack`,
  `lineLimit(1)`, never wraps. Dots use `Theme.Palette.teamA/teamB`; map `vs.scoreboard[0]→A`,
  `[1]→B`.
- Move the pause `Button { showPause = true; vm.pause() }` into the bar (keep
  `accessibilityIdentifier("game-pause-button")` so UI tests pass).
- Keep `Round \(vs.roundNumber)` text content for the round chip.

**Verify:** UI test `game-pause-button` still resolves; screenshot the table — score on one line.

---

## Step 4 — Opponent avatars  ·  `Views/PlayerZoneView.swift`
Swap fanned card-backs for the avatar treatment (partner stays an open fan).
- Add a branch: when `seat.visiblePartnerHand == nil` (i.e. an opponent), render a new
  `avatarSeat` instead of `backsFan`:
  - `Circle()` ⌀54 filled `Theme.Palette.surface`, border `accent` (current/thinking) else
    `white@22%`; initial from `seat.name.first`; **count badge** (`seat.handCount`) overlapping
    bottom-trailing using the existing accent capsule style.
  - Thinking → accent glow ring + reuse `ThinkingDotsView`.
  - Keep `statusBadges` ("Out!" / "Solo?") below, and the existing catch-Solo tap + combined
    accessibility element + `seat-\(seatPosition)` id — **do not regress VoiceOver**.
- Keep `backsFan` in the file (still used if a future non-partner open-hand case appears) but it is
  no longer the opponent default.
- Partner branch (`openHandFan`) unchanged except Step 5's width clamp.

**Verify:** the `seat-1`/`seat-3` ids resolve; catching a Solo! still fires `onCatchSolo`;
screenshot shows L/R avatars with counts.

---

## Step 5 — Table layout + partner clamp  ·  `Views/GameTableView.swift`
- Partner fan was clipping off the right edge. Clamp the partner `maxFanWidth` to
  `geo.size.width - Theme.Space.s4 * 2` (it currently sums side+centre widths and can overflow,
  [GameTableView.swift:149](../WildPairsApp/Views/GameTableView.swift)).
- Avatars are narrower than back-fans → reduce `sideWidth` allocation and give the centre column
  more room; balance vertical space with a spacer above **and** below the seats row so the table
  centre sits centred (matches the spec). Keep the existing `ScrollView` safety net for AX type.
- Thread `reducedMotion` into every `CardView(...)` call (hand, partner, discard, draw back).

**Verify:** iPhone SE + iPad, default and AX5 Dynamic Type — nothing clips; partner fan fully on
screen.

---

## Step 6 — Hand restyle  ·  `Views/HandView.swift`
Already a fitting straight row; just reskin the playable affordance.
- Playable lift stays (`-Theme.Space.s3`). Add a teal ring + glow on playable cards via the
  CardView changes from Step 2 (pass `reducedMotion`).
- Keep the `fanStep` width logic and the scroll fallback for extreme counts untouched.

**Verify:** 7-card hand renders fully; playable cards glow teal; illegal tap still shakes.

---

## Step 7 — Round end  ·  `Views/PauseMenuView.swift` (`RoundEndView`)
- Win trophy: `Theme.Palette.warning` (gold) → an accent **teal disc** with the trophy in
  `onAccent`; loss keeps the muted thumbs-down.
- `ConfettiView` palette → `[crimson, cobalt, jade, amber highlights] + accent` (keep 1.5s,
  keep the reduced-motion guard at [PauseMenuView.swift:84](../WildPairsApp/Views/PauseMenuView.swift)).
- Scoreboard panel → neon surface; add a "WON" badge on the winning team row.
- Buttons already use `wpPrimary/wpSecondary` (now teal) — verify contrast.

**Verify:** win + loss + timeout variants; reduced-motion shows the static badge, no confetti.

---

## Step 8 — New game setup  ·  `Views/NewGameFlowView.swift`
Replace the `Form`/`Picker` with neon segmented controls.
- New reusable `NeonSegmented<T: Hashable>` (label, options, selection) styled per the spec
  (surface track, teal active pill, `onAccent` text). Put it in `Theme.swift` or a small
  `Components/` file.
- Compose: Mode (3) · Difficulty (`Difficulty.allCases`) · Card set (3), each with its existing
  blurb; keep the `Start Game` button and `newgame-start` id and the `standardFourPlayer` builder.

**Verify:** `newgame-start` resolves; each control selects; blurbs update.

---

## Step 9 — Inheriting screens  ·  Home / Settings / Statistics / Pause
Mostly free from Step 1; confirm and polish.
- `HomeView`: wordmark suit colours now neon; add a soft glow behind the monogram; title
  `cream→ink`; primary button glow on. Background already neon.
- `SettingsView` / `StatisticsView`: `Form` + `scrollContentBackground(.hidden)` + accent tint
  already adapt; verify row contrast on the neon field (swap `Color.black.opacity(0.25)` rows to a
  neon `surface` only if contrast needs it).
- `PauseMenuView`: same — verify, restyle list rows only if needed.

**Verify:** screenshot each; check the toggle/active tints are teal and legible.

---

## Step 10 — Accessibility & motion sweep (cross-cutting)
- Reduced Visual Effects (`UserSettings.reducedVisualEffects`): all glow, confetti, and pulse
  paths must no-op → flat fills + solid borders. Audit every `shadow`/glow added in Steps 1–9.
- Colour-blind mode + Pattern fills: suit watermark + `CardPatternFill` overlay must still render
  on the neon faces; verify pattern contrast on the brighter fills.
- Dynamic Type to AX5 on every screen; VoiceOver pass on the table (avatars, hand, draw, catch-Solo).

---

## Verification matrix (run before the gate)
| Screen | iPhone SE | iPhone 15 | iPad | AX5 type | CB on | Reduced FX |
|---|---|---|---|---|---|---|
| Home · Setup · Table · Round-end · Settings | ✔ | ✔ | ✔ | ✔ | ✔ | ✔ |

Capture "after" screenshots for the PR alongside the "before" set.

## Gates (Phase 10 done)
- `./scripts/quality_light.sh` after each step; `./scripts/quality_full.sh` at the end.
- `./scripts/check_no_network_usage.sh`, `check_permissions_minimal.sh`,
  `check_project_capabilities.sh`, `check_privacy_manifest.sh` — all pass.
- Skills: **swiftui-quality-review**, **ux-review**, **accessibility-audit** verdicts recorded;
  **phase-gate** to close.
- `xcodebuild test` (iPhone + iPad schemes) green; existing UI-test identifiers all still resolve.
- Brand: `grep -r "UNO\|Mattel\|mattel\|uno" docs/ WildPairsCore/ WildPairsApp/` clean.

## Definition of done (per the original complaints)
1. Card faces look premium (neon gradient + glow + crisp pips). ✓ Steps 1–2
2. No card ever clips off-screen (hand, partner, opponents). ✓ Steps 4–6
3. No dead space; balanced table. ✓ Step 5
4. Score never wraps. ✓ Step 3
5. Hand + opponents read clearly. ✓ Steps 4, 6

## Suggested commit sequence
1 token foundation · 2 card face · 3 score header · 4 avatars · 5 layout/clamp · 6 hand ·
7 round-end · 8 setup · 9 inheriting screens · 10 a11y/motion sweep + gate.
Each is independently buildable and screenshot-verifiable.
