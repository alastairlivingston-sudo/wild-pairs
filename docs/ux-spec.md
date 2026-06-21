# Wild Pairs — UX Specification

**Version:** 1.0  
**Status:** Draft  
**Audience:** iOS engineers, AI logic engineers, QA  
**Platform:** iOS 17+, SwiftUI, Universal (iPhone + iPad)  
**Last updated:** 2026-06-21

---

## 1. UX Vision

Wild Pairs must feel like the best card game you can play alone on your phone — one that respects your intelligence, rewards your attention, and never wastes your time.

### The emotional experience

| Quality | What it means in practice |
|---|---|
| **Fast** | Menus are one or two taps. AI turns never drag. The game responds the instant you touch it. |
| **Clear** | You always know whose turn it is, what colour is active, and exactly which cards you can play. |
| **Satisfying** | Playing a well-timed Skip or pulling off a come-from-behind win with your partner feels genuinely good. Feedback is immediate and proportionate. |
| **Strategic** | There are real decisions to make. Card choice matters. Watching your partner's count matters. |
| **Friendly** | The app talks to you like a helpful game-night host, not a system administrator or a legal disclaimer. |
| **Offline reliable** | Zero network dependency. Zero permission prompts. The game is there when you open it, every time. |
| **Light-hearted** | Bright game colours, gentle animations, celebratory moments. Never grim, never punishing. |
| **Low-friction** | Settings are discoverable but never in the way. The most common path (play a card) is always the easiest. |
| **Easy to resume** | A game interrupted by a phone call, a lock screen, or a long commute can be resumed instantly with full context. |
| **Premium** | Every pixel is intentional. It does not look or feel like a tutorial project. |

### What the app must NOT feel like

- **Cluttered:** No card game tropes crammed onto the screen for decoration. Every element earns its place.
- **Robotic:** AI opponents must feel like they are thinking, not executing a lookup table. State changes must be explained.
- **Confusing:** If a player is ever unsure what to do next, the design has failed.
- **Slow:** No artificial delays. No loading spinners that exist to mask nothing. No janky transitions.
- **Punishing:** Losing a round must never feel unfair or unexplained. "So close!" not "YOU LOSE."
- **Like a cheap clone:** No UNO visual language, no UNO terminology, no borrowed tropes that remind players of another product.

---

## 2. Experience Principles

These ten principles govern every design decision across every screen and every interaction.

### 1. One obvious primary action per state
Every game state has exactly one primary action that is visually dominant. On your turn: play a card or draw. When colour-picking: tap a colour. When the round ends: tap "Continue" or "New Game". Supporting actions exist but are visually subordinate.

### 2. Show only information needed now
The game table shows four player zones, deck, discard, and a prompt. It does not show card counts for all players unless the player glances at them. Scores, stats, and settings live outside the game table. Rules live in the pause menu. Anything that does not help you make your next decision is hidden or de-emphasised.

### 3. Make legal moves visually obvious
Playable cards have a visible affordance — a subtle lift and full opacity. The action prompt tells you exactly what matches. You should be able to play a correct card without reading anything, just by pattern-matching the visual cues.

### 4. Explain illegal moves politely, never harshly
When a player taps a card they cannot play, the card shakes gently and a brief tooltip explains why: "Needs Jade, a 5, or a wild card." The word "invalid" never appears. The word "error" never appears. The explanation disappears after 2.5 seconds without requiring a dismissal tap.

### 5. Never rely only on colour
Every card has a symbol in addition to its colour (Flame, Wave, Leaf, Sun). Every colour indicator shows its name as text. Every game-critical state change is communicated through text and/or shape, not colour alone. This is not just an accessibility principle — it is a baseline design requirement.

### 6. Keep the bottom half of iPhone useful for one-handed play
The human player's hand, the Draw button, the Solo! button, and the action prompt all live in the bottom half of the screen. Navigation, game status, and opponent zones live in the top half. A right-handed player holding their iPhone can reach every critical action with their thumb without repositioning their grip.

### 7. Use iPad space deliberately, not as stretched iPhone
On iPad, additional space is used to increase card size, add a live events side panel, show more of the game table at once, and provide popover-style pickers instead of full-screen modals. The layout is not simply enlarged — it is reconsidered for the larger canvas.

### 8. Make AI turns understandable, not instant and mysterious
When an AI player acts, the result is always announced in plain English: "Opponent played Jade Skip. Your turn is skipped." A brief thinking indicator establishes that the AI is deliberating, not just executing instantly. Players should understand what happened and why after every AI turn.

### 9. Reward progress with subtle delight
Correctly playing a complex action card earns a satisfying medium haptic. Calling Solo! at the right moment earns a pop animation. Winning a round earns a brief celebration. These moments are proportionate — they feel earned, not patronising.

### 10. Prefer clarity over decorative complexity
A clean white card with a large Crimson Flame is more legible and more elegant than a card with gradients, drop shadows, texture overlays, and multiple competing visual elements. Every decorative decision must pass the question: "Does this help the player, or does it just look busy?"

---

## 3. Information Architecture

### App structure

```
Wild Pairs
├── Home
│   ├── Continue Game (shows mode + time played, only when a game is saved)
│   ├── New Game
│   │   ├── Mode selection (Standard Teams / All-Wild Teams / Side-to-Side Teams)
│   │   ├── Difficulty selection (Easy / Medium / Hard / Expert)
│   │   ├── Card set selection (Standard 108-card / variations if added)
│   │   └── House rules (optional toggles before starting)
│   ├── Quick Play (jumps into Standard Teams with last-used difficulty)
│   ├── Rules
│   │   ├── How to play (overview)
│   │   ├── Card glossary (every card type explained)
│   │   ├── Mode summaries (one page per mode)
│   │   ├── Team rules
│   │   └── Difficulty explained
│   ├── Statistics
│   │   ├── Games played (total, by mode)
│   │   ├── Win rate (total, by mode, by difficulty)
│   │   ├── Average turns per round
│   │   ├── Win streak (current + best)
│   │   └── Local-only note
│   └── Settings
│       ├── Gameplay
│       │   ├── Animation speed (Normal / Fast / Off)
│       │   └── Confirm end game toggle
│       ├── Accessibility
│       │   ├── Haptics (On / Off)
│       │   ├── Reduced visual effects toggle
│       │   ├── Colour-blind mode toggle
│       │   ├── Pattern fills toggle (sub-option of colour-blind mode)
│       │   └── Large cards toggle
│       └── Data
│           ├── Reset statistics
│           └── Reset all local data (destructive, requires confirmation)
│
└── Game (persistent state, resumable)
    ├── Game table (primary gameplay view)
    ├── Pause menu (accessible via tap or swipe)
    │   ├── Resume
    │   ├── Rules (bottom sheet)
    │   ├── Settings
    │   └── End game (confirm destructive action)
    ├── Colour picker (modal / popover)
    ├── Target picker (inline sheet)
    ├── Team pass choice (Side-to-Side mode only)
    ├── Round end summary
    └── Game end summary
```

### Navigation model
- Home is the root. Back navigation from game returns to Home (with confirmation if game is in progress).
- No tab bar on iPhone — the game table is full screen. Navigation happens through the pause menu.
- On iPad in landscape, a persistent side strip can show event log; navigation remains via pause menu.
- Rules and Settings are accessible from both Home and the pause menu.
- Statistics is accessible from Home only (not from within a game).

---

## 4. User Journeys

### Journey 1: First launch to first completed round

1. App opens. Splash/launch screen shows game name for ~0.5s, then fades to Home.
2. Home shows: New Game (primary, large button), Quick Play, Rules, Statistics, Settings. "Continue Game" is absent (no saved game).
3. Player taps "New Game".
4. Mode selection screen: three cards (Standard Teams / All-Wild Teams / Side-to-Side Teams), each with a one-line description. Standard Teams is the default-highlighted choice.
5. Player selects Standard Teams, taps "Next".
6. Difficulty selection: four options (Easy / Medium / Hard / Expert) with brief descriptors. Medium is default.
7. Player selects difficulty, taps "Next".
8. Card set screen: Standard 108-card deck shown as default. House rules toggles below (all off). Player taps "Start Game".
9. **Optional tutorial overlay (first game only):** Five sequential overlay tooltips appear over the game table:
   - Step 1: Arrow points to player's hand — "Here's your hand. These are your cards."
   - Step 2: Arrow points to discard pile — "Match the top card by colour, number, or action."
   - Step 3: Playable cards highlighted — "Tap a highlighted card to play it. If you can't match, draw one."
   - Step 4: Solo! button highlighted — "When you have just one card left, tap Solo! to call it."
   - Step 5: Partner zone highlighted — "You and your partner are a team. Both must empty their hands to win a round."
   - "Got it — let's play!" button dismisses tutorial.
10. Deal animation: cards fly from centre to each player zone.
11. First player's turn determined. If not the human's turn, AI acts with thinking indicator and result announcement.
12. Human's turn: prompt reads "Your turn — play a Crimson card, a 5, or a wild card." Playable cards are visually lifted.
13. Human plays a card. Medium haptic. Card animates to discard pile.
14. Game continues until one team empties their hands. Round end summary appears.
15. Player taps "Continue" to play next round or "New Game" to start fresh.

### Journey 2: Returning user resumes a game

1. App opens. Home screen shows "Continue Game" button at the top, with context: "Standard Teams · Medium · Round 2."
2. Player taps "Continue Game".
3. Game table restores instantly. Full game state, all card counts, discard top card, current colour, and whose turn it is are all visible immediately.
4. If it was the human's turn when they left: action prompt re-appears, playable cards are highlighted.
5. If it was an AI's turn: brief thinking indicator runs, AI plays its card, game continues.
6. No loading state visible. No network request. State was persisted to disk when the app was backgrounded.

### Journey 3: User starts Standard Teams game

