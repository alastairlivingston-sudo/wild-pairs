# Phase 16 Design Lab — Card Face Redesign Brief

## Verdict driving this lab
Alastair rates the Phase 15c faces **4/10** ("still poor"), overriding the earlier 8/10
judge score. The user's score is the score. Diagnosis after research: the current face is
the *mushy middle* — gradient + ghost watermark + gloss sweep + grain + offset-shadow glyph
all stacked on one card, so no single idea reads with confidence.

## What the research says great cards do
Sources: Balatro design analyses ([Medium](https://medium.com/@yyh19971004/balatro-design-analysis-visual-packaging-and-interactive-feedback-cc6fa6a65370),
[halabaojia](https://halabaojia.com/collection/20260212-balatro-visual-design-analysis/),
[Blake Crosley](https://blakecrosley.com/guides/design/balatro)), the
[UNO Minimalista project](https://www.behance.net/gallery/90273937/UNO-Versao-Minimalista)
([Gizmodo coverage](https://gizmodo.com/mattel-turned-this-graphic-designers-minimalist-uno-dec-1841832127)),
playing-card craft ([Daniel Solis: Visibility, Hierarchy, Brevity](https://danielsolisblog.blogspot.com/2024/02/three-principles-of-card-design.html),
[Mattgyver deck tips](https://www.mattgyver.com/tutorials/2022/3/14/playing-card-deck-design-tips),
[Crab Fragment Labs](https://crabfragmentlabs.com/lecture-hall/designing-traditional-card-decks)),
and tabletop iconography ([Mindclash](https://mindclashgames.com/blog/board-game-iconography-how-smart-symbols-enhance-ux-and-playability/)).

1. **One confident idea per face.** Decoration never competes with the decision-making read.
2. **Colour is an information system**, not styling — hue changes must mean something.
3. **Bold silhouettes beat detail.** An icon that survives 20px is an icon; anything else is
   an illustration.
4. **Counter-indexing wins fans.** The corner is the card in a fan; it must carry rank + suit
   alone, at every scale, mirrored in opposite corners.
5. **No mushy middle.** Great decks are decisively minimal (Minimalista) or decisively
   maximal (Balatro) — half-measures read as cheap.

## Hard constraints (all seven directions comply)
- Gloss-print production finish story — **never** the heritage ivory deck (corrections log).
- **No caption text on faces.** Glyphs only; numerals (7, +2, +4, ×2) are marks, not captions.
- Suit symbol visible on **every** card, wilds included (four-chip motif is deck trade dress).
- Colour-blind pattern fills must have a home (hatch / horizontal / vertical / dots).
- All 11 card types render; engine vocabulary (`crimson/cobalt/jade/amber`) untouched.
- Palette is the shipped one: Fire #E8431F/#FF8A3D, Rain #1B5FD9/#4FD2F0,
  Earth #2F8F5B/#8FAE99, Wind #C9A227/#D8C77E, wild charcoal #232030, table #0D0820→#1A1242.

## Shared reference state (identical in every prototype, real content)
- Numbers: Fire 7, Rain 3, Earth 0, Wind 9
- Actions: Skip (Fire), Reverse (Rain), Draw Two (Earth), Skip Two (Wind),
  Targeted Draw (Fire), Forced Swap (Rain), Team Play (Earth), Discard All (Wind)
- Wilds: Change Colour, Draw Four
- A 5-card overlapped fan (corner-read test), a 44pt small-scale row (opponent/discard test),
  and the four colour-blind patterns applied to the number row.

## What wins
The direction (or hybrid) Alastair picks from the rendered set. Winner then gets a design
plan (`design-plan.md`), SwiftUI implementation starting from CardView's anatomy, and
side-by-side parity checks per form factor via /simulator-verify.
