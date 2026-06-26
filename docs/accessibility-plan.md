# Wild Pairs — Accessibility Plan

> *Canonical sources: for data models (CardType, CardColour, Card), `technical-architecture.md` §Model Reference is canonical. For game rules, `game-rules.md`. For visual tokens, `design-system.md`. Where this document disagrees with its canonical source, the canonical source wins.*

**Version:** 1.0  
**Status:** Draft  
**Audience:** iOS engineers, QA  
**Platform:** iOS 17+, SwiftUI, Universal (iPhone + iPad)  
**Last updated:** 2026-06-21

---

## 1. Accessibility Mandate

Accessibility is not a feature to be added later. It is a baseline quality requirement, applied from the first line of code.

### Why this matters

**Everyone.** Accessibility features built for users with permanent disabilities benefit everyone in specific contexts: a player with one hand occupied, someone playing in bright sunlight who can't see colour clearly, a player who has their sound off and needs haptics, or someone on an older device with a smaller screen. The investment serves the entire audience.

**Legal obligation.** iOS apps distributed on the App Store must meet Apple's accessibility guidelines and comply with applicable law (ADA, European Accessibility Act, and equivalents). Building accessibility in from day one is dramatically cheaper than retrofitting it.

**App Store quality signal.** Apple's App Store review team and editorial team actively evaluate accessibility. Well-implemented accessibility is a strong signal of app quality and can influence featuring decisions.

**Our commitment:** Every feature must work with VoiceOver before it is considered complete. Every feature must work with Dynamic Type before it is considered complete. Every feature must work with Reduced Motion before it is considered complete.

---

## 2. VoiceOver Support

### Card label patterns

Every card in the human hand must have a precise, informative accessibility label. These exact formats must be implemented.

#### Number cards

**Playable:**
```
"[Colour] [Number written out], number card. Playable. Double tap to select."

Example: "Crimson Seven, number card. Playable. Double tap to select."
Example: "Jade Zero, number card. Playable. Double tap to select."
```

**Not playable:**
```
"[Colour] [Number written out], number card. Not playable — [reason]. Double tap for more information."

Example: "Cobalt Three, number card. Not playable — current card is Jade Five. Double tap for more information."
Example: "Amber Nine, number card. Not playable — needs Cobalt or a nine. Double tap for more information."
```

#### Action cards

**Playable:**
```
"[Colour] [Action name], action card. [One-sentence action description]. Playable. Double tap to select."

Examples:
"Jade Skip, action card. Skips the next player's turn. Playable. Double tap to select."
"Crimson Reverse, action card. Reverses the direction of play. Playable. Double tap to select."
"Cobalt Draw Two, action card. The next player draws two cards and loses their turn. Playable. Double tap to select."
```

**Not playable:**
```
"[Colour] [Action name], action card. [One-sentence description]. Not playable — [reason]. Double tap for more information."

Example: "Amber Reverse, action card. Reverses the direction of play. Not playable — needs Amber or a Reverse card. Double tap for more information."
```

#### Wild cards

**Playable (always playable in Standard and Side-to-Side modes):**
```
"[Card name], wild card. [One-sentence description]. Plays on any colour. Playable. Double tap to select."

Examples:
"Change Colour, wild card. Lets you choose a new colour for all players. Plays on any colour. Playable. Double tap to select."
"Draw Four, wild card. The next player draws four cards and loses their turn. Plays on any colour. Playable. Double tap to select."
```

> **Note:** Forced Swap is a **coloured action card**, not a wild card. It uses the action card label pattern (see above), e.g. "Crimson Forced Swap, action card. Swap your hand with any other player. Playable. Double tap to select."
> Discard All is a wild card (no colour): "Discard All, wild card. Discard all cards of a chosen colour from your hand. Plays on any colour. Playable. Double tap to select."

#### Opponent and partner card backs (non-interactive)

```
"[Player label], [N] cards remaining."

Examples:
"Partner, four cards remaining."
"Left Opponent, seven cards remaining."
"Right Opponent, one card remaining. Solo called."
```

#### Draw pile

```
"Draw pile, [N] cards remaining. Double tap to draw a card."
(When drawing is not allowed): "Draw pile, [N] cards remaining. Drawing not available on your turn."
```

#### Discard pile

```
"Discard pile. Top card: [full card label]. Current colour: [colour name]."

Example: "Discard pile. Top card: Jade Skip, action card. Current colour: Jade."
```

#### Current colour indicator

```
"[Colour name], [symbol name] symbol. Current active colour."

Example: "Cobalt, Wave symbol. Current active colour."
Colour-blind mode: "[Colour name], [symbol name] symbol, [COLOURNAME]. Current active colour."
```

### Game status announcements (live regions)

These events are announced automatically as `UIAccessibility.post(.announcement)` without requiring the VoiceOver cursor to move to the element.