1. From Home → New Game → Mode selection.
2. Player taps "Standard Teams" card. A brief description expands below: "Match colour, number, or action. Wild cards change the colour. You and your AI partner must both empty your hands to win each round."
3. Player taps "Next" → Difficulty → Card set → "Start Game".
4. Mode summary toast appears at game start (3 seconds, dismissible): "Standard Teams — match colour, number, or action. Both you and your partner must empty your hands to win."
5. Gameplay follows standard rules. Partner AI plays cooperatively.

### Journey 4: User starts All-Wild Teams game

1. From Home → New Game → Mode selection.
2. Player taps "All-Wild Teams." Description: "Every card is wild! Play any card on any card, but action effects still apply. Focus on emptying your hand fast — teamwork still wins."
3. Player proceeds to difficulty, start.
4. Mode summary at game start: "All-Wild Teams — any card plays on any card. Action effects still apply. Work with your partner to empty both hands."
5. All cards appear with wild-card affordance (no colour restrictions on play eligibility). Colour picker appears after every card play. The action prompt reads "Choose any card to play."

### Journey 5: User starts Side-to-Side Teams game

1. From Home → New Game → Mode selection.
2. Player taps "Side-to-Side Teams." Description: "Partners sit side by side (you and the right opponent form one team; the left opponent and your AI partner form the other). You can pass one card to your partner per round."
3. Player proceeds to difficulty, start.
4. Mode summary at game start: "Side-to-Side Teams — you and the player to your right are partners. You may pass one card to your partner per round."
5. Player zones are re-labelled. Human's partner is to their right (previously labelled "opponent"). The pass mechanic is available once per round: a "Pass to partner" button appears when enabled.

### Journey 6: User changes difficulty mid-session

1. During a game, player opens pause menu.
2. Pause menu shows current difficulty. Player taps "Change difficulty".
3. Confirmation prompt: "Changing difficulty will not affect the current round. It will apply starting next round. Change to [difficulty selector]?"
4. Player confirms. New difficulty takes effect at the start of the next round.
5. Game resumes with no interruption to the current round.

### Journey 7: User learns why a card is not playable

1. Human's turn. Active colour is Cobalt. Player taps a Crimson 7.
2. Card shakes gently (spring animation, ~0.3s). Light error haptic.
3. Tooltip appears above the card: "Needs Cobalt, a 7, or a wild card." Tooltip uses the card's colour chip icon for Cobalt and text label.
4. Tooltip fades after 2.5 seconds automatically. Player does not need to dismiss it.
5. If player taps the same card again while tooltip is visible, tooltip resets its 2.5s timer.
6. If player is using VoiceOver: the reason is read aloud. No tooltip shown.

### Journey 8: User plays a Change Colour card

1. Human's turn. Player has a Change Colour wild card in their hand. Taps it.
2. Card lifts into selected state (elevation2 shadow, selection ring).
3. Action prompt updates: "Choose a new colour."
4. **iPhone:** Full-screen modal colour picker rises from the bottom. Four large colour swatches arranged in a 2×2 grid. Each swatch shows colour name and symbol. Minimum swatch size: 100×100pt.
5. **iPad:** Popover appears anchored to the card. Same four swatches, popover width ~260pt.
6. Player taps "Cobalt (Wave)". Popover/modal dismisses with a brief colour-pulse animation on the discard pile.
7. Card animates from hand to discard pile. New colour indicator updates.
8. Action prompt for next player: "Opponent's turn — must play a Cobalt card or a wild card."
9. If player taps outside the picker (iPhone modal only, behind a scrim): picker dismisses, card de-selects. No card is played.
10. VoiceOver: "Colour picker. Select a new colour. Crimson, Flame symbol, button. Cobalt, Wave symbol, button. Jade, Leaf symbol, button. Amber, Sun symbol, button."

### Journey 9: User plays a Targeted Draw card

1. Human plays a Targeted Draw card (draws a specified number of cards for a chosen opponent).
2. After card plays into the selected state, action prompt: "Choose a player to target."
3. Target picker shows player portraits/labels: "Left Opponent" and "Right Opponent" (partner cannot be targeted in Standard Teams).
4. Each target option shows current card count as a badge.
5. Player taps a target. Brief pulsing ring animation on that player's zone.
6. Target player's zone receives a draw-penalty animation (cards stack in with a fanning motion).
7. Result announced: "You targeted [Right Opponent]. They drew 2 cards."
8. Turn passes to next player.

### Journey 10: AI partner helps the human win

1. Human has 3 cards. Partner has 2 cards. Opponents each have 5+ cards.
2. Partner's turn. AI plays a Skip targeting the leading opponent. Event log: "Partner skipped [Left Opponent]'s turn."
3. Partner then (on their next turn) plays a Change Colour card and sets the colour to match the human's strongest suit. Event log: "Partner changed colour to Jade. Sets you up!"
4. Human's turn: 2 of their 3 remaining cards are now playable. Player plays down to 1.
5. Solo! call fires automatically: "Solo!" badge pops on the human's zone. VoiceOver: "You have one card remaining. Solo called automatically."
6. Partner plays their last card on their next turn. Partner zone shows "Out!" badge.
7. Human plays their final card on their next turn. Round win celebration triggers.

### Journey 11: User loses a close game and understands why

1. Human has 2 cards. Both opponents have 1 card each. Partner has 3.
2. Right Opponent plays Draw Two targeting the human. Human draws 2 cards (now 4 cards).
3. Event log: "Right Opponent played Draw Two — you drew 2 cards."
4. Left Opponent plays their final card. Left Opponent is out.
5. Right Opponent plays their final card on the next turn. Both opponents are out. Round over.
6. Round end summary screen appears. Gentle desaturate animation on the game table beneath it.
7. Summary shows: "Opponents win this round." Card counts listed for all players at round end. A short sentence: "Right Opponent drew your team out to end the round." ("So close!" shown if human had ≤3 cards at round end.)
8. Player taps "Next Round" or "New Game". No harshness, no penalty, no shaming language.

### Journey 12: User toggles colour-blind mode

1. From Home → Settings → Accessibility → Colour-blind mode (toggle off → on).
2. Toggle animates on. A brief preview row shows two sample cards with symbols and text labels added.
3. Subtitle text: "Symbols and text labels added to all cards and colour indicators."
4. Player returns to game (if in progress). No round interruption. Cards immediately show "CRIMSON", "COBALT" etc. as text labels; symbols are now larger and always visible.
5. Colour indicator always shows both chip and text name: [Cobalt chip] "Cobalt (Wave)".

### Journey 13: User plays in airplane mode

1. Device is in airplane mode. Player opens Wild Pairs.
2. App opens normally. No network check. No error banner. No degraded mode.
3. All features function identically. Statistics save locally. Game state saves locally.
4. Player plays a full session, closes app, reopens later. All state preserved.
5. Nothing in the app UI references network connectivity. There is no "offline mode" banner because there is no online mode.

### Journey 14: User quits mid-game and resumes later

1. Player is mid-game. They press the Home button (or use a gesture to background the app).
2. Game state serialises to disk synchronously in `applicationWillResignActive` (or equivalent SwiftUI lifecycle hook). This takes <50ms.
3. Player reopens the app 4 days later.
4. Home screen shows "Continue Game" with context details.
5. Player taps "Continue Game". Game table restores to the exact state when they left: same card hands, same discard pile, same whose-turn, same current colour.
6. No "session expired" state. No forced new game. State persists indefinitely until the player ends the game manually or resets data.

### Journey 15: User rotates iPad during a game

1. Player is playing in iPad portrait. They rotate to landscape.
2. SwiftUI layout adapts. Game table reflows: human hand remains at bottom, partner at top, opponents left and right. Deck and discard move to a more centred position. Available space used for a side events panel.
3. All animations complete in the rotated layout. No state is lost. No visual glitch.
4. Player rotates back to portrait. Layout reflows again. State preserved.
5. Auto-rotation lock respected: if the device rotation lock is on, the layout does not change.

### Journey 16: User plays in iPad Split View or narrow window

1. Player is on iPad with another app in Split View. Wild Pairs receives a compact-width horizontal size class.
2. Game table adapts to compact layout: side panel hidden, card sizes reduce to compact dimensions, layout mirrors iPhone layout.
3. Player can play a complete round without any element clipping off screen or becoming unreachable.
4. Stage Manager: app window can be any size. `GeometryReader` ensures the layout adapts at every width from ~320pt to ~1024pt.

### Journey 17: User resets local data

1. From Settings → Data → "Reset all local data."
2. Confirmation alert: "This will delete all saved games, statistics, and preferences. This cannot be undone." Two buttons: "Reset everything" (destructive, red) and "Cancel" (default).
3. Player taps "Reset everything."
4. All local data wiped: saved game state, statistics, settings preferences.
5. App returns to Home in fresh-launch state. "Continue Game" is absent. Statistics show zeroes.
6. Preferences (animation speed, haptics, accessibility) reset to defaults.
7. No crash, no loading state. Wipe is instant (<50ms for the data operation; layout update on next frame).

---

## 5. Screen-level UX Specs

### Home screen

**Purpose:** Entry point. Orient returning players; funnel new players into a game quickly.

**Primary action:** Continue Game (if saved game exists) / New Game (otherwise)

**Secondary actions:** Quick Play, Rules, Statistics, Settings

**Layout hierarchy:**
1. App name / wordmark (top, large)
2. Continue Game card (full-width, contextual — hidden if no saved game)
3. New Game button (primary, large, full-width)
4. Quick Play button (secondary, full-width)
5. Rules / Statistics / Settings row (tertiary, icon+label buttons at bottom)

**Empty states:** No saved game — Continue Game button absent. Statistics not yet collected — Statistics screen shows zeroed state with explanatory text.

**Error states:** None on this screen. Local data is always available.

**Accessibility notes:** All buttons have clear accessibility labels. Wordmark is decorative (accessibility hidden). Settings icon has label "Settings." Focus order: Continue → New Game → Quick Play → Rules → Statistics → Settings.

**Motion notes:** Home appears with a simple fade on first launch. No loop animation or idle animation. Continue Game card fades in if present.

