# ChatGPT prompt — design critique of the Solo table redesign

> Paste everything below into ChatGPT and attach the two gameplay recordings
> (`gameplay-iphone-compressed.mp4` and `gameplay-ipad-compressed.mp4`). If ChatGPT
> samples frames rather than watching in full, tell it to focus on the moments listed
> under "What to look for".

---

You are a **senior product & game-UX designer** reviewing a pre-release build. Give me a
rigorous, specific, and honest critique — not reassurance. Assume I want to ship something that
feels premium and legible, and that flattery is worthless to me. Where something is weak, say so
plainly and say why, grounded in what you can actually see in the videos.

## The product
**Solo** is an offline, single-device 2v2 team card game (a shedding / colour-and-number matching
game in the UNO family, but with 100% original art, colours, and terminology). One human plays
with an AI partner against two AI opponents; there is also a same-device pass-and-play mode. It is
**strictly offline**: no accounts, no internet, no ads, no in-app purchases, no coins/soft
currency, no social features, no leaderboards. That is a deliberate product stance, not a gap —
so please **do not** recommend monetisation, live-ops, social, or online-multiplayer features.
Where the reference game (mobile UNO) uses coins/rewards for drama, our equivalent lever is
**score** (a per-round points total with a difficulty multiplier).

## What this redesign just changed (so you know what's intentional)
The videos show a newly integrated "table redesign". Deliberate elements to evaluate:
- A **unified state rail** under the top edge: current colour chip + whose turn it is + a round
  countdown timer, in one bar.
- **Element display names**: the four colours are shown as **Lava / Sky / Grass / Sun** (with the
  whole table tinting to the active element). Distinct suit symbols and colour-blind patterns exist.
- A **"PARTNER · OPEN HAND"** shelf: your AI partner's hand is shown face-up (this is by design —
  teammates share hand info).
- **Opponent fans**: each opponent is a fan of face-down card backs topped by an abstract
  **elemental crest**, with an exact count badge.
- **Active-turn treatment**: white corner brackets + an explicit **"UP NOW"** flag on whoever is to
  act, plus a turn-handoff light sweep between seats.
- A physical **three-layer draw deck** with an outside-edge count badge, a gap to the discard, and
  an always-visible **direction orbit** ("CLOCKWISE / COUNTER-CLOCKWISE") around the piles.
- Card **travel animations** (a played card flies from the acting seat to the discard; draws fly
  from the deck to the hand, more cards = longer).
- A native **Solo!** call button (thumb zone) and a **"CATCH +2"** affordance for catching an
  opponent who dropped to one card without calling.
- An in-table **colour picker** (Lava/Sky/Grass/Sun) that deliberately does not cover the hand.
- A restrained animated background (a few slow motes; static fallback under Reduce Motion).

## What to look for in the recordings
The iPhone clip shows: your turn → calling **Solo!** → the **colour picker** → the table
re-tinting to the chosen element → a **+4 penalty** landing on an opponent → a **turn handoff**,
plus a **CATCH +2** affordance and a **round-end scoreboard**. The iPad clip (portrait) shows
draws, plays with **card travel**, colour theming, a **+2 draw-stack**, and the wider-screen layout.
Judge **motion and timing** as much as static layout — the whole point is that a turn should be
*readable*: who played what, whose turn it is now, and which way play is going.

## What I want from you
Work through these dimensions. For each, tell me what works, what's weak, and the *specific* fix:

1. **Legibility & visual hierarchy** — At a glance, can you tell whose turn it is, the current
   colour, and the state of play? Is the state rail pulling its weight, or competing with the
   partner shelf / prompt banner for the same attention?
2. **Turn-order & direction clarity** — Is the direction orbit + UP NOW + handoff sweep genuinely
   legible, or decorative? Does anything contradict itself (e.g. rail vs. seat cues during a
   transition)?
3. **Play & feedback choreography** — Do the card-travel, draw, stack-pop, skip/penalty, and
   colour-change moments *read*, and are they well-timed (not too fast/slow, not overlapping into
   mush)? Where would you add, cut, or retime motion?
4. **The new components individually** — critique the **state rail**, **partner shelf**, **opponent
   fans + crests**, **draw deck/orbit**, **Solo!/CATCH**, and **colour picker**. Flag any that feel
   over-designed, cramped, redundant, or off-brand.
5. **Consistency & polish** — spacing, alignment, type scale, corner radii, glow/shadow language,
   card-face vs. chrome cohesion. Call out anything that looks unfinished or inconsistent.
6. **Accessibility** — the crests and active-turn treatment must not rely on colour alone (they add
   shape + the "UP NOW" text — does that hold?); is text likely to survive large Dynamic Type; any
   contrast risks in the element tints (esp. **Sun/**yellow)?
7. **iPhone vs iPad** — does the layout adapt well, or is the iPad just a stretched phone? What
   would you do differently with the extra space?
8. **Emotional read** — does it feel premium, calm, and confident, or busy/generic? One honest
   sentence.

## Output format
- A one-paragraph **overall verdict** with a score out of 10 and the single biggest lever to raise it.
- A **prioritised issue list**: `[High/Med/Low] — observation — why it matters — concrete fix`,
  most important first. Be specific enough to action (name the element, the timing, the spacing).
- **3–5 "keep these"** — things that are genuinely good, so I don't regress them.
- Anything you'd **A/B test** rather than assert.
- Flag any recommendation that would require network, accounts, IAP, or social — and give the
  offline-compatible alternative instead (dramatise *score*, never currency).

Be concrete, cite specific moments/timestamps from the videos where you can, and don't pad.