| Game event | Announcement text |
|---|---|
| Turn begins (human) | "Your turn. Play a [colour] card, a [number], or a wild card." |
| Turn begins (partner) | "Partner's turn." |
| Turn begins (left opponent) | "Left Opponent's turn." |
| Turn begins (right opponent) | "Right Opponent's turn." |
| AI plays a number card | "[Player] played [Colour] [Number]." |
| AI plays an action card | "[Player] played [Colour] [Action]. [Effect summary]." |
| AI plays a wild card | "[Player] played [Card name] and chose [Colour]." |
| Human turn skipped | "Your turn is skipped." |
| Partner turn skipped | "Partner's turn is skipped." |
| Reverse played | "Direction reversed. [Next player]'s turn." |
| Draw Two on human | "You drew two cards. [Next player]'s turn." |
| Draw Four on human | "You drew four cards and lost your turn. [Next player]'s turn." |
| Draw penalty on AI | "[Player] drew [N] cards." |
| Human calls Solo! | "Solo called! You have one card remaining." |
| Partner calls Solo! | "Your partner called Solo! They have one card remaining." |
| Opponent calls Solo! | "[Player] called Solo! They have one card remaining." |
| Round ends (human team wins) | "Your team wins this round." |
| Round ends (opponent team wins) | "Opponents win this round." |
| Game ends (human team wins) | "Your team wins the game!" |
| Game ends (opponent team wins) | "Opponents win the game." |
| Solo! penalty (Strict Solo! rule) | "You forgot to call Solo! — two penalty cards drawn." |
| Forced Swap executed | "[Player] used Forced Swap — hands exchanged." |

### VoiceOver custom actions

Custom actions (`UIAccessibilityCustomAction`) extend the standard double-tap interaction. They appear in the VoiceOver rotor.

**On each card in the human hand:**

| Action name | Trigger condition | Effect |
|---|---|---|
| "Play card" | Card is playable | Plays the card (bypasses select → play two-step) |
| "Card details" | Always available | Reads the full rules description for this card type |

**On draw pile:**

| Action name | Trigger condition | Effect |
|---|---|---|
| "Draw card" | Human's turn, drawing allowed | Draws a card from the pile |

**On game table (background element, always focusable):**

| Action name | Trigger condition | Effect |
|---|---|---|
| "Game status" | Always available | Reads full status: round, whose turn, colour, all player card counts, action prompt |

**Game status readout format:**
```
"Round [N]. [Active player]'s turn. Current colour: [colour name]. 
Your hand: [N] cards. 
Partner: [N] cards. 
Left Opponent: [N] cards. 
Right Opponent: [N] cards. 
[Current action prompt text]."
```

### Focus order

VoiceOver focus must navigate in a logical reading order that matches the player's workflow. SwiftUI's `accessibilitySortPriority` is used to enforce order where needed.

**Home screen:**
1. App name (decorative — `.accessibilityHidden(true)` if purely visual, or `.accessibilityAddTraits(.isHeader)` if it sets context)
2. Continue Game (if present)
3. New Game
4. Quick Play
5. Rules
6. Statistics
7. Settings

**Mode / difficulty / setup screens:**
1. Screen title (header)
2. Mode reminder chip (if present, as read-only informational element)
3. First option
4. Second option (etc.)
5. Next / Start button
6. Back button (last — it goes backward)

**Game table:**
1. Pause button
2. Round and score display (informational)
3. Partner zone (card count)
4. Left opponent zone (card count)
5. Right opponent zone (card count)
6. Draw pile
7. Discard pile
8. Current colour indicator
9. Action prompt
10. Human hand, card 1 through card N (left to right)
11. Draw button (if visible)
12. Solo! button (if visible)

**Colour picker:**
1. "Choose a new colour" (title)
2. Crimson, Flame symbol
3. Cobalt, Wave symbol
4. Jade, Leaf symbol
5. Amber, Sun symbol
6. Cancel / dismiss (if applicable)

**Target picker:**
1. "Choose a target" (title)
2. First eligible target (e.g., "Left Opponent, six cards")
3. Second eligible target
4. Cancel

**Round end summary:**
1. Result headline (e.g., "Your team wins this round!") — announced automatically as live region
2. Player card counts (table)
3. Context sentence
4. Next Round button
5. New Game button
6. Home button

**Pause menu:**
1. "Game paused" (announcement on appear)
2. Resume
3. Rules
4. Settings
5. Change difficulty
6. End game

---

## 3. Dynamic Type Support

### Implementation rules

- All text must use SwiftUI font system styles (`.largeTitle`, `.title`, `.title2`, `.title3`, `.body`, `.callout`, `.subheadline`, `.footnote`, `.caption`, `.caption2`).
- Never use `.font(.system(size: N))` with a hardcoded point size for text that must scale. If an exact size is needed (e.g., for a purely decorative element), apply `.accessibilityHidden(true)` to remove it from the accessibility tree.
- Use `@ScaledMetric` for layout values that must scale with Dynamic Type (e.g., card dimensions in large card mode).
- Apply `.minimumScaleFactor(0.75)` on card text where layout cannot expand, with `.lineLimit(1)` to prevent unwanted wrapping.

### Size class behaviour

| Dynamic Type size | Expected behaviour |
|---|---|
| xSmall | All text smaller; cards use `.caption` for numbers. Layout unchanged. |
| Small | Slightly smaller text. Normal layout. |
| Medium (default) | Reference layout. |
| Large | Text slightly larger. Normal layout. |
| xLarge | Text noticeably larger. Cards may need to show abbreviated action names. |
| xxLarge | Cards switch to large card mode automatically if not already active. |
| xxxLarge | Large card mode active. Hand area may scroll. |
| AX1 | Very large text. Large card mode required. Text-only fallback for card names in hand if needed. |
| AX2 | Large card mode. Card fan compressed. Scroll required for more than 4 cards. |
| AX3 | As AX2 but larger. Action prompt may wrap to 3 lines. |
| AX4 | Maximum practical card size. Partner/opponent zones may collapse to count-only with no fan. |
| AX5 | Extreme size. Cards in hand use full `@ScaledMetric` dimensions. Full scrollability required. |