**Tap targets:** All buttons minimum 50pt height, full width on iPhone.

**One-handed use:** All buttons reachable with bottom-of-screen thumb. Nothing critical above the fold midpoint on iPhone SE.

**Small iPhone (SE):** Three tertiary actions (Rules / Statistics / Settings) arranged as icon row to save vertical space. Continue Game card height reduced.

**Large iPhone (Pro Max):** Additional breathing room above/below buttons. Layout centred within safe area.

**iPad portrait:** Buttons constrained to 480pt max-width, centred. Wordmark larger. Additional whitespace above and below button group.

**iPad landscape:** Left-aligned button group with wordmark above, decorative card illustration to the right (or purely empty right half — do not stretch the button group).

**Split View / narrow:** Matches iPhone compact layout. All buttons full-width within available space.

---

### Mode selection

**Purpose:** Let players choose one of three game modes clearly.

**Primary action:** Select a mode (continues to difficulty).

**Secondary actions:** Back to Home.

**Layout hierarchy:**
1. Screen title: "Choose a mode"
2. Three mode cards (vertically stacked on iPhone, 3-column grid on iPad landscape)
3. Each card: mode name, one-line tagline, 2–3 line description
4. Selected card gains a subtle border/highlight
5. "Next" button at bottom (activates when a mode is selected; Standard Teams pre-selected by default)

**Empty states:** N/A

**Error states:** N/A

**Accessibility:** Each mode card has an accessibility label including name and description. Selecting a mode announces "Selected." Tab between modes with VoiceOver swipe. "Next" button announces "Mode selected, continue to difficulty."

**Motion:** Cards appear with a brief stagger-in (reduced motion: appear immediately).

**Tap targets:** Mode cards minimum 88pt height on iPhone.

**One-handed use:** Standard layout; all cards visible without scrolling on iPhone 6.1"+. SE may require scroll.

**Small iPhone (SE):** Cards slightly more compact; description text drops to 2 lines with truncation and "more" indicator.

**iPad portrait:** Cards arranged 1-column or 2-column depending on orientation.

**iPad landscape:** Cards arranged in 3-column grid. Descriptive text can be longer.

**Split View:** Falls back to 1-column vertical stack.

---

### Difficulty selection

**Purpose:** Set the AI difficulty level for the session.

**Primary action:** Select a difficulty.

**Secondary actions:** Back to mode selection.

**Layout hierarchy:**
1. Screen title: "Choose difficulty"
2. Mode reminder chip: "Standard Teams" (non-interactive, shows chosen mode)
3. Four difficulty options (vertically stacked rows or 2×2 grid on iPad)
4. Each option: name, one-line description of AI behaviour (e.g., "Easy — AI plays slowly and makes occasional mistakes," "Expert — AI plays optimally and coordinates perfectly with your partner")
5. Medium pre-selected by default
6. "Next" button at bottom

**Accessibility:** Difficulty descriptions must be included in accessibility labels. "Medium, recommended for new players. Currently selected."

**Tap targets:** Each row minimum 60pt height.

---

### Card set + house rules selection

**Purpose:** Confirm the card set (future-proofing for expansions) and enable any optional house rules before starting.

**Primary action:** "Start Game"

**Secondary actions:** Back to difficulty.

**Layout hierarchy:**
1. Screen title: "House rules"
2. Card set picker (standard only at v1.0; row shows "Standard 108-card deck — locked")
3. Divider: "Optional house rules"
4. Toggle list: each house rule has a name, one-line description, and on/off toggle (all off by default)
   - No draws back-to-back (prevents chaining multiple draw cards)
   - Strict Solo! (penalty for forgetting; default: off)
   - Jump-in (allow out-of-turn play of exact match; default: off)
5. "Start Game" primary button at bottom

**Motion:** None required.

**Accessibility:** Toggle labels include description: "Strict Solo! — penalty applied if you forget to call before the next player acts. Currently off."

---

### Game table — normal state

**Purpose:** Display the full game state at all times, even when it is not the human's turn.

