# Solo — Current UX Audit (Phase 17 "before")

A self-contained handoff for the design team: what the app does **today**, where it's **weak**,
and the **code** each piece lives in. This is the "before" for the Phase 17 redesign
(`docs/phase-17-requirements.md`, plan in `docs/phase-17-design/`). Captures referenced below are
in `docs/phase-17-design/current-ux/`.

The headline brief from the player: **you can't tell what's happening as cards are played — who
played what, whose turn it is, which way play is going, who got skipped.** Turn/play feedback is
the priority redesign. Separately, the card faces are being **replaced** by a supplied art pack.

## How to reproduce these states
The app is procedural SwiftUI, portrait-locked on iPhone (iPad allows landscape). Debug launch
arguments jump straight to a state (no tapping):
- `--uitest-cardgallery` — every card face × colour, wilds, resolved-wild tints, the back, and
  table-centre states, on one scrollable screen (`WildPairsApp/Views/CardGalleryView.swift`).
- `--uitest-autostart` — a live solo table on the human's turn.
- `--uitest-autostart-2p` — two-human pass-and-play table.

## Captures in this folder
| File | Shows |
|---|---|
| `iphone-01-card-gallery.png` | Current "Ink & Foil" card faces (actions + wilds), iPhone |
| `iphone-02-table-autostart.png` | Full live table, iPhone portrait — the whole feedback story in one frame |
| `iphone-03-colour-picker.png` | Colour picker as a bottom sheet **covering the hand** (C5), iPhone |
| `iphone-05-play-and-picker-motion.mp4` | 18s: playing a wild + the picker sliding up (the current, weak play motion) |
| `ipad-01-card-gallery-landscape.png` | Card faces, iPad landscape |
| `ipad-03-table-landscape.png` | Full live table, iPad landscape (13") |
| `ipad-04-colour-picker-and-roundend.png` | Colour picker + round-end banner; note Team B on **402 pts** (scores do accumulate) |

---

## 1. Card faces — "Ink & Foil" (being replaced)
**Today:** every face is drawn procedurally (SwiftUI `Shape`/`Path`/`Canvas`, no image assets).
Near-black glass stock, a coloured foil frame, a single large hero glyph, mirrored corner indices,
and a faint colour-blind pattern overlay. Numerals for numbers/+2/+4; bespoke pictograms for
actions (skip = struck player token, reverse = chasing arrows, targeted draw = reticle, etc.).
Wilds are charcoal with a four-colour chip motif. See `iphone-01-card-gallery.png`.
**Code:** `WildPairsApp/Views/CardView.swift` (shell + glyphs), `Views/InkFoilFace.swift` (active
face), `Theme/CardSkin.swift` + `Theme/Theme.swift:27` (`activeCardSkin`). Card back is still
legacy white stock (`CardView.swift:841`), never re-skinned.
**"After":** the supplied art pack `docs/solo_swiftui_asset_pack.zip` (75 pre-rendered faces)
replaces these outright; the back and a new Draw Eight card need matching stand-ins (no art
supplied for them).

## 2. Table layout ("Living Table")
**Today:** perspective-relative zones — you (hand) at bottom, partner (open hand) top, opponents
left/right, draw+discard centre. `iphone-02` and `ipad-03` show it. On the 13" iPad landscape it
fits; on **smaller iPads landscape it needs vertical scrolling** (the whole table is inside a
`ScrollView`).
**Code:** `Views/GameTableView.swift` (zones via `seat(at:)`; `ScrollView(.vertical)` wrapper),
`Views/PlayerZoneView.swift`, `Views/TableCenterView.swift`.

## 3. Turn indication & order legibility — WEAK (priority)
**Today, three cues, all subtle:**
- Active seat: a soft pulsing element-tinted glow + a small "arrival pop" scale
  (`PlayerZoneView.swift:119-135,214`).
- Turn direction: a single small `arrow.clockwise` SF Symbol under the pile — persistent but easy
  to miss (`TableCenterView.swift:208`; the little ↻ in `iphone-02`/`ipad-03`).
- A text prompt banner ("Play a Rain card, a 4, or a wild card") does most of the work
  (`DecisionViews.swift:179`).
**Weak because:** there is no strong "whose turn", no legible sense of seat **order**, and
direction reads as decoration. In an AI-partner game there is no turn-change popup at all, so a
whole AI round can pass with almost no legible signal.
**Redesign target:** always-legible turn order (an orbit/spotlight travelling seat→seat in the
direction of play), a strong active-seat treatment, and an emphatic Reverse.

## 4. Play feedback — WEAK (priority)
**Today:** playing a card from your hand uses an in-place fade / slide-up transition **in the hand
only**; **there is no cross-table travel**. AI and partner plays simply **swap the discard's top
card** with no motion from the acting seat. See `iphone-05-play-and-picker-motion.mp4` — the wild
just appears on the pile.
**Code:** `HandView.swift:156-160` (local transition); AI/partner plays publish a new state with no
travel. `Theme.Motion.playArc` exists but is **unused** (`Theme.swift:92`).
**Weak because:** you cannot see who played what — the core complaint.
**Redesign target:** every play (all players) animates the card travelling from the acting seat to
the discard along an arc.

## 5. Draw feedback — WEAK
**Today:** drawing produces haptics + sound only; drawn cards just appear in the re-sorted hand.
No card travels from the draw pile. The engine even emits `animateCardDraw(count:)` but the app
uses it only for haptics/sound.
**Code:** `GameViewModel.swift:368-370`; `Theme.Motion.draw` defined but **unused** (`Theme.swift:93`).
**Redesign target:** cards fly from the pile to the hand, staggered so a 6-card penalty draw reads
visibly longer than a single draw.

## 6. Skip / Reverse / Draw-on cues — ABSENT (priority)
**Today:** the engine emits `animateSkip`, `animateSkipTwo`, `animateReverse`, `animateTeamPlay`,
but the app **ignores them** (`GameViewModel.handle` hits `default: break`,
`GameViewModel.swift:385`). So a Skip produces **no seat-level visual** at all; Reverse only nudges
the tiny direction arrow.
**Redesign target:** bold seat callouts — a "skipped" stamp on the skipped seat(s), a direction
sweep on Reverse, a `+N` token flying to the seat that has to draw.

## 7. Stacking / "+N" penalty display
**Today:** when a Draw Two/Four stack is pending, the draw pile shows a `+N` badge reading the
engine's accumulated total (`TableCenterView.swift:127`, `+\(pendingDrawCount)`). The gallery's
"table centre — forced pickup" tile demonstrates a `+6` badge.
**Weak because:** a Draw Two adds its +2 **immediately**, but a Draw Four's +4 is added **only
after the colour is chosen**, so the badge updates inconsistently depending on which card started
the stack (the reported "+2 → +6 sometimes wrong"). This is a fix, not a redesign, but the badge
is a candidate for the stronger play-feedback language too.

## 8. Opponent seats — avatar only (no pile)
**Today:** opponents render as an initial-letter avatar circle + a card-count badge (the "L 7" /
"R 7" in `iphone-02`). A fanned card-back **pile view already exists but is unused**
(`PlayerZoneView.swift:169`, capped at 5).
**Redesign target:** show a real card-back pile whose size tracks the opponent's hand count (keep
the number for exactness).