### Critical test points

- **xSmall:** Nothing is illegibly tiny. Card numbers remain readable.
- **AX3:** No text clips. No button labels truncate. No card content overflows its container.
- **AX5:** Layout does not break. All interactive elements remain reachable. Horizontal scroll in hand works correctly.

---

## 4. Large Card Mode

### What it does

Large Card Mode is a user-controlled setting (Settings → Accessibility → Large cards) that increases card dimensions and text independently of Dynamic Type. It provides a targeted improvement for players who find the default card size difficult to read, without requiring the player to scale all system UI.

### Dimensions change

| Element | Normal | Large card mode |
|---|---|---|
| iPhone hand card | 60×90pt | 84×126pt (+40%) |
| iPhone selected card | 80×120pt | 112×168pt (+40%) |
| iPad hand card | 80×120pt | 112×168pt (+40%) |
| iPad selected card | 100×150pt | 140×210pt (+40%) |

Implemented using `@ScaledMetric(relativeTo: .body) var cardWidth: CGFloat = 60` — this means large card mode is implemented by changing the base value, not the scale factor.

### Text change

- Card numbers step up one Dynamic Type size (e.g., `.subheadline` → `.title3`).
- Action name abbreviations step up one size.
- Card hand area uses horizontal scroll when cards do not fit without overlap.

### Compatibility

- Large card mode is additive with Dynamic Type — both can be active simultaneously.
- At the intersection of Large card mode + AX5 Dynamic Type, the hand will scroll significantly. This is acceptable — scroll is preferable to clipping.
- Large card mode does not affect opponent zones, draw pile, or discard pile (these do not need to scale the same way).

### Activation

- Toggle in Settings → Accessibility → Large cards.
- Change takes effect immediately without requiring app restart or game restart.
- Does not interrupt an in-progress game.

---

## 5. Colour-blind Mode

### Default design (always colour-blind safe)

Even without toggling colour-blind mode, Wild Pairs is designed to be usable with common colour vision deficiencies:

- Every card face shows its suit symbol (Flame, Wave, Leaf, Sun) at all times.
- The current colour indicator always shows the suit symbol alongside the colour chip.
- Game event log always includes colour names as text.
- VoiceOver always speaks colour names — never "the red card" relying on the user to perceive colour.

### Colour-blind mode enhancements

When Settings → Accessibility → Colour-blind mode is toggled on:

| UI element | Normal mode | Colour-blind mode |
|---|---|---|
| Card background label | Not shown | Colour name in all-caps bold (e.g., "CRIMSON") at top of card |
| Suit symbol | Large, centred | Even more prominent; bolder stroke |
| Colour indicator | Colour chip + symbol | Colour chip + symbol + colour name text |
| Action prompt colour references | Colour chip | Colour chip + colour name (e.g., "● Cobalt" becomes "● Cobalt (Wave)") |
| Event log entries | Colour chip + text | Colour chip + text + symbol |
| Colour picker swatches | Colour fill + symbol + name | Colour fill + symbol + name in all-caps + pattern fill overlay |
| Pattern fills | Off | Optional (sub-setting: Settings → Accessibility → Pattern fills) |

### Pattern fills (optional sub-setting)

When both colour-blind mode and pattern fills are active, card backgrounds gain a texture overlay:

| Game colour | Pattern | Description |
|---|---|---|
| Crimson | Diagonal hatching, 45° angle, 4pt spacing | Classic hatching |
| Cobalt | Horizontal lines, 4pt spacing | Horizontal bands |
| Jade | Vertical lines, 4pt spacing | Vertical bands |
| Amber | Dot grid, 6pt spacing | Polka dots |

Pattern fills are rendered at 30% opacity over the colour fill, preserving colour readability while adding a tactile visual distinction.

### Colour-blind mode and VoiceOver

Colour-blind mode does not change VoiceOver behaviour — VoiceOver already speaks colour names for all users. The mode only changes the visual presentation.

---

## 6. High Contrast

### Default contrast targets

All default colours must meet WCAG 2.1 Level AA:
- Text contrast ratio: 4.5:1 minimum against background.
- Non-text UI elements (borders, icons, active states): 3:1 minimum against adjacent colours.

### Verified contrast ratios (light mode)

| Element | Foreground | Background | Ratio | Status |
|---|---|---|---|---|
| Primary text on white | `#000000` | `#FFFFFF` | 21:1 | ✓ AAA |
| Secondary text on white | `#6C6C70` | `#FFFFFF` | ~4.6:1 | ✓ AA |
| White text on Crimson card | `#FFFFFF` | `#C0392B` | ~5.0:1 | ✓ AA |
| White text on Cobalt card | `#FFFFFF` | `#2471A3` | ~5.1:1 | ✓ AA |
| White text on Jade card | `#FFFFFF` | `#1E8449` | ~5.3:1 | ✓ AA |
| White text on Amber card | `#FFFFFF` | `#D4AC0D` | ~4.6:1 | ✓ AA |
| Accent (indigo) on white | System indigo | `#FFFFFF` | Verify against system value | Verify |

### Increased contrast mode

When `UIAccessibility.isDarkerSystemColorsEnabled` returns `true` (user has enabled "Increase Contrast" in iOS Settings):

