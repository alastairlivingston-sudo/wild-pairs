# ChatGPT design brief — Solo table redesign (single prompt)

> Owner decision 2026-07-17: design elements come from ChatGPT in **one prompt** that
> returns everything — mockups, production assets, and implementable SwiftUI code —
> replacing the `/design-direction-lab` HTML-prototype step. SwiftUI integration and
> `/simulator-verify` parity checks stay in-repo as before.

## Source files to attach

These are the **latest** captures of the build (2026-07-11, Phase-17 stage-3 motion work —
the newest visual style: bright textured card faces, scene tinting to the active colour).
Attach all five:

| File | Shows |
|---|---|
| `docs/phase-17-design/stage3-motion/01-handoff-spotlight-arriving.png` | Your turn: translucent "WP" draw panel behind discard, stacked opponent backs, Solo! button, Play chip |
| `docs/phase-17-design/stage3-motion/02-played-card-in-flight.png` | Card travelling to the discard mid-animation |
| `docs/phase-17-design/stage3-motion/03-active-seat-tinted-to-scene.png` | Opponent's turn: whole scene tinted to active colour, right-opponent highlight |
| `docs/phase-17-design/stage3-motion/04-resolved-wild-colour-chip.png` | Move-timer bar ("9s to play"), wild card resolved on discard |
| `docs/phase-17-design/partner-view/impl-active-half-beth-turn.png` | Side-to-Side partner mode (partner's face-up hand, top half) |

Optionally also attach `docs/phase-17-design/current-ux/ipad-03-table-landscape.png` for
the iPad **layout** only — tell ChatGPT its visual style is an older build and to ignore it.

## The prompt (paste all of this, with the screenshots attached)

```
You are redesigning screens for "Solo", an original, fully offline iOS/iPadOS card game
built in SwiftUI (iOS 17+). The attached screenshots are the CURRENT build — evolve this
existing style, don't replace it wholesale. This is an original game: do NOT imitate UNO
or any Mattel product's artwork, logo, card faces, or trade dress in any way.

GAME CONTEXT: 2v2 team card game. Four card colours whose display names are being renamed
to: Lava (red), Sky (blue), Grass (green), Sun (yellow). Your partner's hand is open
(face-up, top of screen) by design. A "Solo!" call must be made when about to go down to
one card; a player who forgets can be caught for a +2 penalty. Play direction can reverse.
Each round has a single 3-minute countdown, plus a short per-move timer.

PROBLEMS TO SOLVE (all visible in the screenshots):
1. DRAW PILE: currently a translucent panel with "WP" on it, sitting behind the discard.
   Redesign as a convincing stack of physical face-down cards beside the discard, with a
   readable card-count badge. Design an original card-back for it.
2. OPPONENTS: currently dark rounded "WP" stacks with a number chip. Show each opponent as
   a small fanned hand of face-down card backs (count still readable) topped by an avatar.
   Avatars are abstract elemental crests/emblems — NOT human faces or characters — one per
   element: Lava, Sky, Grass, Sun.
3. WHOSE TURN + DIRECTION: add a direction-of-play indicator (arrows circling the table
   centre) that is ALWAYS visible and visibly flips when a Reverse is played. Strengthen
   the "it's this player's turn" treatment beyond the current subtle glow/tint — obvious
   at a glance, and not communicated by colour alone.
4. SOLO! MOMENT: make the "Solo!" call button prominent and satisfying — it should feel
   like shouting it at the table — plus a clear affordance for CATCHING an opponent who
   forgot to call, and a visible "+2 caught" penalty treatment.
5. QUICK-CHAT STRIP: a compact row of tappable canned phrases sent to the AI partner
   (e.g. "Play +2", "Change colour", "Save your wild"), out of the way of the hand.
6. PARTNER PEEK: in the Side-to-Side screenshot the partner's open hand reads as too
   subtle — make "these are my partner's cards" clearer without dominating the screen.

HARD CONSTRAINTS:
- Keep the existing look (dark table, scene tinting to the active colour, bright textured
  card faces) and evolve it — same card faces, same general layout skeleton.
- Use the colour names Lava / Sky / Grass / Sun wherever colour labels appear.
- Colour-blind safety: never rely on colour alone; keep per-colour symbols/patterns.
- Must work in iPhone portrait AND iPad landscape (iPad has little vertical space around
  the table centre).
- Fully offline single-player game: no coins, currencies, store, online, or social
  elements. Celebrations dramatise SCORE only.
- Respect iOS Reduced Motion: every animation you specify needs a static fallback.

DELIVERABLES — produce ALL of these in your response, in this order:

A. MOCKUPS (images): (1) the full redesigned mid-game table in iPhone portrait on your
   turn; (2) a close-up of the table centre (draw stack + discard + direction ring +
   turn indicator); (3) the same table during an opponent's turn showing the whose-turn
   treatment; (4) a short note + rough sketch of how the layout adapts to iPad landscape.

B. PRODUCTION ASSETS (each a separate downloadable PNG, transparent background, matching
   the mockups exactly):
   1. Four avatar crests — Lava, Sky, Grass, Sun — distinguishable by silhouette alone,
      1024x1024.
   2. The card-back for draw stack + opponent fans, 1024x1434 (0.714 aspect), rounded
      corners baked into the alpha.
   3. Direction-of-play arrow ring (clockwise; we mirror it in code), 1024x1024.
   4. "Solo!" call burst and "+2 caught" penalty badge, 1024x1024 each. No text baked
      into assets except "Solo!" and "+2".

C. SWIFTUI CODE (this is the most important deliverable — it must be directly usable):
   One complete, compiling Swift file named `TableRedesignKit.swift` for iOS 17 SwiftUI,
   no third-party dependencies, containing:
   - `enum TableDesignTokens` — every colour as `Color(red:green:blue:)` with the exact
     hex noted in a comment, plus spacing/radius/font constants used in the mockups.
   - `struct DrawStackView: View` — the stacked draw pile with count badge (uses the
     card-back asset via `Image("solo_card_back")`).
   - `struct OpponentSeatView: View` — avatar crest (`Image("crest_lava")` etc.) over a
     fanned row of card backs with a count badge; parameters: element, cardCount,
     isActiveTurn.
   - `struct DirectionRingView: View` — the always-visible ring; parameter
     `isClockwise: Bool`, animated flip on change with a Reduced Motion fallback
     (`@Environment(\.accessibilityReduceMotion)`).
   - `struct ActiveTurnHighlight: ViewModifier` — the whose-turn treatment.
   - `struct QuickChatStrip: View` — the canned-phrase row; parameter: phrases
     `[String]`, `onSend: (String) -> Void`.
   - `struct SoloCallButton: View` — the prominent Solo! button with pressed/urgent
     states, and a `CaughtPenaltyBadge` view for the +2 moment.
   - A `#Preview` for each view.
   Every view must have sensible `accessibilityLabel`s, work with Dynamic Type, and never
   encode information in colour alone. Use placeholder `Image(...)` names exactly matching
   the assets in B so they drop straight into an Xcode asset catalog.

D. INTEGRATION NOTES: a short list mapping each view in C to where it replaces current UI
   (draw pile/discard centre, opponent seats, turn indicator, hand-adjacent chat strip),
   plus the asset-catalog names for the files in B.

If the response gets too long, prioritise C, then B, then A — but deliver all sections.
```

## Import notes (for the implementing session)

- Screenshots above are the ground truth for "current style"; the iPad shot is layout-only.
- Downscale the 1024 masters via asset catalogs (`WildPairsApp/Assets.xcassets`, 1x/2x/3x);
  verify crest silhouettes at ~28pt seat size before accepting.
- `TableRedesignKit.swift` is a starting point, not a drop-in: adapt it to the repo's
  MVVM/reducer structure (views stay dumb, state comes from `GameViewModel`), match the
  no-comments style rules, then run `/swiftui-quality-review`, `/accessibility-audit`,
  and `/simulator-verify` (iPhone → iPad).