**Primary action:** (None when not human's turn — UI is read-only except for pause)

**Secondary actions:** Open pause menu (button top-right or swipe gesture).

**Layout hierarchy:**
1. **Top bar:** Round indicator, current score/round count, Pause button (top-right)
2. **Partner zone (top):** Partner label, card back fan (showing count), "Out!" badge when empty, Solo! badge when applicable
3. **Left opponent zone (left):** Rotated label, card count, Solo! badge
4. **Right opponent zone (right):** Rotated label, card count, Solo! badge
5. **Table centre:** Draw pile (left of centre), Discard pile (right of centre), Current colour indicator (above/beside discard)
6. **Turn direction indicator:** Subtle arrow or icon near table centre showing direction
7. **Active player highlight:** Subtle glow on the currently-active player zone
8. **Action prompt:** Between table centre and human hand — always present, always describes current state
9. **Human hand (bottom):** Card fan, scrollable, tappable. Draw and Solo! buttons adjacent.

**Empty states:** N/A during gameplay.

**Accessibility:** VoiceOver focus order: Status bar → Discard pile → Colour indicator → Action prompt → Human hand (left to right) → Draw button → Solo! button → Pause.

**Motion:** Active player highlight pulses slowly. Turn direction indicator animates on change.

**Tap targets:** Draw button 56×44pt. Solo! button 56×44pt. Pause button 44×44pt. Cards: see hand interactions.

**One-handed use:** Human hand, Draw, Solo! all in bottom 40% of iPhone screen.

**Small iPhone (SE):** Partner and opponent zones minimal — card count only, no card-back fan.

**Large iPhone (Pro Max):** Card fan wider; more cards visible without scrolling; opponent counts more prominent.

**iPad portrait:** All zones larger. Events side panel may appear on right (showing last 5 actions as a log).

**iPad landscape:** Full table layout with more breathing room. Side panel with event log.

**Split View:** Compact layout identical to iPhone. Side panel hidden.

---

### Game table — human turn (playable cards highlighted)

**Purpose:** Make it effortless to identify and play a legal card.

**Additions to normal state:**
- Playable cards: lifted (elevation2), full opacity, subtle play-affordance ring or glow
- Unplayable cards: same opacity (no dimming), but no lift and no ring — the difference between playable and unplayable is the presence of affordance, not dimming
- Action prompt: "Your turn — play a [colour] card, a [number], or a wild card."
- Draw button visible and labelled "Draw Card"
- Solo! button visible and labelled "Solo!" if human has exactly 1 card remaining

**Card tap interactions:**
- First tap on playable card: card lifts further (selected state), Play button may appear (or second tap plays it on iPhone; single tap plays on iPad)
- Second tap on same playable card (or tap "Play"): card plays
- Tap on unplayable card: shake + tooltip

**Accessibility:** "Your turn" announced as live region update. Each playable card includes "Playable. Double tap to select." in its accessibility label.

---

### Game table — AI turn (thinking indicator)

**Purpose:** Show that the AI is deliberating. Prevent the impression that cards vanish by magic.

**Additions to normal state:**
- Thinking indicator on active AI player zone: three pulsing dots or spinner (reduced motion: static "thinking" label)
- Duration: Easy 0.3s / Medium 0.6s / Hard 0.9s / Expert 1.2s / Fast mode: 0.1s for all
- After thinking: card animation from player zone to discard
- Event log entry appears immediately after card play
- Action prompt updates to reflect result and next player's state

**Accessibility:** "Opponent is thinking" announced when thinking indicator appears. Result announced when card is played.

---

### Colour picker — iPhone (full-screen modal)

**Purpose:** Allow the human player to choose a new colour after playing a Change Colour or Draw Four wild card.

**Primary action:** Tap a colour swatch.

**Layout:**
- Full-screen modal rising from bottom (sheet presentation)
- Title: "Choose a new colour" (large, centred)
- 2×2 grid of large swatches, each showing:
  - Large colour fill
  - Suit symbol (Flame / Wave / Leaf / Sun)
  - Colour name as text
- Each swatch minimum 100×100pt
- Dismiss: tap swatch to select (no explicit cancel; card de-selects and picker closes if player dismisses sheet with swipe-down)
- In colour-blind mode: pattern fill overlays on each swatch; large symbol; colour name in all-caps

**Accessibility:** "Choose a new colour. Crimson, Flame symbol. Cobalt, Wave symbol. Jade, Leaf symbol. Amber, Sun symbol." Each swatch: "[Colour], [Symbol] symbol, button."

**Motion:** Sheet rises with standard system sheet animation (reduced motion: no animation, appears in place).

---

### Colour picker — iPad (popover)

**Purpose:** Same as iPhone picker, but respects iPad spatial conventions.

**Layout:**
- Popover anchored to the played wild card (or to a fixed anchor point near the discard pile if card position is variable)
- 2×2 swatch grid inside popover, ~260pt wide
- Arrow pointing to anchor
- Tap outside to dismiss (card de-selects)

**Accessibility:** Same as iPhone. Popover is announced as "Colour selection popover."

---

### Target picker (player selection)

**Purpose:** Allow the human player to choose a target for a Targeted Draw card or similar directed action.

**Layout (iPhone):**
- Bottom half sheet (half-height)
- Title: "Choose a target"
- Vertical list of eligible targets (Left Opponent, Right Opponent, etc.)
- Each row: player label, current card count badge
- Ineligible targets: not shown or shown greyed with explanation

**Layout (iPad):**
- Inline sheet or action sheet anchored near the played card

**Accessibility:** "Choose a target. Left Opponent, 5 cards, button. Right Opponent, 3 cards, button."

---

### Team pass choice (Side-to-Side mode)

**Purpose:** In Side-to-Side Teams mode, allow the human player to pass one card to their partner on their turn (once per round).

**Layout:**
- Small banner or action strip near the hand: "Pass a card to your partner?"
- "Yes — choose a card to pass" (button) / "No — skip pass" (button)
- If "Yes": human's hand enters pass-selection mode; tapping a card selects it for passing
- Confirm: "Pass [card name] to [partner label]?"
- Card animates across to partner zone

**Accessibility:** Pass option announced when available. Card selection for passing uses same VoiceOver interaction as card play.

---

### Pause menu

**Purpose:** Allow the player to resume, get help, change settings, or end the game.

**Layout:**
- Full-screen overlay (blurred game table behind it)
- Primary: "Resume" (large, top)
- Secondary: "Rules" (bottom sheet), "Settings" (push to settings screen), "Change difficulty" (inline)
- Tertiary/destructive: "End game" (red text, bottom — triggers confirmation)

**Accessibility:** "Game paused. Resume button. Rules button. Settings button. End game, destructive, button."

**Motion:** Overlay appears with blur fade (reduced motion: opacity transition only).

---

### Round end / game end summary

**Purpose:** Celebrate or commiserate, explain the result, and give a clear path forward.

**Layout:**
- Card-style overlay on game table
- Win: "Your team wins this round!" / "Your team wins the game!" in large display text. Colour glow. Brief confetti (reduced motion: static celebration badge).
- Loss: "Opponents win this round." / "Opponents win the game." Gentle desaturate. "So close!" shown if human had ≤3 cards at round end.
- Summary: card counts for all players at round end
- Context sentence: what ended the round (e.g., "Right Opponent played out first.")
- Round score summary (if multi-round scoring is tracked)
- Buttons: "Next Round" (primary) / "New Game" (secondary) / "Home" (tertiary)

**Accessibility:** Result announced as live region update. Focus moves to "Next Round" button automatically.

---

### Rules / help

**Purpose:** Allow players to learn or look up any game rule at any time.

**Layout:**
- Navigation list (on iPhone: push navigation; on iPad: split view with category list on left)
- Categories: How to Play, Card Glossary, Mode Summaries, Team Rules, Difficulty Explained
- Each entry: title, description, sample card image where relevant
- Card glossary: sorted list of every card type with icon, name, action description
- Accessible from Home → Rules and from pause menu

**Accessibility:** Full VoiceOver navigation. Card images have accessibility descriptions.

---

### Settings

**Purpose:** Personalise gameplay and accessibility options.

**Layout:**
- Grouped list (iOS settings style)
- Gameplay group: Animation speed (segmented control: Normal / Fast / Off), Confirm end game (toggle)
- Accessibility group: Haptics, Reduced visual effects, Colour-blind mode, Pattern fills (sub-row, only visible when colour-blind mode on), Large cards
- Data group: Reset statistics (non-destructive confirmation), Reset all local data (destructive confirmation)
- Each toggle has a subtitle explaining what it does

**Accessibility:** Toggle labels include state ("Haptics, currently on"). Destructive actions have warning labels in accessibility.

---

### Statistics

**Purpose:** Show the player how they are performing over time, without pressure or shame.

**Layout:**
- Summary row: total games played, overall win rate
- Mode breakdown: Standard Teams / All-Wild Teams / Side-to-Side Teams (win rate per mode)
- Difficulty breakdown: Easy / Medium / Hard / Expert (win rate per difficulty)
- Other stats: average turns per round, current win streak, best win streak
- Footer note: "All statistics are stored only on this device."

**Accessibility:** Stats are read as plain text. Percentages announced as "N percent."

---

## 6. Wireframes — iPhone (ASCII)

All wireframes use a notional 390×844pt iPhone (iPhone 14 baseline). Safe areas assumed (44pt top status bar, 34pt home indicator at bottom).

---

### Wireframe 1: Home screen (iPhone)

```
┌─────────────────────────────┐
│  ●●●                  9:41  │  ← Status bar
├─────────────────────────────┤
│                             │
│                             │
│      ♦  Wild Pairs  ♦       │  ← App wordmark (display size)
│                             │
│ ┌─────────────────────────┐ │
│ │  Continue Game          │ │  ← Contextual card (hidden if none)
│ │  Standard Teams · Med   │ │
│ │  Round 2 of 3  →        │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │        New Game         │ │  ← Primary button (accent filled)
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │       Quick Play        │ │  ← Secondary button (outlined)
│ └─────────────────────────┘ │
│                             │
│  ┌───────┐ ┌───┐ ┌───────┐ │
│  │ Rules │ │ ✦ │ │ ⚙ Set │ │  ← Tertiary row
│  └───────┘ └───┘ └───────┘ │
│            Stats            │
│                             │
│       ————————————          │  ← Home indicator
└─────────────────────────────┘
```

---

### Wireframe 2: Mode selection (iPhone)

```
┌─────────────────────────────┐
│  ←                    ···   │  ← Nav bar: back, title
│        Choose a mode        │
├─────────────────────────────┤
│                             │
│ ┌─────────────────────────┐ │
│ │  ✓  Standard Teams      │ │  ← Selected (border highlight)
│ │     Match colour, number│ │
│ │     or action. Classic  │ │
│ │     cooperative play.   │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │     All-Wild Teams      │ │
│ │     Any card plays on   │ │
│ │     any card. Fast and  │ │
│ │     chaotic.            │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │   Side-to-Side Teams    │ │
│ │     Partners sit side   │ │
│ │     by side. Pass one   │ │
│ │     card per round.     │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │          Next →         │ │  ← Primary button
│ └─────────────────────────┘ │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 3: Difficulty selection (iPhone)

```
┌─────────────────────────────┐
│  ←                          │
│      Choose difficulty      │
├─────────────────────────────┤
│  [ Standard Teams ]         │  ← Mode reminder chip (read-only)
│                             │
│ ┌─────────────────────────┐ │
│ │  Easy                   │ │
│ │  AI makes mistakes &    │ │
│ │  plays slowly.          │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │  ✓  Medium              │ │  ← Default selected
│ │  Balanced — good for    │ │
│ │  most players.          │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │  Hard                   │ │
│ │  AI plays strategically │ │
│ │  and rarely errs.       │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │  Expert                 │ │
│ │  Optimal play and tight │ │
│ │  partner coordination.  │ │
│ └─────────────────────────┘ │
│                             │
│ ┌─────────────────────────┐ │
│ │          Next →         │ │
│ └─────────────────────────┘ │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 4: Card set + house rules (iPhone)

```
┌─────────────────────────────┐
│  ←                          │
│        House rules          │
├─────────────────────────────┤
│  Card set                   │
│ ┌─────────────────────────┐ │
│ │  Standard 108-card deck │ │
│ │  (locked)            🔒 │ │
│ └─────────────────────────┘ │
│                             │
│  Optional house rules       │
│ ─────────────────────────── │
│  No draws back-to-back  [ ] │
│  Prevents chaining draw     │
│  cards.                     │
│ ─────────────────────────── │
│  Strict Solo!           [ ] │
│  Penalty for forgetting     │
│  to call Solo!              │
│ ─────────────────────────── │
│  Jump-in                [ ] │
│  Play out of turn on an     │
│  exact card match.          │
│ ─────────────────────────── │
│                             │
│ ┌─────────────────────────┐ │
│ │       Start Game        │ │  ← Primary
│ └─────────────────────────┘ │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 5: Game table — idle (iPhone)

```
┌─────────────────────────────┐
│  ⏸  Round 2    ●○○          │  ← Top bar: pause, round, score
├─────────────────────────────┤
│                             │
│   ┌──────────────────────┐  │
│   │  PARTNER  [🂠][🂠][🂠] │  │  ← Partner zone (3 card backs shown)
│   │           4 cards    │  │
│   └──────────────────────┘  │
│                             │
│  ┌────┐          ┌────┐     │
│  │LEFT│          │RGHT│     │  ← Left/Right opponent zones
│  │ 🂠  │          │ 🂠  │     │
│  │ 6  │          │ 5  │     │
│  └────┘          └────┘     │
│                             │
│     ┌────┐  ┌──────────┐   │
│     │DECK│  │  TOP     │   │  ← Draw pile / discard pile
│     │ 🂠  │  │CARD FACE │   │
│     │ 43 │  │ Cobalt 7 │   │
│     └────┘  └──────────┘   │
│                  ● Cobalt   │  ← Colour indicator
│                             │
│  Partner's turn…            │  ← Action prompt
│                             │
│ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐ ┌─┐  │  ← Human hand (card backs in idle)
│ │ │ │ │ │ │ │ │ │ │ │ │  │
│ └─┘ └─┘ └─┘ └─┘ └─┘ └─┘  │
│                             │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 6: Game table — human turn (iPhone)

```
┌─────────────────────────────┐
│  ⏸  Round 2    ●○○          │
├─────────────────────────────┤
│   ┌──────────────────────┐  │
│   │  PARTNER  [🂠][🂠][🂠] │  │
│   └──────────────────────┘  │
│  ┌────┐          ┌────┐     │
│  │LEFT│          │RGHT│     │
│  │ 6  │          │ 5  │     │
│  └────┘          └────┘     │
│     ┌────┐  ┌──────────┐   │
│     │DECK│  │ Cobalt 7 │   │
│     │ 43 │  └──────────┘   │
│     └────┘    ● Cobalt      │
│                             │
│  Your turn — play a Cobalt  │  ← Action prompt (your turn)
│  card, a 7, or a wild card. │
│                             │
│ ┌──┐ ┌──┐╔══╗ ┌──┐ ┌──┐   │  ← Hand: middle card playable (lifted)
│ │C3│ │J9│║C7║ │A2│ │🃏│   │  ← C=Crimson J=Jade A=Amber 🃏=Wild
│ └──┘ └──┘╚══╝ └──┘ └──┘   │  ← Selected card has double border
│                             │
│         [Draw Card]         │  ← Draw button visible
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 7: Game table — AI turn (iPhone)

```
┌─────────────────────────────┐
│  ⏸  Round 2    ●○○          │
├─────────────────────────────┤
│   ┌──────────────────────┐  │
│   │  PARTNER  [🂠][🂠][🂠] │  │
│   └──────────────────────┘  │
│  ┌────┐          ┌────┐     │
│  │LEFT│          │RGHT│     │
│  │ 🟡 ···│        │ 5  │     │  ← Left opponent: thinking indicator
│  └────┘          └────┘     │
│     ┌────┐  ┌──────────┐   │
│     │DECK│  │ Cobalt 7 │   │
│     │ 43 │  └──────────┘   │
│     └────┘    ● Cobalt      │
│                             │
│  Left Opponent is thinking… │  ← Action prompt
│                             │
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐  │  ← Human hand (non-interactive)
│ │  │ │  │ │  │ │  │ │  │  │
│ └──┘ └──┘ └──┘ └──┘ └──┘  │
│                             │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 8: Colour picker — iPhone (modal)

```
┌─────────────────────────────┐
│  ⏸  Round 2    ●○○          │
│                             │  ← Dimmed game table behind
│     [blurred game view]     │
│                             │
├─────────────────────────────┤  ← Sheet rising from bottom
│                             │
│     Choose a new colour     │  ← Sheet title
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │          │ │          │  │
│  │ CRIMSON  │ │  COBALT  │  │  ← 2×2 colour swatches
│  │  🔥 Flame│ │ 〰 Wave  │  │
│  │          │ │          │  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │          │ │          │  │
│  │   JADE   │ │  AMBER   │  │
│  │  🍃 Leaf │ │  ☀ Sun   │  │
│  │          │ │          │  │
│  └──────────┘ └──────────┘  │
│                             │
│  Swipe down or tap outside  │  ← Dismissal hint
│  to cancel.                 │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 9: Target picker — iPhone

```
┌─────────────────────────────┐
│  ⏸  Round 2    ●○○          │
│                             │
│     [blurred game view]     │
│                             │
│                             │
├─────────────────────────────┤  ← Half-height sheet
│                             │
│      Choose a target        │
│                             │
│ ┌─────────────────────────┐ │
│ │  Left Opponent   5 cards│ │  ← Target rows
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │  Right Opponent  3 cards│ │
│ └─────────────────────────┘ │
│                             │
│  [Cancel]                   │  ← Cancel button (ghost style)
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 10: Pause menu (iPhone)

```
┌─────────────────────────────┐
│                             │
│     [blurred game view]     │  ← Full-screen blur overlay
│                             │
│ ┌─────────────────────────┐ │
│ │         Paused          │ │  ← Modal card
│ │                         │ │
│ │ ┌─────────────────────┐ │ │
│ │ │      Resume ▶       │ │ │  ← Primary
│ │ └─────────────────────┘ │ │
│ │                         │ │
│ │   Rules         ›       │ │  ← Secondary rows
│ │   Settings      ›       │ │
│ │   Change difficulty ›   │ │
│ │                         │ │
│ │ ─────────────────────── │ │
│ │   End game              │ │  ← Destructive (red text)
│ └─────────────────────────┘ │
│                             │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 11: Round end (iPhone)

```
┌─────────────────────────────┐
│                             │
│  [desaturated game table]   │  ← Behind overlay
│                             │
│ ┌─────────────────────────┐ │
│ │                         │ │
│ │   🎉 Your team wins!    │ │  ← Win state (or "Opponents win.")
│ │   Round 2 complete      │ │
│ │                         │ │
│ │  You         0 cards    │ │  ← Final card counts
│ │  Partner     0 cards    │ │
│ │  Left Opp    4 cards    │ │
│ │  Right Opp   6 cards    │ │
│ │                         │ │
│ │  Right Opponent played  │ │  ← Context sentence
│ │  out first — you were   │ │
│ │  close!                 │ │
│ │                         │ │
│ │ ┌─────────────────────┐ │ │
│ │ │     Next Round →    │ │ │  ← Primary
│ │ └─────────────────────┘ │ │
│ │   New Game     Home     │ │  ← Secondary / tertiary
│ └─────────────────────────┘ │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 12: Rules / help (iPhone)

```
┌─────────────────────────────┐
│  ←            Rules         │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────────┐│
│  │ How to Play          ›  ││
│  ├─────────────────────────┤│
│  │ Card Glossary        ›  ││
│  ├─────────────────────────┤│
│  │ Standard Teams       ›  ││
│  ├─────────────────────────┤│
│  │ All-Wild Teams       ›  ││
│  ├─────────────────────────┤│
│  │ Side-to-Side Teams   ›  ││
│  ├─────────────────────────┤│
│  │ Team Rules           ›  ││
│  ├─────────────────────────┤│
│  │ Difficulty explained ›  ││
│  └─────────────────────────┘│
│                             │
│                             │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 13: Settings (iPhone)

```
┌─────────────────────────────┐
│  ←           Settings       │
├─────────────────────────────┤
│  GAMEPLAY                   │
│  Animation speed            │
│  [ Normal | Fast | Off ]    │
│  Confirm end game       [✓] │
│                             │
│  ACCESSIBILITY              │
│  Haptics                [✓] │
│  Reduced visual effects [ ] │
│  Colour-blind mode      [ ] │
│    Pattern fills        [ ] │  ← Sub-row (greyed when parent off)
│  Large cards            [ ] │
│                             │
│  DATA                       │
│  Reset statistics       ›   │
│  Reset all local data   ›   │  ← Red text
│                             │
│       ————————————          │
└─────────────────────────────┘
```

---

### Wireframe 14: Statistics (iPhone)

```
┌─────────────────────────────┐
│  ←         Statistics       │
├─────────────────────────────┤
│  OVERVIEW                   │
│  Games played:    47        │
│  Overall wins:    58%       │
│  Win streak:      3 (best 7)│
│                             │
│  BY MODE                    │
│  Standard Teams:  62%       │
│  All-Wild Teams:  51%       │
│  Side-to-Side:    44%       │
│                             │
│  BY DIFFICULTY              │
│  Easy:            80%       │
│  Medium:          60%       │
│  Hard:            42%       │
│  Expert:          25%       │
│                             │
│  OTHER                      │
│  Avg turns/round: 18        │
│                             │
│ ─────────────────────────── │
│  All statistics stored only │
│  on this device.            │
│       ————————————          │
└─────────────────────────────┘
```

---

## 7. Wireframes — iPad (ASCII)

iPad wireframes use a notional 1024×1366pt iPad Pro 13" in portrait and 1366×1024pt in landscape. iPad Air 11" proportions are similar at smaller scale.

---

### Wireframe 1: iPad home screen

```
┌──────────────────────────────────────────────────────────────────┐
│  ●●●  Wild Pairs                                       9:41  ■   │  ← Status bar
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│                     ♦  Wild Pairs  ♦                            │  ← Large wordmark
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Continue Game — Standard Teams · Medium · Round 2 of 3 → │  │  ← Continue card
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│         ┌─────────────────────┐  ┌─────────────────────┐        │
│         │      New Game       │  │     Quick Play       │        │  ← Side by side
│         └─────────────────────┘  └─────────────────────┘        │
│                                                                  │
│         ┌──────────┐  ┌──────────┐  ┌──────────────────┐        │
│         │  Rules   │  │  Stats   │  │    Settings      │        │  ← Three tertiary
│         └──────────┘  └──────────┘  └──────────────────┘        │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

### Wireframe 2: iPad mode selection

```
┌──────────────────────────────────────────────────────────────────┐
│  ←   Choose a mode                                               │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────┐ ┌────────────────────┐ ┌──────────────┐ │
│  │ ✓ Standard Teams   │ │  All-Wild Teams     │ │ Side-to-Side │ │  ← 3-column
│  │                    │ │                     │ │ Teams        │ │
│  │  Match colour,     │ │  Any card plays on  │ │              │ │
│  │  number, or        │ │  any card. Fast     │ │  Partners    │ │
│  │  action. Classic   │ │  and chaotic.       │ │  sit side by │ │
│  │  cooperative play. │ │                     │ │  side.       │ │
│  │                    │ │                     │ │              │ │
│  └────────────────────┘ └────────────────────┘ └──────────────┘ │
│                                                                  │
│                      ┌──────────────┐                           │
│                      │    Next →    │                           │
│                      └──────────────┘                           │
└──────────────────────────────────────────────────────────────────┘
```

---

### Wireframe 3: iPad game table — portrait

```
┌──────────────────────────────────────────────────────────────────┐
│  ⏸  Round 2   ●○○                                     [Events▸] │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│         ┌──────────────────────────────────────┐                │
│         │   PARTNER   [🂠][🂠][🂠][🂠]  4 cards  │                │  ← Partner zone
│         └──────────────────────────────────────┘                │
│                                                                  │
│  ┌─────────┐                                    ┌─────────┐     │
│  │  LEFT   │                                    │  RIGHT  │     │
│  │   OPP   │                                    │   OPP   │     │
│  │  [🂠][🂠] │                                    │  [🂠][🂠] │     │
│  │ 6 cards │                                    │ 5 cards │     │
│  └─────────┘                                    └─────────┘     │
│                                                                  │
│              ┌──────────┐    ┌──────────────┐                   │
│              │  DECK    │    │  TOP CARD    │                   │
│              │  [🂠]    │    │  Cobalt 7    │                   │
│              │  43 rem  │    │  ● Cobalt    │                   │
│              └──────────┘    └──────────────┘                   │
│                                                                  │
│  Your turn — play a Cobalt card, a 7, or a wild card.           │  ← Prompt
│                                                                  │
│  ┌───┐  ┌───┐  ╔═══╗  ┌───┐  ┌───┐  ┌───┐  ┌───┐              │  ← Hand (larger cards)
│  │C 3│  │J 9│  ║C 7║  │A 2│  │🃏 │  │J S│  │C 4│              │
│  └───┘  └───┘  ╚═══╝  └───┘  └───┘  └───┘  └───┘              │
│                                                                  │
│                         [Draw Card]                             │
└──────────────────────────────────────────────────────────────────┘
```

---

### Wireframe 4: iPad game table — landscape

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  ⏸  Round 2   ●○○                                                    9:41  ■  │
├────────────────────────────────────────────────────────────────┬───────────────┤
│                                                                │  Event log    │
│      ┌────────────────────────────────────────────┐           │  ─────────── │
│      │  PARTNER   [🂠][🂠][🂠][🂠]   4 cards        │           │  Partner     │
│      └────────────────────────────────────────────┘           │  changed to  │
│                                                                │  Cobalt      │
│  ┌──────────┐                          ┌──────────┐           │  ─────────── │
│  │   LEFT   │                          │  RIGHT   │           │  You skipped │
│  │    OPP   │                          │   OPP    │           │  Left Opp    │
│  │  6 cards │                          │  5 cards │           │  ─────────── │
│  └──────────┘                          └──────────┘           │  Left Opp    │
│                                                                │  drew 2      │
│           ┌──────────┐   ┌───────────────┐                    │  ─────────── │
│           │   DECK   │   │  TOP CARD     │                    │              │
│           │  43 rem  │   │  Cobalt 7     │                    │              │
│           └──────────┘   │  ● Cobalt     │                    │              │
│                          └───────────────┘                    │              │
│  Your turn — play a Cobalt card, a 7, or a wild.              │              │
│                                                                │              │
│  ┌────┐ ┌────┐ ╔════╗ ┌────┐ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │              │
│  │C 3 │ │J 9 │ ║C 7 ║ │A 2 │ │ 🃏 │ │J S │ │C 4 │ │C 1 │    │              │
│  └────┘ └────┘ ╚════╝ └────┘ └────┘ └────┘ └────┘ └────┘    │              │
│                                                                │              │
│                           [Draw Card]                         │              │
├────────────────────────────────────────────────────────────────┴───────────────┤
└────────────────────────────────────────────────────────────────────────────────┘
```

---

### Wireframe 5: iPad Split View — narrow layout

```
┌──────────────────────────┐
│  ⏸  R2  ●○○             │  ← Compact top bar
├──────────────────────────┤
│  PARTNER  [🂠][🂠]  4 ♠  │  ← Compact partner zone
│                          │
│ [L6]              [R5]   │  ← Compact opponent labels
│                          │
│  [DECK 43]  [Cobalt 7]   │
│             ● Cobalt     │
│                          │
│  Your turn — Cobalt,     │  ← Prompt wraps to 2 lines
│  7, or wild.             │
│                          │
│ ┌──┐ ┌──┐ ╔══╗ ┌──┐ ┌──┐│  ← Compact hand
│ │C3│ │J9│ ║C7║ │A2│ │🃏 ││
│ └──┘ └──┘ ╚══╝ └──┘ └──┘│
│       [Draw]             │
│       ────────           │
└──────────────────────────┘
```

---

### Wireframe 6: iPad colour picker (popover)

```
     ┌────────────────────────┐
     │   Choose a new colour  │  ← Popover title
     │                        │
     │  ┌──────┐  ┌──────┐   │
     │  │ 🔥   │  │ 〰   │   │
     │  │CRIMS.│  │COBALT│   │
     │  └──────┘  └──────┘   │
     │  ┌──────┐  ┌──────┐   │
     │  │ 🍃   │  │ ☀    │   │
     │  │JADE  │  │AMBER │   │
     │  └──────┘  └──────┘   │
     └──────────┬─────────────┘
                │  ← Arrow pointing to wild card played
         ╔═════╗
         ║ 🃏  ║  ← Selected wild card in hand
         ╚═════╝
```

---

### Wireframe 7: iPad target picker (inline sheet)

```
┌──────────────────────────────────────────────────────────────────┐
│  [game table behind]                                             │
│                                                                  │
│              ┌──────────────────────────────┐                   │
│              │     Choose a target          │                   │
│              │                              │                   │
│              │  ┌──────────────────────┐   │                   │
│              │  │  Left Opponent  6 ♠  │   │                   │
│              │  └──────────────────────┘   │                   │
│              │  ┌──────────────────────┐   │                   │
│              │  │  Right Opponent 5 ♠  │   │                   │
│              │  └──────────────────────┘   │                   │
│              │                              │                   │
│              │  [Cancel]                    │                   │
│              └──────────────────────────────┘                   │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

---

### Wireframe 8: iPad rules/help (side panel)

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  ←   Rules                                                                     │
├────────────────────────┬───────────────────────────────────────────────────────┤
│  How to Play           │                                                        │
│  Card Glossary      ←  │   Card Glossary                                       │
│  Standard Teams        │                                                        │
│  All-Wild Teams        │   Change Colour                                        │
│  Side-to-Side Teams    │   [wild card illustration]                             │
│  Team Rules            │   Play on any card. Choose a new colour for           │
│  Difficulty explained  │   all players. The next player must match             │
│                        │   the chosen colour or play a wild card.              │
│                        │                                                        │
│                        │   Draw Four                                            │
│                        │   [wild card illustration]                             │
│                        │   Play on any card. The next player draws             │
│                        │   four cards and loses their turn. Then               │
│                        │   choose a new colour.                                 │
│                        │                                                        │
│                        │   Skip                                                 │
│                        │   [action card illustration]                           │
│                        │   The next player loses their turn.                   │
│                        │                                                        │
└────────────────────────┴───────────────────────────────────────────────────────┘
```

---

### Wireframe 9: iPad settings / statistics (split layout)

```
┌────────────────────────────────────────────────────────────────────────────────┐
│  Settings                                                                       │
├───────────────────────────┬────────────────────────────────────────────────────┤
│  Gameplay              ←  │  Accessibility                                     │
│  Accessibility            │  ────────────────────────────────────────────────  │
│  Data                     │  Haptics                              [✓]          │
│                           │  When on, the app uses haptic feedback             │
│                           │  for card plays, wins, and errors.                 │
│                           │                                                    │
│                           │  Reduced visual effects               [ ]          │
│                           │  Simplifies animations and blurs.                 │
│                           │                                                    │
│                           │  Colour-blind mode                    [ ]          │
│                           │  Adds text labels and symbols to all              │
│                           │  colour indicators and cards.                      │
│                           │                                                    │
│                           │     Pattern fills                     [ ]          │
│                           │     Adds pattern overlays to cards.               │
│                           │                                                    │
│                           │  Large cards                          [ ]          │
│                           │  Increases card size by 40%.                      │
│                           │                                                    │
└───────────────────────────┴────────────────────────────────────────────────────┘
```

---

## 8. Game Table UX — Detailed

### Player zones

**Human hand (bottom):**
- Cards displayed in a fan spread along the bottom of the screen.
- Fan angle: cards slightly overlap, spread left-to-right.
- When hand is ≤5 cards on iPhone: cards comfortably spaced, all visible.
- When hand is 6–10 cards on iPhone: cards overlap more, all visible (scrollable if more than 10).
- When hand exceeds 10 cards: horizontal scroll within the fan area; a subtle gradient at the edges indicates more cards.
- Card size: 60×90pt compact (iPhone), 80×120pt (iPad). Large card mode: 80×120pt (iPhone), 100×150pt (iPad).
- Tapping a card selects it (elevation2 shadow, 4pt lift offset, selection ring).
- On iPhone: tap once to select, tap again (or tap Play button that appears) to play. On iPad: single tap plays directly (more deliberate interaction surface).
- Played-card animation: card slides up from hand position to discard pile position (0.3s spring).

**Partner zone (top):**
- Shows card back fan (visual indication of how many cards remain), card count badge.
- When partner is down to 1 card: Solo! badge appears prominently.
- When partner has played out: "Out!" badge. Card fan collapses.
- Last-played card or card count shown; no individual card faces (partner hand is hidden).

**Left and right opponent zones:**
- Narrow side panels on iPhone; wider on iPad.
- Show player label, card count, card-back thumbnail.
- Solo! badge when applicable.
- Active player highlight: subtle glow around the zone border when it is that player's turn.
- On iPad landscape: zones can be taller, showing a larger card-back fan.

### Table elements

**Draw pile:**
- Positioned centre-left of the table area.
- Shows a single card back face (the top of the deck).
- Count badge (e.g., "43") below or overlaid.
- Tappable only when it is the human's turn and they must or may draw.
- When tapped: card slides from pile to human's hand (0.3s). New card highlights briefly as the newest addition.

**Discard pile:**
- Positioned centre-right of the table area.
- Shows the top card fully: colour background, suit symbol, number or action name, colour name (in colour-blind mode).
- When a new card is played: top card updates with a brief crossfade or the new card slides in from the player zone.
- Slightly larger than draw pile for visual emphasis (this is the reference card everyone is matching).

**Current colour indicator:**
- A coloured chip/circle positioned near the discard pile.
- In normal mode: solid colour fill.
- In colour-blind mode: colour fill + colour name text + suit symbol.
- Changes with colour change animation (0.3s pulse to new colour).
- Always visible; never obscured by hand or player zones.

**Turn direction indicator:**
- A subtle animated arrow or set of arrows near the centre of the table.
- Shows clockwise or counterclockwise play direction.
- Animates a 180° rotation when a Reverse card is played.
- Reduced motion: no rotation animation; direction arrow updates instantly.

**Active player highlight:**
- A soft glow (elevation-style shadow in the active game colour) around the border of the active player's zone.
- Pulses slowly (period ~2s) to draw attention without being distracting.
- Reduced motion: static solid border instead of pulsing glow.

### Human hand interactions

**Card selection:**
- Tap: card lifts 4pt, gains selection ring (2pt border in accent colour), shadow increases to elevation2.
- If card is playable: selection ring is accent/success colour. A "Play" affordance may appear (button below card on iPhone, or a "double-tap to play" hint for VoiceOver users).
- If card is not playable: gentle spring shake animation (2 oscillations, ~0.3s total), light error haptic, tooltip appears.

**Tooltip behaviour:**
- Appears above the shaken card.
- Text: "Needs [active colour], a [active number], or a wild card." (always three criteria unless edge case).
- Colour chip + text in tooltip for colour reference.
- Fades automatically after 2.5s.
- Does not block any other interaction.
- Multiple illegal taps on different cards: each gets its own tooltip; previous tooltip dismisses immediately.
- VoiceOver: reason is spoken aloud instead.

**Scrollable hand:**
- When hand exceeds visible area: scroll gesture within the hand area (left/right swipe).
- Accessibility: VoiceOver users swipe through cards in order; scroll position not required.
- Gradient fade at left/right edges of hand area.

**Large card mode:**
- Cards are 80×120pt on iPhone (instead of 60×90pt). Text on cards scales up by one font step.
- Fewer cards visible at once; fan tighter; more scrolling required for large hands.
- Draw and Solo! buttons remain visible; they do not get pushed off screen.

### Action prompt area

The action prompt is a persistent text area between the table centre and the human hand. It always describes the current game state in plain English.

**State descriptions:**
- `"Your turn — play a [Colour] card, a [number], or a wild card."`
- `"Your turn — play a [Colour] card or a wild card."` (when top card is an action card)
- `"Your turn — no matching card. Draw one."` (when human has no legal play)
- `"Choose a new colour."` (after playing a wild card)
- `"Choose a player to target."` (after playing a targeted action card)
- `"Partner's turn."` (waiting for AI partner)
- `"Left Opponent's turn."` / `"Right Opponent's turn."` (waiting for AI opponent)
- `"Left Opponent is thinking…"` (during thinking indicator)
- `"Your turn is skipped."` (when a Skip or chain targets the human)
- `"Drawing [N] cards…"` (during draw penalty animation)

The prompt is always left-aligned, body text size (17pt), plain English. It never uses game jargon without explanation.

### Draw button

- Visible only when the human must draw (no legal play) or may draw (as an optional choice if allowed by rules).
- Label: "Draw Card" (never just "Draw" — always the noun for clarity).
- Position: below the hand area, centred or left of centre.
- Minimum tap target: 56×44pt.
- On tap: draw animation plays, new card appears in hand and is highlighted briefly.

### Solo! button and mechanic

- **Automatic detection:** When the human plays a card that brings their hand to 1 card, "Solo!" is called automatically. A badge animation fires on the human's zone. VoiceOver: "Solo! called automatically — you have one card remaining."
- **Manual call:** When the human has exactly 2 cards and they are about to play down to 1, the Solo! button appears prominently near the hand. Label: "Solo!" Subtitle text below: "Call before you play your last card."
- **Forgetting Solo!:** If "Strict Solo!" house rule is active and the human fails to call before the next player acts, a penalty fires: the human draws 2 cards. A gentle notification: "You forgot to call Solo! — drawing 2 cards."
- **AI calling opponent's forgotten Solo!:** If an AI player notices the human forgot to call Solo! (Strict Solo! mode), the event log reads: "Left Opponent called your Solo! — you drew 2 cards."

### Card selection on iPad

- Cards are larger (80×120pt regular, 100×150pt in large card mode).
- Single tap on an eligible card plays it directly (less ambiguity with larger touch targets).
- Selected card gains a floating preview above the hand — an enlarged ghost of the card (1.2× size) floats above the fan for ~0.5s before animating to the discard pile.
- Colour picker appears as a popover anchored to the played card position or the discard pile.

---

## 9. AI Turn UX

### Thinking indicator

Each AI player has a brief deliberation delay before acting. This delay is visible to the player and establishes that the AI is making a considered decision, not executing instantly.

| Difficulty | Thinking delay | Appearance |
|---|---|---|
| Easy | 0.3s | 1–2 pulsing dots |
| Medium | 0.6s | 3 pulsing dots |
| Hard | 0.9s | 3 pulsing dots + subtle glow on player zone |
| Expert | 1.2s | 3 pulsing dots + glow + brief pause before card animates |
| Fast mode | 0.1s (all) | Static "thinking" label only, no pulse |
| Reduced motion | 0.0s | No indicator; card appears instantly |

During the thinking period, the rest of the UI is non-interactive (except Pause).

### Card play animation

1. A card-back shape lifts from the active AI player's zone.
2. Card animates in an arc to the discard pile (duration: 0.3s normal, 0.15s fast mode).
3. Card face reveals on landing (crossfade from back to face, 0.15s).
4. Discard pile updates.
5. If the card is a wild: colour picker briefly animates to the AI's chosen colour (1s glow).
6. Event log entry and action prompt update simultaneously with the card landing.

### Action result announcements

Every significant AI action is announced in the event log (side panel on iPad landscape; a toast/banner on iPhone) and reflected in the action prompt:

| AI action | Event log text | Action prompt that follows |
|---|---|---|
| Opponent plays Skip (on partner) | "Right Opponent skipped your partner's turn." | "Your turn — play a [colour] card…" |
| Opponent plays Skip (on human) | "Left Opponent skipped your turn." | "Your turn is skipped. [Next player]'s turn." |
| Opponent plays Reverse | "Right Opponent reversed the direction." | "Partner's turn." |
| Opponent plays Draw Two (on human) | "Right Opponent used Draw Two — you drew 2 cards." | "Your turn — play a [colour] card, a [number], or a wild card." |
| Opponent plays Draw Four (on human) | "Left Opponent used Draw Four — you drew 4 cards and lost your turn." | "Right Opponent's turn." |
| Opponent changes colour | "Right Opponent changed colour to Jade." | "Your turn — play a Jade card or a wild card." |
| Opponent plays Forced Swap | "Right Opponent used Forced Swap — they swapped hands with you!" | "Your turn — play a [colour] card…" |
| Partner plays Skip (on opponent) | "Partner skipped Right Opponent's turn." | "Your turn — play a [colour] card…" |
| Partner changes colour | "Partner changed colour to Cobalt. Sets you up!" | "Your turn — play a Cobalt card or a wild card." |
| Partner calls Solo! | "Your partner called Solo! They have 1 card left." | (game continues) |
| AI player calls opponent's forgotten Solo! | "[Player] called [Target]'s Solo! — [Target] drew 2 cards." | (game continues) |

### Fast mode AI behaviour

In Fast mode (animation speed = Fast):
- All AI thinking delays reduced to 0.1s.
- Card animations reduced to 0.15s.
- Event log entries appear instantly.
- Colour change animations: 0.1s.
- The game feels snappy and driven; experienced players can get through rounds quickly.

---

## 10. Motion and Micro-interactions Catalogue

### Deal animation
- **Trigger:** Game start (after "Start Game" tap or after "Next Round").
- **Duration normal:** 0.8s total; cards stagger at 0.08s intervals.
- **Duration fast:** 0.3s total; 0.03s stagger.
- **Reduced motion:** Cards appear in place instantly.
- **Description:** Cards fly from a central deck position to each player zone in sequence (human first, then clockwise). Each card flips face-up when it reaches the human hand; others remain face-down.

### Card draw animation
- **Trigger:** Human taps "Draw Card" or is forced to draw.
- **Duration normal:** 0.3s.
- **Duration fast:** 0.15s.
- **Reduced motion:** Card appears in hand instantly with a brief opacity pulse.
- **Description:** Card slides from deck to the rightmost position in the human's hand. Card highlights briefly (1s, then fades).

### Card play animation
- **Trigger:** Human card is played; AI card is played.
- **Duration normal:** 0.3s (spring easing).
- **Duration fast:** 0.15s (easeOut).
- **Reduced motion:** Instant position update; discard pile updates with crossfade.
- **Description:** Card arc-slides from player zone to discard pile, revealing face on landing.

### Skip animation
- **Trigger:** Skip card played; targeted player's turn is skipped.
- **Duration normal:** 0.4s.
- **Duration fast:** 0.2s.
- **Reduced motion:** Static "SKIP" label appears on player zone for 1s.
- **Description:** An X mark materialises briefly over the skipped player's zone (scale-in then fade-out), then that zone briefly dims and the next player's zone lights up.

### Reverse animation
- **Trigger:** Reverse card played.
- **Duration normal:** 0.5s.
- **Duration fast:** 0.2s.
- **Reduced motion:** Direction indicator flips instantly.
- **Description:** The turn direction arrow rotates 180° with a spin-and-bounce easing.

### Draw penalty animation
- **Trigger:** Draw Two, Draw Four, or other penalty card played against a player.
- **Duration normal:** 0.6s (cards stagger at 0.1s intervals).
- **Duration fast:** 0.2s (0.03s stagger).
- **Reduced motion:** Card count badge on recipient zone updates; brief count animation (number increments).
- **Description:** Multiple card-back shapes fan into the recipient's zone in sequence, each landing with a slight bounce. Card count badge increments for each.

### Colour change animation
- **Trigger:** Change Colour or Draw Four wild card resolves; new colour selected.
- **Duration normal:** 0.4s.
- **Duration fast:** 0.15s.
- **Reduced motion:** Colour indicator and discard pile update instantly.
- **Description:** The discard pile and current colour indicator both pulse outward (scale 1.0 → 1.08 → 1.0) and crossfade to the new colour.

### Target selection animation
- **Trigger:** Targeted Draw card played; target picker appears.
- **Duration:** Continuous loop until target chosen (60Hz ring pulse, period 1.2s).
- **Reduced motion:** Static highlight ring on selectable players; no pulse.
- **Description:** Eligible target player zones gain a pulsing ring in the active colour while the target picker is open.

### Partner assist animation
- **Trigger:** AI partner makes a move that directly benefits the human (changes colour to match human's strongest suit; skips an opponent who would have acted before human).
- **Duration normal:** 0.6s.
- **Duration fast:** 0.2s.
- **Reduced motion:** Not shown.
- **Description:** A brief luminous arc traces from the partner zone to the human's hand (a "glow" connection). Appears simultaneously with the "Sets you up!" event log text.

### Solo! call animation
- **Trigger:** Any player reaches 1 card remaining.
- **Duration normal:** 0.5s.
- **Duration fast:** 0.2s.
- **Reduced motion:** Badge appears instantly.
- **Description:** A "Solo!" badge pops (scale 0 → 1.15 → 1.0, spring) on the player's zone. The badge glows in warning colour (amber). Haptic: heavy impact (human); warning notification (if AI player calls Solo!).

### Round win celebration
- **Trigger:** Human team wins a round.
- **Duration normal:** 1.5s (confetti burst, then fades to round end summary).
- **Duration fast:** 0.5s.
- **Reduced motion:** Round end summary appears with static "Your team wins!" badge. No confetti.
- **Description:** Confetti burst from the top of the screen; winning team zones glow in their active colour; round end overlay slides up.

### Round loss feedback
- **Trigger:** Opponent team wins a round.
- **Duration normal:** 0.6s.
- **Duration fast:** 0.2s.
- **Reduced motion:** Overlay appears with standard opacity transition.
- **Description:** Game table desaturates gently (not abruptly — 0.6s ease). Round end overlay slides up with "Opponents win." text.

### Haptic patterns

| Pattern | Trigger | Type | Notes |
|---|---|---|---|
| `cardSelect` | Tap to select a card | Light impact | Always fires on card tap |
| `cardPlay` | Card played successfully | Medium impact | Fires on card leaving hand |
| `illegalCard` | Tap unplayable card | Error notification | Fires with shake animation |
| `soloCall` | Solo! called (human) | Heavy impact | Success moment |
| `roundWin` | Human team wins round | Success notification | Distinct from cardPlay |
| `roundLoss` | Opponent team wins round | Warning notification | Gentle, not punishing |
| `drawPenalty` | Human draws due to penalty | Warning notification | Each card stagger may have individual light tap |
| `colourChange` | New colour selected | Light impact | Confirmation of selection |
| `targetChosen` | Target player selected | Medium impact | Confirmation of selection |
| `dealCard` | Each card dealt at round start | None (silent) | Too many haptics in deal would feel wrong |

**Motion constraints:**
- All animations must respect `UIAccessibility.isReduceMotionEnabled`. When enabled, use instant transitions or simple opacity changes.
- Fast mode reduces all animation durations by 70% (rounded to nearest 0.05s).
- No animation or chain of animations may block user input for more than 0.5s. If a sequence of AI actions would take longer, they must be parallelised or queued to complete within the 0.5s input window between each action the human cares about.
- The Pause button is always interactive, even during animations.

---

## 11. Onboarding and Help

### First-game tutorial

Shown on first launch only. The player can skip at any step. The tutorial overlays the live game table, so the player sees exactly what they will be playing.

| Step | Highlighted element | Text |
|---|---|---|
| 1 | Human hand | "Here's your hand. These are your cards — tap one to select it." |
| 2 | Discard pile | "Match the top card here — by colour, number, or action type." |
| 3 | Playable cards (highlighted) | "Highlighted cards match. Tap a highlighted card to play it. If you can't match, tap 'Draw Card'." |
| 4 | Solo! button | "When you have just one card left, tap 'Solo!' to call it. Don't forget — there's a penalty in Strict Solo! mode." |
| 5 | Partner zone | "You're on a team. You and your AI partner must both empty your hands to win a round." |
| Final | — | "Got it — let's play! (You can find the rules any time in the pause menu.)" |

- Tutorial progress persists. If interrupted, resumes at the last step.
- Tutorial can be replayed from Settings (not exposed by default; only after completing it).

### Contextual hints

Available in the first session or when enabled in settings. These are soft tooltip hints that appear once:

- **First illegal tap:** "That card doesn't match. The prompt above tells you what will play."
- **First wild card play:** "Wild cards play on anything! Choose a colour to set for everyone."
- **First AI partner action:** "Your partner is playing for your team. Their moves help both of you."

Hints are never repeated once dismissed. They can be re-enabled in Settings → Gameplay → "Show tips" (hidden behind "more options" on the settings screen).

### "Why can't I play this?" explanations

- Every illegal-tap tooltip explains the rule in one sentence.
- Pattern: "Needs [active colour], a [matching number], or a wild card."
- For Draw Two chain (if house rules prevent it): "Draw cards can't chain with that rule active."
- For target selection: "Tap a player zone to choose your target."

### Rules bottom sheet

Accessible from:
1. Pause menu → "Rules"
2. Home → "Rules" (full screen)

Bottom sheet (accessible from pause) contains:
- Current mode summary at the top (non-scrollable, always visible)
- Scrollable content: card glossary, team rules, how to win
- Close button (top-right)

### Mode summary at game start

A non-blocking toast banner appears at the start of each game (3 seconds, dismissible):

| Mode | Summary text |
|---|---|
| Standard Teams | "Standard Teams — match colour, number, or action. Both you and your partner must empty your hands to win." |
| All-Wild Teams | "All-Wild Teams — any card plays on any card. Action effects still apply. Empty your hand fast!" |
| Side-to-Side Teams | "Side-to-Side Teams — you and the right player are partners. Pass one card to your partner per round." |

### Card glossary

Full list of card types with icon, name, and description. Included in the Rules screen.

| Card | Icon | Description |
|---|---|---|
| Number cards (0–9) | Colour + number | Play on matching colour or matching number. |
| Skip | Colour + ∅ | Skips the next player's turn. Play on matching colour or any Skip. |
| Reverse | Colour + ↺ | Reverses play direction. Play on matching colour or any Reverse. |
| Draw Two | Colour + +2 | Next player draws 2 cards and loses their turn. Play on matching colour or any Draw Two. |
| Change Colour | Wild card | Play on any card. Choose a new colour for all players. |
| Draw Four | Wild card | Play on any card. Next player draws 4 cards and loses their turn. Then choose a new colour. |
| Forced Swap | Wild card | Play on any card. Choose a player and swap hands with them. |
| Targeted Draw | Colour card | Play on matching colour. Choose any one opponent to draw cards. |

---

## 12. Accessibility

### VoiceOver label patterns

**Number cards:**
```
"[Colour] [Number], number card. [Playable / Not playable — [reason]]. Double tap to [select / get more information]."

Examples:
"Crimson Seven, number card. Playable. Double tap to select."
"Cobalt Three, number card. Not playable — current card is Jade Five. Double tap for more information."
```

**Action cards:**
```
"[Colour] [Action name], action card. [Action description]. [Playable / Not playable — [reason]]. Double tap to [select / get more information]."

Examples:
"Jade Skip, action card. Skips the next player's turn. Playable. Double tap to select."
"Amber Reverse, action card. Reverses play direction. Not playable — needs Amber or a Reverse card. Double tap for more information."
```

**Wild cards:**
```
"[Wild card name], wild card. [Action description]. Plays on any colour. Playable. Double tap to select."

Examples:
"Change Colour, wild card. Lets you choose a new colour. Plays on any colour. Playable. Double tap to select."
"Draw Four, wild card. Next player draws four cards and loses their turn. Plays on any colour. Playable. Double tap to select."
```

**Opponent/partner cards (face-down):**
```
"[Player label], [N] cards remaining."
```

### VoiceOver custom actions

Every interactive card in the human's hand supports:
- **"Play card"** — plays the selected card (equivalent to the normal double-tap flow)
- **"Card details"** — reads the full rules text for that card type

Draw pile:
- **"Draw card"** — draws a card (only available during human's turn when draw is allowed)

Game table (as a whole — accessible by focusing the table background element):
- **"Game status"** — reads: "Round [N]. [Player]'s turn. Current colour: [colour]. Your hand: [N] cards. Partner: [N] cards. Left Opponent: [N] cards. Right Opponent: [N] cards. [current action prompt]."

### Live region announcements

The following game events trigger VoiceOver live region announcements (using `UIAccessibility.post(.announcement)` or SwiftUI equivalent):

- Turn starts (human): "Your turn. Play a [colour] card, a [number], or a wild card."
- Turn starts (AI partner): "Partner's turn."
- Turn starts (AI opponent): "[Opponent label]'s turn."
- AI plays a card: "[Player] played [card name]."
- Skip result (on human): "Your turn is skipped."
- Reverse result: "Play direction reversed."
- Draw penalty on human: "You drew [N] cards."
- Solo! called by anyone: "[Player] called Solo! They have one card remaining." (human: "You called Solo!")
- Round ends: "Your team wins this round." / "Opponents win this round."
- Game ends: "Your team wins the game!" / "Opponents win the game."

### Focus order

**Home screen:** Continue Game → New Game → Quick Play → Rules → Statistics → Settings

**Game table:** Pause button → Status bar → Discard pile → Colour indicator → Action prompt → Human hand (left to right, card by card) → Draw button (if visible) → Solo! button (if visible)

**Colour picker:** Title → Crimson → Cobalt → Jade → Amber → (dismiss)

**Target picker:** Title → first eligible target → second eligible target → Cancel

**Round end:** Result announcement → card count summary → Next Round → New Game → Home

### Dynamic Type
- All text elements use SwiftUI `.font()` with system styles (`.body`, `.title`, etc.) which scale automatically.
- Card numbers and symbols: use `.subheadline` (scales appropriately).
- At AX3 and above: card layout switches to large-card mode automatically (or user can toggle independently).
- No text is clipped at any Dynamic Type size. Cards may truncate long action names to abbreviations at very small sizes (e.g., "Rev." for Reverse).
- `.minimumScaleFactor(0.7)` used where layout cannot accommodate full-size text.

### High Contrast
- Default colours meet WCAG AA (4.5:1 for text, 3:1 for UI elements).
- When `UIAccessibility.isDarkerSystemColorsEnabled` is true: card borders increase to 2pt, transparency effects disabled, colour chips gain a dark border.

### Reduced Motion
- Detect `UIAccessibility.isReduceMotionEnabled`.
- When active: all card slide animations replaced by instant crossfades; deal is instant; confetti disabled; pulsing glow is static; thinking indicator is static text.
- All state changes remain clearly legible. No information is conveyed only through motion.

### Tap Targets
- All interactive elements minimum 44×44pt.
- Cards: 60×90pt compact (exceeds minimum on both axes).
- Draw, Solo!, colour swatches: minimum 56pt on the primary axis.
- Pause button: 44×44pt (top-right, not thumb-zone critical).
- Navigation items (back, close): 44×44pt.