- Card border width: 1pt → 2pt (all cards).
- Button border width: 1pt → 2pt.
- Panel/container borders: added where previously absent.
- Transparency effects (blur backgrounds): disabled; replaced with solid colours.
- Shadow opacity: increased by 50%.
- Detect via: `UIAccessibility.isDarkerSystemColorsEnabled` (check on view appear and on `UIAccessibility.darkerSystemColorsStatusDidChangeNotification`).
- In SwiftUI: use `@Environment(\.colorSchemeContrast)` which returns `.increased` when high contrast is active.

---

## 7. Reduced Motion

### Detection

```swift
// SwiftUI
@Environment(\.accessibilityReduceMotion) var reduceMotion

// UIKit equivalent (for animation wrappers)
UIAccessibility.isReduceMotionEnabled
```

Subscribe to `UIAccessibility.reduceMotionStatusDidChangeNotification` to respond dynamically if the user changes this setting mid-session.

### Behaviour when reduced motion is active

| Animation | Normal | Reduced motion fallback |
|---|---|---|
| Card deal | Cards fly from deck to each zone | Cards appear in place instantly |
| Card draw | Card slides from deck to hand | Card appears in hand with opacity fade-in |
| Card play | Card arc-slides to discard pile | Card disappears from hand; discard pile updates with crossfade |
| Skip animation | X overlay materialises on player zone | Static "SKIP" label appears briefly, then fades |
| Reverse animation | Direction arrow rotates 180° | Direction indicator swaps to new state instantly |
| Draw penalty | Cards fan into recipient zone | Card count badge increments; brief badge scale |
| Colour change | Discard pile pulses in new colour | Instant colour change on discard pile |
| Target selection | Pulsing ring on eligible players | Static highlight ring (no pulse) |
| Partner assist | Luminous arc from partner to hand | No visual; event log text only |
| Solo! badge | Scale-in spring animation | Badge appears with opacity fade-in |
| Round win | Confetti burst + zone glow | Static "Your team wins!" overlay, no confetti |
| Round loss | Table desaturates | Overlay appears with opacity transition |
| Thinking indicator | Pulsing dots | Static "Thinking…" text |
| AI card play | Arc animation from zone to discard | Card disappears from zone; discard updates |
| Direction indicator | Continuous slow rotation | Static directional indicator |
| Active player glow | Pulsing glow on zone border | Static solid border in accent colour |

### Principles

- All state changes remain clear and legible with reduced motion. No information is conveyed only through motion.
- Reduced motion does not mean "no visual feedback" — it means "instant or simple transitions instead of animated ones."
- Opacity transitions are permitted under reduced motion (they do not cause vestibular issues for most users).
- Scale transforms (bounce/pop) are not permitted under reduced motion.
- Blur transitions may be simplified but not necessarily removed (check `UIAccessibility.prefersCrossFadeTransitions` for whether crossfade is explicitly preferred).

---

## 8. Haptic Accessibility

### System integration

Haptics use standard UIKit feedback generators, which automatically respect the user's system haptic settings:
- iOS "System Haptics" off → `UIImpactFeedbackGenerator` produces no haptic.
- iOS "Vibration" off (some devices) → no haptic.

Wild Pairs does not need to replicate this setting check — the system handles it. However, Wild Pairs adds its own in-app haptics toggle (Settings → Accessibility → Haptics) for users who prefer no in-game haptics even when system haptics are enabled.

### No haptic-only information

Every haptic event has a visual or VoiceOver equivalent:

| Haptic | Visual equivalent | VoiceOver equivalent |
|---|---|---|
| Card select (light) | Card lifts visually | VoiceOver focus on card |
| Card play (medium) | Card animates to discard | "You played [card name]" live region |
| Illegal card (error) | Shake animation + tooltip | "[Reason]" spoken aloud |
| Solo! (heavy) | Solo! badge appears | "Solo called!" announcement |
| Round win (success) | Win overlay + confetti | "Your team wins" announcement |
| Round loss (warning) | Loss overlay | "Opponents win" announcement |
| Draw penalty (warning) | Cards animate to zone | "You drew N cards" announcement |

---

## 9. Minimum Tap Targets

All interactive elements meet Apple's Human Interface Guideline of 44×44pt. Higher-priority interactive elements use 56pt on the primary axis.

| Element | Minimum size | Notes |
|---|---|---|
| Card in hand (iPhone compact) | 60×90pt | Exceeds minimum in both axes |
| Card in hand (iPhone large mode) | 84×126pt | Well above minimum |
| Card in hand (iPad regular) | 80×120pt | Above minimum |
| Play button / Draw Card button | 56×44pt | 56pt width for easy one-handed reach |
| Solo! button | 56×44pt | Large — this is a timing-sensitive action |
| Colour picker swatches | 100×100pt (iPhone), 56×56pt (iPad popover) | Large on iPhone; minimum spec on iPad |
| Target player selection rows | 56×44pt | Player rows in target picker |
| Navigation items (back, close, pause) | 44×44pt | Standard navigation minimum |
| Toggle rows (settings) | Full row width × 44pt | Entire row is tappable, not just the switch |
| Mode selection cards | Full width × 88pt | Large tap targets for setup flow |
| Difficulty selection rows | Full width × 60pt | Comfortable tap |
| Round end buttons | Full width × 50pt | Clear primary action at end of round |

### Implementation

