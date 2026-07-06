# Phase 16 Design Plan — Ink & Foil deck + swappable card skins + Colour Burst card

**Chosen direction:** 05 · Ink & Foil (Alastair, 2026-07-06). Parity reference:
`docs/phase-16-design/05-ink-and-foil.html` — collector's black-glass deck; colour as
jewellery (luminous foil frames, gradient-foil marks, giant tone-on-tone embossed suit mark).
Brief and hard constraints: `00-brief.md`.

## 1. Card-skin architecture (the swap seam)

Goal: a future deck restyle touches exactly three things — one new face file, one enum case,
one token flip. Nothing else in the app knows what a card looks like.

| Piece | File | Role |
|---|---|---|
| `CardSkin` enum | `WildPairsApp/Theme/CardSkin.swift` | `case glossPrint, inkFoil` + `Theme.activeCardSkin` token (the only switch point) |
| `CardFaceContext` | same file | Everything a face may render: card, size, isPlayable/isSelected, showColourName, showPattern, wildTint, reducedMotion, colourScheme |
| `GlossPrintFace` | `WildPairsApp/Views/GlossPrintFace.swift` | The Phase 15c face, extracted verbatim from CardView (kept as proof the seam works and as instant rollback) |
| `InkFoilFace` | `WildPairsApp/Views/InkFoilFace.swift` | New skin, incl. `InkFoilTokens` (all colours/metrics below) |
| `CardView` | unchanged public API | Thin shell: accessibility, playable ring, selection scale, then `switch Theme.activeCardSkin` |
| Shared glyphs | stay in CardView.swift (or CardGlyphs.swift if size forces a split) | SuitSymbol + the Phase 15 pictorial action glyphs are the deck's *vocabulary*, not its *style* — skins restyle them (white print vs foil), never redraw them |

### Skin Swap Contract — what to feed a future design run
1. **A self-contained HTML prototype** in `docs/phase-16-design/` format. `00-brief.md`
   defines the mandatory reference state (numbers 7/3/0/9, all action types, both wilds,
   5-card fan, 64 pt small row, 4 pattern rows) and the hard constraints (no captions,
   suit always visible, gloss production story, engine palette hexes). The HTML **is** the
   spec — a design tool only has to produce that one file.
2. From it, fill the **token sheet** (the shape of `InkFoilTokens` §2 below): stock, per-suit
   ink + foil gradient stops, frame treatment, typography sizes as fractions of card width,
   glyph stroke language, shadows/glow, reduced-effects story.
3. Implementation recipe: new `XyzFace.swift` consuming `CardFaceContext` + shared glyphs,
   `case xyz` in `CardSkin`, flip `Theme.activeCardSkin`, then parity-check the
   `--uitest-cardgallery` screen against the HTML side-by-side per form factor.

## 2. InkFoilTokens (from the prototype)

- Stock: linear 170° `#16121E → #0D0A13`; radius 13 pt equivalent (`Theme.Radius.card`);
  outer rim `white 8%` hairline for figure-ground on the dark table; existing double shadow.
- Foil gradients (120°, 3 stops): crimson `#FF8A3D→#E8431F→#FF8A3D`; cobalt
  `#4FD2F0→#1B5FD9→#4FD2F0`; jade `#5ADF9B→#2F8F5B→#8FAE99`; amber
  `#FFE08A→#C9A227→#FFE08A`. Wild: conic all-four ring (frame) / 4-stop linear (marks).
- Frame: inset 4.7% of width, stroke ~1.6% of width, foil gradient + inner glow (suit
  highlight at 25%) + outer bloom (12%). Reduced effects ⇒ glows off, stroke stays.
- Emboss: giant suit mark, suit highlight at 16%, anchored bottom-right off-card (−14%, −8%),
  size 100% of width. Not on wilds.
- Hero marks: numerals/+2/+4 in foil gradient (`foregroundStyle` gradient on Text),
  weight 800, size 69% of width (numbers), 52% (+2/+4). Action glyphs: shared glyph shapes,
  foil gradient where the shape inherits `foregroundStyle`, else flat suit highlight.
