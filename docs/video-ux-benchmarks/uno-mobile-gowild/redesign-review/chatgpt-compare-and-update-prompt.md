# ChatGPT prompt — compare to UNO + update the UX (with code)

> Attach: my Solo recordings (`gameplay-iphone-compressed.mp4`, `gameplay-ipad-compressed.mp4`),
> the original mobile-UNO gameplay video you're benchmarking against, **and the source zip
> `solo-redesign-source.zip`** (the exact SwiftUI files you'll be editing — the paths inside the
> zip are the real repo paths, so quote them when you say where a change goes).

---

You're a senior mobile game-UX designer **and** a strong SwiftUI engineer. I'm giving you two things:
1. **Solo (my game)** — gameplay of a just-redesigned card table (iPhone + iPad).
2. **The original mobile UNO** — a gameplay video I'm benchmarking against.

**Solo** is an **offline, single-device** 2v2 card game (UNO-family, 100% original art and terms),
**SwiftUI, iOS 17+**. Hard constraints: **no** accounts, internet, ads, IAP, coins/currency, or
social/online features — these are deliberate, so don't propose them. Where UNO uses coins/rewards
for drama, my only lever is **score**. Ignore UNO's monetisation and online-meta layers entirely.

## Architecture you must fit into (don't fight it)
- **MVVM + unidirectional reducer.** Pure game logic lives in `WildPairsCore` (no SwiftUI/UIKit);
  the app `WildPairsApp` imports it. `GameEngine.reduce(state, action)` is the only place rules
  change. `GameViewModel` (`@MainActor`, ObservableObject) owns timers/AI scheduling and publishes a
  `GameViewState`. **Views render `GameViewState`; they never derive game logic.**
- Colours: internal `CardColour` cases are `crimson/cobalt/jade/amber` and **must never be renamed**
  (save/test/AI keys). Player-facing names come only from `CardColour.displayName`
  (currently Lava/Sky/Grass/Sun).
- Don't add a parallel timer, active-player flag, direction property, or score model — extend the
  existing owner. New transient UI signals are one-shot `@Published` events on `GameViewModel`
  (pattern: `cardFlight`, `drawFlight`, `seatCue`, `soloPenalty`).
- Keep these accessibility identifiers: `game-turn-rail`, `game-draw-card-button`,
  `game-move-timer`, `game-round-timer`, `game-pause-button`, `game-solo-button`, `seat-<0..3>`.

## Where things live (edit the owner, don't clone it)
- `WildPairsApp/Views/GameTableView.swift` — root composition; the `TableStateRail` (element +
  turn + round timer), Solo! burst button, all overlays, card-flight/handoff launchers.
- `WildPairsApp/Views/TableCenterView.swift` — draw/discard piles, three-layer deck, direction
  orbit, pile gap (`Theme.Table.drawDiscardGap`), `game-draw-card-button`, table anchors.
- `WildPairsApp/Views/PlayerZoneView.swift` — partner "OPEN HAND" shelf, opponent fans + elemental
  crests, `UP NOW`/white brackets, `CATCH +2`, `+N CAUGHT` stamp, `seat-<n>` ids.
- `WildPairsApp/Views/CardView.swift` — card shell + `CardBackView`; `SoloArtFace.swift` — image
  card faces.
- `WildPairsApp/Views/DecisionViews.swift` — in-table `ColourPickerView`, `MoveTimerBar`,
  `DrawFourChallengeView`, `TeamPassPickerView`, prompt banner.
- `WildPairsApp/Theme/Theme.swift` — design tokens (`Theme.Space`, `Theme.Radius`, `Theme.Motion`,
  `Theme.CardSize`, `Theme.Table`); `TableBackground.swift` — the table surface.
- `WildPairsApp/ViewModels/GameViewModel.swift` — published state, timers, one-shot events.
- `WildPairsCore/Presentation/GameViewState.swift` — the display projection + `CardColour.displayName`.

## Do three things
1. **Compare**, moment for moment: turn clarity, whose-turn + direction cues, play/draw
   choreography, action-card feedback (skip / draw / reverse / wild colour pick), the one-card
   "Solo!" call, opponent presence, end-of-round. Say where UNO reads better, and where Solo already
   matches or beats it. (Ignore UNO's coins/social.)
2. **Update the UX with real code.** For each change, give me:
   - the **exact target** — file + `struct`/function, and the precise insertion point (before/after
     which existing element, e.g. "inside `TableStateRail.body`, after the element chip");
   - the **SwiftUI code** — a paste-ready snippet or a full small component, matching the existing
     token/naming style; reuse `Theme.*` tokens and existing modifiers rather than hard-coded values;
   - any **new supporting bits** — a new `Theme.Table`/`Theme.Motion` constant, a new `GameViewState`
     field or `GameViewModel` one-shot event (say where it's set), or a new asset name — and note if
     a change adds a new file (the app target is folder-sourced, so a new file needs an `xcodegen
     generate` step; prefer editing existing files to avoid that).
   - respect Reduce Motion / Dynamic Type / the offline constraint.
3. **Flag** anything in the redesign that's over-designed, inconsistent, or off-brand to cut (with
   the code/lines to remove).

## Output format
A one-paragraph verdict + score /10; then a **prioritised change list** (High/Med/Low, most
impactful first) where every item is `target → why → code → placement`; then 3–5 "keep these".
Keep prose tight — the value is in specific, correct, placeable code.