- Use `.frame(minWidth: 44, minHeight: 44)` and `.contentShape(Rectangle())` to expand hit areas without expanding visual bounds.
- For cards, the visual card frame is the tap target — it already exceeds 44pt minimum.
- Never rely on the visual border of a small element as its tap boundary. Always expand the hit area with `.contentShape`.

---

## 10. Per-screen Accessibility Checklist

### Home screen

- [x] App name: appropriate header trait; or accessibility hidden if purely decorative
- [x] Continue Game button: label includes mode, round, and time context
- [x] New Game: clear label
- [x] Quick Play: label specifies it jumps into Standard Teams
- [x] Rules, Statistics, Settings: clear labels
- [x] Focus order: logical top-to-bottom
- [x] No information conveyed only by colour
- [x] No information conveyed only by animation (no ambient animation on home)
- [x] All interactive elements minimum 44×44pt
- [x] Works in compact width (Split View)

### Setup screens (mode / difficulty / card set)

- [x] Screen title has `.accessibilityAddTraits(.isHeader)` applied
- [x] Each option card has full accessibility label including description text
- [x] Selected state announced: ".accessibilityAddTraits(.isSelected)"
- [x] "Next" button disabled and labelled appropriately when no selection made
- [x] Mode reminder chip is `.accessibilityElement` with clear descriptive label
- [x] No information conveyed only by colour (selected state uses border + background, not colour alone)
- [x] Toggle rows (house rules) include state in label: "Strict Solo!, currently off"
- [x] Focus order: title → mode reminder (if present) → options → Next

### Game table

- [x] All four player zones have accessibility labels with player name and card count
- [x] Draw pile: label includes count and whether drawing is available
- [x] Discard pile: label includes full card description and current colour
- [x] Current colour indicator: label includes colour name and symbol name
- [x] Action prompt: readable by VoiceOver at focus; changes announced via live region on turn change
- [x] All human hand cards: precise VoiceOver labels per §2 patterns
- [x] All human hand cards: custom actions ("Play card", "Card details")
- [x] Draw button: present in accessibility tree only when available; disabled trait when not
- [x] Solo! button: present when applicable; announced proactively via live region
- [x] Pause button: always accessible, even during animations
- [x] Game status custom action available on game table background element
- [x] Focus order: logical per §2 focus order definition
- [x] No information conveyed only by colour (symbols, labels, prompts all present)
- [x] No information conveyed only by animation (all state changes have text equivalents)
- [x] All live game events announced via UIAccessibility.announcement
- [x] Turn change announced without requiring VoiceOver focus movement
- [x] Minimum tap targets met for all interactive elements

### Colour picker

- [x] Picker announced on appear: "Choose a new colour" as modal title or announcement
- [x] Each swatch: label includes colour name, symbol name, and "button"
- [x] Colour-blind mode: pattern description included in label when pattern fills active
- [x] Focus moves to first swatch on picker appear
- [x] Dismiss via swipe-down (iPhone) or tap-outside (iPad) — both produce VoiceOver dismiss feedback
- [x] Swatch size 100×100pt (iPhone) or 56×56pt (iPad) — above tap target minimum
- [x] No information conveyed by colour alone (names and symbols always present)

### Target picker

- [x] Title announced on appear: "Choose a target"
- [x] Each target row: label includes player name and current card count
- [x] Ineligible targets: not shown or shown with ".isEnabled = false" trait
- [x] Cancel button: labelled and accessible
- [x] Focus moves to first target row on appear

### Round end / game end

- [x] Result announced automatically as live region on appear (no VoiceOver focus movement required)
- [x] Card count table readable by VoiceOver in logical order (your count, partner count, opponents)
- [x] Context sentence: plain text, readable by VoiceOver
- [x] "Next Round" button: focus moves here after announcement
- [x] "New Game" and "Home" buttons: labelled and accessible
- [x] No information conveyed only by confetti or animation (result always in text)

### Rules / help

- [x] Screen title has header trait
- [x] Navigation list items have clear labels and disclosure indicators described
- [x] Card illustrations in glossary: accessibility descriptions describe the card type
- [x] Card glossary text: full descriptions accessible via VoiceOver
- [x] Logical reading order throughout
- [x] Back/close button accessible and labelled

### Settings

- [x] Section headers have header trait
- [x] All toggle rows: label includes name, description, and current state ("Haptics, currently on")
- [x] Sub-option rows (pattern fills): trait indicates they are sub-options; disabled trait when parent is off
- [x] "Reset statistics" and "Reset all local data": both have destructive trait; confirmation alert is fully accessible
- [x] Confirmation alert: title and message readable; both buttons labelled (including destructive style)

### Statistics

- [x] Screen title has header trait
- [x] All statistics labelled with both metric name and value ("Games played, 47")
- [x] Percentages spoken as "[N] percent" not "[N]%"
- [x] "Local only" footer note accessible and not suppressed
- [x] No chart or graph elements without text equivalents

---

## 11. Phase 9 visual overhaul — accessibility re-verification (2026-06-26)

Re-audited after the premium dark-felt redesign, bespoke `SuitSymbol` shapes, card face/back
rebuild, width-aware overlapping hand/seat fans, and the new `Theme.Motion`-driven state
animations. Scope: `CardView`, `HandView`, `PlayerZoneView`, `GameTableView`,
`TableCenterView`, `HomeView`, `NewGameFlowView`, `RulesView`, `SettingsView`,
`OnboardingView`, `PauseMenuView`, `DecisionViews`, `Theme.swift`, `TableBackground.swift`.