- Indices: both corners, mirrored; rank (13% of width, weight 800) over suit mark (9.3%),
  in suit highlight colour. Wilds: four-chip mini-motif.
- Gloss: single 155° sheen `white 14% → 2% → clear` — the production finish nod.
- Colour-blind: pattern fills print in suit highlight at 10%; colour-name foot plate renders
  as suit-highlight text on `#0D0A13` plate. Resolved wild (`wildTint`): frame + hero take
  the chosen suit's foil; stock stays black.
- Playable ring: unchanged accent teal — it must stay skin-independent (affordance, not style).

## 3. New engine card — Colour Burst (`discardColour`)

The coloured cousin of Discard All (wild): a Colour Burst card is printed in one of the four
colours; playing it discards **every card of its own colour** from your hand along with it.
No decision prompt (colour is fixed), so it resolves inside `applyCardEffect` — the wild
Discard All's resolution in `handleSelectColour` is the template.

| Site | Change |
|---|---|
| `Card.swift` | `case discardColour` in `CardType` (Codable case name is the stable contract; old saves unaffected — they simply never contain it) |
| `CardFactory.swift` | `discardColour(_ colour:)` factory |
| `Deck.swift` | Advanced set: 1 per colour (+4 cards ⇒ advanced deck 96 → 100) |
| `GameEngine.applyCardEffect` | New case: filter hand by `card.colour`, discard removed on top of pile (mirrors Discard All), `.animateDiscardAll` effect (reused), advance turn |
| `GameEngine.handlePlayCard` | Solo! nuance: if the burst removed extra cards and left exactly one, that is an *effect drop* ⇒ grace window (`applySoloRequirementViaEffect`); if it removed nothing, normal declare-at-two rules (`ViaPlay`). Win-on-empty is already generic |
| `GameEngine` scoring | 20 points (action card) |
| `GameRules` | No change — colour/type matching is generic |
| `AIPlayer` | Conservation: treat like `discardAll`/`forcedSwap` (hold when urgency < 0.5) |
| `GameViewState.typeRank` | Insert in coloured-action block |
| `Theme.abbreviation` | `"BURST"` (accessibility string only — no face captions) |
| CardView/skins | New glyph: three suit-coloured mini-cards swept off by one ejection arrow (Discard All's silhouette family, but the minis carry the suit) + corner miniature |
| `RulesView` glossary | "Colour Burst — discards every card of its colour from your hand along with it." |
| Docs | `game-rules.md`: composition table, new §Colour Burst, scoring table, Solo! grace list. `CLAUDE.md`: card-type row |
| Prototype 05 | Add a Colour Burst card to the actions row (parity reference for the new face) |

Deliberate behaviours (documented, test-pinned): burst cards go face-up **on top** of the
played card exactly as wild Discard All does (same-family consistency; colour matching is
unaffected because they share the burst colour); active colour stays the card's colour;
All-Wild mode changes nothing.

### Tests (RulesTests/EngineTests additions)
1. Burst removes every same-colour card + itself; other colours untouched; currentColour kept.
2. Burst emptying the hand wins the round for the team.
3. Burst 5→1 (extras removed) ⇒ `soloGraceAtOne`, declaration at one card legal.
4. Burst 2→1 (no extras) ⇒ no grace (via-play rules).
5. Legality: playable on colour match and on type match.
6. Advanced deck contains exactly 4 (one per colour); advanced total 100.
7. Codable round-trip; 20-point scoring.

## 4. Order of work
1. Commit lab artefacts + this plan (parity reference frozen).
2. Engine: Colour Burst + tests + docs — `swift test` green. Commit.
3. Skin seam + InkFoilFace + Colour Burst glyph; `xcodebuild build`; gallery screenshot
   parity evidence. Commit.
4. Deferred to next session (needs Alastair): per-form-factor /simulator-verify checkpoints,
   /swiftui-quality-review, /accessibility-audit (contrast on dark stock is the known risk),
   then the remaining Phase 16 motion items.

## 5. Out of scope for this pass
Card backs, table chrome, HandView fan geometry, motion items (card travel etc.), the
iPad colour-picker popover, App Store icon. Reduced-effects fallback ships with the skin;
Dynamic-Type large-card audit rides the existing accessibility flow.
