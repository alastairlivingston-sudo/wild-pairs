# ChatGPT design brief — Solo table redesign

> Owner decision 2026-07-17: design elements for the UX match plan come from ChatGPT
> (concept mockups first, then finished assets), replacing the `/design-direction-lab`
> HTML-prototype step. This file is the paste-ready material. SwiftUI implementation and
> `/simulator-verify` parity checks stay in-repo as before.

## Source files to attach

Attach these screenshots from the repo to the ChatGPT conversation (they show the current
Phase-17 build — the "before" state):

| Priority | File | Shows |
|---|---|---|
| **Primary** | `docs/phase-17-design/current-ux/iphone-02-table-autostart.png` | iPhone table mid-game: translucent draw pile, bare L/R opponent circles, tiny direction glyph — the screen most of the feedback targets |
| Strongly recommended | `docs/phase-17-design/current-ux/ipad-03-table-landscape.png` | Same table on iPad landscape (layout must work here too) |
| Recommended | `docs/phase-17-design/partner-view/impl-active-half-beth-turn.png` | Side-to-Side partner mode (partner peek + stacked opponent backs variant) |
| Optional | `docs/phase-17-design/current-ux/ipad-04-colour-picker-and-roundend.png` | Colour picker + round-end surface (for the end-game ceremony work) |

## Round 1 — concept mockups (paste this)

```
You are designing a visual redesign for "Solo", an original, fully offline iOS/iPadOS card
game (SwiftUI, dark neon table theme). I'm attaching screenshots of the current build.
This is an original game: do NOT imitate UNO or any Mattel product's artwork, logo, card
faces, or trade dress in any way — the attached screenshots define our own existing style,
which you should evolve, not replace wholesale.

Game context: 2v2 team card game. Four card colours with elemental display names being
renamed to: Lava (red), Sky (blue), Grass (green), Sun (yellow). Partner's hand is open
(visible face-up) by design. There is a "Solo!" call when a player is about to go down to
one card. Play direction can reverse. Rounds have a single 3-minute countdown.

Produce 3 distinct visual direction mockups (images) of the mid-game table screen in
iPhone portrait, each addressing ALL of the following problems visible in the screenshots:

1. DRAW PILE: currently a weird translucent panel with "WP" on it. Redesign it as a
   convincing stack of physical face-down cards (with a card count badge). Design an
   original card-back for this.
2. OPPONENTS: currently just circles labelled "L"/"R" with a number chip. Show each
   opponent as a small fanned hand of face-down card backs (count still readable) plus an
   avatar. Avatars are abstract elemental crests/emblems — NOT human faces or characters.
3. WHOSE TURN + DIRECTION: a direction-of-play indicator (clockwise/anticlockwise arrows
   circling the table centre) that is ALWAYS visible and visibly flips when a Reverse is
   played; plus a much stronger "it's this player's turn" treatment (glow/spotlight on the
   active seat). It must be obvious at a glance whose turn it is.
4. SOLO! MOMENT: a prominent, satisfying "Solo!" call button/moment (the one-card-left
   declaration) — it should feel like shouting it at the table — and a visible "caught you,
   +2 penalty" treatment when a player who forgot to call gets caught.
5. QUICK-CHAT STRIP: a small row of tappable canned phrases the player can send to their
   AI partner (e.g. "Play +2", "Change colour", "Save your wild"). Compact, out of the way
   of the hand.
6. PARTNER PEEK: the partner's open hand should stay visible but read clearly as "my
   partner's cards" — in the partner-mode screenshot it is too subtle; make it clearer
   without dominating the screen.

Constraints:
- Keep the existing dark navy/neon look and the existing card face style; evolve it.
- Use the new colour names Lava/Sky/Grass/Sun where colour labels appear.
- Colour-blind safety: never rely on colour alone — keep per-colour symbols/patterns.
- Layouts must be plausible for BOTH iPhone portrait and iPad landscape (iPad has very
  little vertical space around the centre — see the iPad screenshot).
- Offline single-player game: no coins, currencies, store, or online/social elements.
  Celebrations dramatise SCORE only.
- Motion will be implemented separately and must respect iOS Reduced Motion, so mockups
  should read well as static layouts.

For each of the 3 directions, deliver: (a) the full iPhone table mockup, (b) a close-up
of the table centre (draw stack + discard + direction indicator), and (c) one sentence on
the idea behind the direction. Number the directions 1–3 so I can pick one.
```

After Round 1: pick a direction (optionally iterate), then run Round 2 in the same
conversation so it keeps the context.

Also ask, in the same conversation once a direction is picked, for a matching mockup of
the **end-of-game rank ceremony** screen (winning team trophy, final scores, score-
multiplier bonus breakdown line, one-tap "Play again" button) — Tier-1 item 2 shares the
chosen direction.

## Round 2 — finished assets (paste after picking a direction)

```
I'm going with direction N. Now produce production-ready image assets in that exact style,
each on a transparent background (PNG) unless noted:

1. Four avatar crests, one per element — Lava, Sky, Grass, Sun — abstract emblems, no
   human faces, each distinguishable in silhouette alone (colour-blind safe). 1024x1024.
2. Card-back design for the draw stack and opponent fans (portrait card, rounded corners
   baked into the alpha). 1024x1434 (same 0.714 aspect as our card faces).
3. Direction-of-play indicator: clockwise arrow ring around the table centre. One asset;
   we will mirror it in code for anticlockwise. 1024x1024, transparent.
4. "Solo!" call badge/burst and a "+2 caught" penalty badge, matching the direction's
   style. 1024x1024 each.

Keep exact colours consistent with the mockup. No text baked into assets except "Solo!"
and "+2". Deliver each as a separate downloadable file.
```

Import notes (for the implementing session): downscale/encode via asset catalogs
(`WildPairsApp/Assets.xcassets`), 1x/2x/3x from the 1024 masters; verify silhouettes at
~28pt (avatar-in-seat size) before accepting; run `/simulator-verify` after wiring in.