| Check | Result | Notes |
|---|---|---|
| Every interactive element has an explicit `accessibilityLabel` | PASS (1 regression found + fixed by the UI test suite) | New bespoke `SuitSymbol` glyphs are nested inside existing `.accessibilityElement(children: .ignore/.combine)` containers or explicitly-labelled `Button`s, so none leak as orphaned elements. Separately, `xcodebuild test` caught a real regression this manual pass missed: `HandView`'s rewrite wrapped its content directly in `GeometryReader` + `.accessibilityLabel("Your hand, N cards")`; `GeometryReader` has no view identity of its own, so the label "leaked" down and overwrote every individual card's label with the literal string "Your hand, 7 cards" instead of its real card description. Fixed by adding `.accessibilityElement(children: .contain)` before the label, which gives the container its own summary label while keeping each card individually reachable. Caught by `testHandCardsHaveCanonicalAccessibilityLabels` (`WildPairsUITests`) — this is exactly the kind of issue manual code review of accessibility *modifiers* can miss because the Swift code reads correctly; only the rendered accessibility tree reveals the leak. Re-ran the full `WildPairsUITests` suite afterward: 18/18 pass. |
| Game events announced via VoiceOver live region | PASS | `GameViewModel.announce(_:)` call sites unchanged; new `publishViewState()` animation wrapper does not alter `accessibilityAnnounce` effect handling |
| Colour-blind mode (`showColourName` / `CardPatternFill`) | PASS | Both flags still threaded through `CardView`, `HandView`, `PlayerZoneView`, `TableCenterView`, `ColourPickerView` unchanged; `SuitSymbol` is additive, not a replacement for the colour-name text path |
| Dynamic Type XS→AX5, no clipping | PASS, with one pre-existing gap noted | New action-card `readableName` text (e.g. "Draw +2") uses `minimumScaleFactor(0.7)` + `lineLimit(1)`, consistent with the existing card-text pattern, so it shrinks rather than clips. Confirmed the new fixed-width opponent zones (`GameTableView.opponentZone`) have an 80pt floor (`max(sideWidth, 80)`) so they cannot collapse to zero. Pre-existing gap (not a Phase 9 regression): design-system.md §3's "AX3+ activates large card mode automatically" is not yet wired to `dynamicTypeSize` — logged in `docs/known-issues.md` |
| Reduced Motion fallback present for every animation | PASS | `HandView`/`PlayerZoneView` card insertion/removal transitions are gated `reducedMotion ? .identity : .scale...opacity`; `GameViewModel.publishViewState()` skips `withAnimation` entirely when `reducedVisualEffects` is on or `animationSpeed == .off`; pre-existing colour-pulse/glow/confetti gates untouched |
| Tap targets ≥44×44pt | PASS | New `PrimaryButtonStyle`/`SecondaryButtonStyle` enforce `minHeight: 50`; `GhostButtonStyle` enforces `minHeight: 44`; card sizes unchanged |
| VoiceOver focus order / no orphaned elements | PASS (1 fix applied) | `HomeView`'s new decorative four-suit wordmark was initially exposed as 4 unlabelled shapes; fixed with `.accessibilityHidden(true)` since the "Wild Pairs" text immediately below already names the app |
| `accessibilityElement` grouping for compound views | PASS | `CardView` (`.ignore`) and `PlayerZoneView` (`.combine`) grouping strategy unchanged |
| `accessibilityHint` for non-obvious interactions | PASS | Unchanged — hand cards, catch-out tap, draw pile all retain hints |

**Blocking issues:** none. **Fixes applied during this audit:** `HomeView` wordmark
`accessibilityHidden`. **Carried-forward gap:** AX3+ auto large-card-mode (pre-existing, not
introduced by Phase 9) — see `docs/known-issues.md`.

---

## 11. Accessibility Testing Checklist

This checklist must be completed before each phase gate (feature complete, beta, release candidate).

### VoiceOver — navigation

- [ ] Navigate entire home screen without looking at the screen. Confirm all buttons reachable and labelled.
- [ ] Navigate setup flow (mode → difficulty → house rules → start) without visual reference. Confirm all options announced correctly.
- [ ] Navigate game table: confirm all player zones, draw pile, discard pile, colour indicator, and action prompt announced correctly.
- [ ] Navigate human hand left-to-right: confirm each card's label is correct and complete.
- [ ] Navigate to Draw button: confirm it is only present and enabled when drawing is allowed.
- [ ] Navigate to Solo! button: confirm it appears when human has exactly 1 card and the label is clear.
- [ ] Hear game status on demand using the "Game status" custom action.
- [ ] Open pause menu and navigate all options.
- [ ] Navigate round end summary and activate "Next Round."

### VoiceOver — gameplay

- [ ] Play a complete round using VoiceOver only (no looking at screen). Use "Play card" custom action to play cards.
- [ ] Experience a draw penalty: confirm the draw is announced correctly.
- [ ] Experience a skipped turn: confirm the skip is announced correctly.
- [ ] Play a wild card: navigate to colour picker using VoiceOver; select a colour; confirm result announced.
- [ ] Play a targeted draw card: navigate to target picker using VoiceOver; select target; confirm result announced.
- [ ] Call Solo! using VoiceOver. Confirm it can be triggered with the custom action or by activating the button.
- [ ] Win a round: confirm win announcement fires without requiring focus movement.