## 9. Colour picker covers the hand
**Today:** after a Change Colour / Draw Four, a "Choose a new colour" picker appears. On iPhone
it's a bottom sheet that **covers the local hand** (`iphone-03-colour-picker.png`); on iPad it
floats centre over the table (`ipad-04`).
**Code:** `DecisionViews.swift:7` (`ColourPickerView`), presented as a `.sheet` with a fixed height
detent (`GameTableView.swift:143`).
**Redesign target:** an in-table picker near the discard that leaves the hand and partner hand
visible.

## 10. Timers
**Today:** a 3-minute round timer (`iphone-02` shows 2:51) and a per-move timer. The per-move limit
is **30s in code** (`RuleProfile.swift:99,114,129`) though the design docs say 10s; there is **no**
"drop to 5s in the final minute" behaviour. The move bar only appears in the last ~12s of a move.
**Redesign/fix target:** 10s per move, dropping to 5s once the round is inside its final minute.

## 11. Round end & scoring display
**Today:** round end shows a win/lose banner + a scoreboard; game scores accumulate across rounds.
`ipad-04` shows "Opponents win this round… decided by lowest score" with **Team B on 402 pts** —
proving scores *do* accumulate (winner banks the losers' remaining card points; loser gets 0).
**Note for the team:** the engine's scoring model is correct and staying; the player's "scoring
doesn't work" is being investigated as a **display** issue (e.g. whether the score is hidden when
casual "scoring" is off). Not a visual redesign item, but the round-end and score-bar treatments
are in scope for polish. **Code:** `Views/PauseMenuView.swift` (`RoundEndView`), `GameTableView`
score bar.

## 12. Hand sorting (already good)
**Today:** the local hand is already sorted colour → type (numbers before actions) → ascending
value on every update (`GameViewState.cardSortsBefore`). Partner/opponent hands are not re-sorted.
Mostly a verify item, not a redesign.

---

## Where the redesign goes next
- **Turn/play legibility (§3–6, §8)** is the headline redesign — see Plan Stage 3
  (`docs/phase-17-design/...`). Recommend a short design exploration of the table's *feedback
  language* before build.
- **Card art (§1)** is replaced by the asset pack (Plan Stage 5 E), with procedural stand-ins for
  the card back and the new Draw Eight card.
- **Colour picker (§9), timers (§10), stacking display (§7)** are targeted fixes bundled into the
  same phase.