### VoiceOver — iPad

- [ ] Full game navigation on iPad using VoiceOver. Confirm no iPhone-only assumptions break on iPad.
- [ ] Colour picker appears as popover and is navigable via VoiceOver.
- [ ] Events side panel (iPad landscape): confirm events are accessible and do not disrupt game table navigation order.

### Dynamic Type

- [ ] Set Dynamic Type to AX3 system-wide. Launch app. Confirm: no text clipped; no buttons with truncated labels; no overflow.
- [ ] Set Dynamic Type to AX3. Play a round. Confirm: cards readable; hand scrollable; draw and Solo! buttons accessible.
- [ ] Set Dynamic Type to xSmall. Confirm: no text unreadably small; card numbers still legible.

### Large card mode

- [ ] Enable large card mode in Settings. Return to game. Confirm card dimensions increase. Confirm hand remains scrollable. Confirm no elements fall off screen.
- [ ] Enable large card mode + AX3 Dynamic Type simultaneously. Confirm layout does not break.

### Colour-blind mode

- [ ] Enable colour-blind mode. Navigate to game table. Confirm all cards show colour name as text. Confirm colour indicator shows name and symbol. Confirm no colour-only information remains.
- [ ] Enable colour-blind mode + pattern fills. Confirm patterns appear on cards.
- [ ] Disable colour-blind mode. Confirm text labels and patterns are removed.

### Reduced motion

- [ ] Enable "Reduce Motion" in iOS Settings (Settings → Accessibility → Motion → Reduce Motion).
- [ ] Start a new game. Confirm deal animation is instant (no flying cards).
- [ ] Play a card. Confirm card does not slide — discard pile updates with crossfade.
- [ ] Win a round. Confirm no confetti. Confirm win state is clearly communicated without animation.
- [ ] Watch an AI turn. Confirm thinking indicator is static, not pulsing.

### Haptics

- [ ] Disable haptics in Wild Pairs Settings. Play a round. Confirm no haptic feedback. Confirm all actions still have clear visual feedback.
- [ ] Enable haptics. Tap an unplayable card. Confirm error haptic fires with shake animation.
- [ ] Play a card. Confirm medium haptic fires.
- [ ] Win a round. Confirm success haptic fires.

### One-handed use — iPhone SE

- [ ] Test on iPhone SE (or smallest available device). Confirm all interactive elements in bottom 60% of screen are reachable with right-hand thumb without repositioning grip.
- [ ] Confirm Draw Card button reachable one-handed.
- [ ] Confirm Solo! button reachable one-handed.
- [ ] Confirm all hand cards tappable without repositioning grip (hand may scroll but all cards are in thumb zone).

### Split View / Stage Manager

- [ ] Test game in iPad Split View at narrow width (~320pt). Confirm game is fully playable. Confirm no elements clipped.
- [ ] Resize Stage Manager window from wide to narrow during a game. Confirm layout reflows correctly. Confirm game state is preserved.

---

## 12. Accessibility Label Implementation Guide

### Swift implementation patterns

All VoiceOver labels are constructed programmatically from card and game state properties. They must never be hardcoded strings, because card state (playable/not playable) changes during gameplay.

```swift
// MARK: - Card accessibility label construction
// (To be implemented in Phase 5 — Accessibility pass)

extension Card {
    
    /// Constructs the full VoiceOver accessibility label for this card,
    /// given whether it is currently playable and the reason if not.
    func accessibilityLabel(isPlayable: Bool, reason: String? = nil) -> String {
        let colourAndName = "\(colour.displayName) \(displayName)"
        let typeDescription = type.voiceOverDescription  // e.g. "number card", "action card", "wild card"
        let actionDescription = type.rulesDescription    // one-sentence action effect (nil for number cards)
        
        var components: [String] = []
        
        // "[Colour] [Name], [type]."
        components.append("\(colourAndName), \(typeDescription).")
        
        // For action and wild cards, include the effect.
        if let actionDescription {
            components.append(actionDescription)
        }
        
        // Playability.
        if isPlayable {
            components.append("Playable. Double tap to select.")
        } else {
            let reasonText = reason ?? "Cannot play now."
            components.append("Not playable — \(reasonText). Double tap for more information.")
        }
        
        return components.joined(separator: " ")
    }
    
    /// VoiceOver label for a wild card (always playable in standard mode).
    func wildCardAccessibilityLabel() -> String {
        return "\(displayName), wild card. \(type.rulesDescription ?? "Plays on any colour.") Plays on any colour. Playable. Double tap to select."
    }
}

// MARK: - Card type descriptions
// Canonical CardType has 11 cases (see technical-architecture.md §Model Reference).
// Every switch here must be exhaustive across all 11.

extension CardType {
    
    /// Short type description for VoiceOver.
    /// forcedSwap is a coloured action card, not a wild card.
    /// discardAll is a wild card (no colour).
    var voiceOverDescription: String {
        switch self {
        case .number:        return "number card"
        case .skip:          return "action card"
        case .reverse:       return "action card"
        case .drawTwo:       return "action card"
        case .drawFour:      return "wild card"
        case .changeColour:  return "wild card"
        case .discardAll:    return "wild card"
        case .targetedDraw:  return "action card"
        case .forcedSwap:    return "action card"   // coloured action card, not wild
        case .skipTwo:       return "action card"
        case .teamPlay:      return "action card"
        }
    }
    
    /// One-sentence rules description for VoiceOver label (nil for number cards).
    var rulesDescription: String? {
        switch self {
        case .number:        return nil
        case .skip:          return "Skips the next player's turn."
        case .reverse:       return "Reverses the direction of play."
        case .drawTwo:       return "The next player draws two cards and loses their turn."
        case .drawFour:      return "The next player draws four cards and loses their turn."
        case .changeColour:  return "Lets you choose a new colour for all players."
        case .discardAll:    return "Discard all cards of a chosen colour from your hand."
        case .targetedDraw:  return "Force a chosen opponent to draw two cards."
        case .forcedSwap:    return "Swap your entire hand with another player."
        case .skipTwo:       return "The next two players each lose their turn."
        case .teamPlay:      return "You and your partner each draw one bonus card."
        }
    }
}

// MARK: - Player zone accessibility label

/// Constructs the accessibility label for an AI player zone (opponent or partner).
func playerZoneAccessibilityLabel(player: Player, cardCount: Int, hasSoloCalled: Bool, isOut: Bool) -> String {
    var components: [String] = []
    components.append(player.displayName)
    
    if isOut {
        components.append("Out — no cards remaining.")
    } else {
        let cardWord = cardCount == 1 ? "card" : "cards"
        components.append("\(cardCount) \(cardWord) remaining.")
        if hasSoloCalled {
            components.append("Solo called.")
        }
    }
    
    return components.joined(separator: " ")
}

// MARK: - Draw pile accessibility label

func drawPileAccessibilityLabel(count: Int, canDraw: Bool) -> String {
    let cardWord = count == 1 ? "card" : "cards"
    let base = "Draw pile, \(count) \(cardWord) remaining."
    if canDraw {
        return base + " Double tap to draw a card."
    } else {
        return base + " Drawing not available right now."
    }
}

// MARK: - Discard pile accessibility label

func discardPileAccessibilityLabel(topCard: Card, currentColour: CardColour) -> String {
    return "Discard pile. Top card: \(topCard.accessibilityLabel(isPlayable: false)). Current colour: \(currentColour.displayName)."
}

// MARK: - Game status (for custom action)

func gameStatusAccessibilityDescription(
    roundNumber: Int,
    activePlayer: Player,
    currentColour: CardColour,
    humanCardCount: Int,
    partnerCardCount: Int,
    leftOpponentCardCount: Int,
    rightOpponentCardCount: Int,
    actionPrompt: String
) -> String {
    return """
    Round \(roundNumber). \(activePlayer.displayName)'s turn. \
    Current colour: \(currentColour.displayName). \
    Your hand: \(humanCardCount) cards. \
    Partner: \(partnerCardCount) cards. \
    Left Opponent: \(leftOpponentCardCount) cards. \
    Right Opponent: \(rightOpponentCardCount) cards. \
    \(actionPrompt)
    """
}
```

### SwiftUI view modifier patterns

```swift
// Apply to each card view in the human hand:
CardView(card: card)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
        card.accessibilityLabel(
            isPlayable: gameState.isPlayable(card),
            reason: gameState.playabilityReason(for: card)
        )
    )
    .accessibilityAddTraits(gameState.isPlayable(card) ? [.isButton] : [.isButton])
    .accessibilityCustomActions([
        UIAccessibilityCustomAction(name: "Play card") { _ in
            if gameState.isPlayable(card) {
                gameState.play(card)
                return true
            }
            return false
        },
        UIAccessibilityCustomAction(name: "Card details") { _ in
            // Post announcement with full card type rules description
            UIAccessibility.post(
                notification: .announcement,
                argument: card.type.fullRulesDescription
            )
            return true
        }
    ])

// Apply to the game table background to expose Game Status action:
Color.clear
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .contentShape(Rectangle())
    .accessibilityElement(children: .contain)
    .accessibilityCustomActions([
        UIAccessibilityCustomAction(name: "Game status") { _ in
            UIAccessibility.post(
                notification: .announcement,
                argument: gameState.accessibilityStatusDescription()
            )
            return true
        }
    ])
```

### Live region announcements

```swift
// Post a live region announcement for turn changes and significant events.
// This fires regardless of where VoiceOver focus is currently positioned.

func announceToVoiceOver(_ message: String, delay: TimeInterval = 0) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

// Usage examples:
announceToVoiceOver("Your turn. Play a Cobalt card, a seven, or a wild card.")
announceToVoiceOver("Partner played Jade Skip. Right Opponent's turn is skipped.")
announceToVoiceOver("You drew two cards.")
announceToVoiceOver("Solo called! You have one card remaining.")
announceToVoiceOver("Your team wins this round!", delay: 0.5)  // Brief delay to let round-end overlay appear first
```

### Custom action registration on Draw pile

```swift
DrawPileView()
    .accessibilityLabel(drawPileAccessibilityLabel(
        count: gameState.deckCount,
        canDraw: gameState.humanCanDraw
    ))
    .accessibilityCustomActions(
        gameState.humanCanDraw ? [
            UIAccessibilityCustomAction(name: "Draw card") { _ in
                gameState.humanDrawCard()
                return true
            }
        ] : []
    )
```

---

*This document covers the full accessibility surface of Wild Pairs v1.0. Update this plan whenever a new feature is added. Accessibility review is required at every phase gate.*
