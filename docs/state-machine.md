# Wild Pairs — Game Engine State Machine Specification

> *Canonical sources: for data models (including GameSnapshot schema), `technical-architecture.md` §Model Reference is canonical. For game rules and house-rule defaults, `game-rules.md` is canonical. Where this document disagrees with its canonical source, the canonical source wins.*

## Architecture Notes

The Wild Pairs engine is a **pure synchronous reducer**:

```
(GameState, GameAction) -> (GameState, [GameEffect])
```

All state transitions happen on the **main actor** (or are dispatched to it synchronously). There is no concurrent game logic. Animations are cosmetic side-effects returned as `GameEffect` values; they do not block state transitions. The UI layer consumes `GameEffect` values and plays animations independently of the state machine.

State is persisted as a `Codable` snapshot using `FileManager`. Autosave is triggered at specific persistence points listed below.

---

## State Transition Diagram

```
                        ┌──────────────┐
                        │ appLaunching │
                        └──────┬───────┘
                               │ saved game found?
                    ┌──────────┴──────────┐
                    │ YES                 │ NO
                    ▼                     ▼
           ┌──────────────┐       ┌──────────────┐
           │loadingSavedGame│     │     home     │
           └──────┬────────┘      └──────┬───────┘
          success │                      │ newGame
                  │              ┌───────▼────────────┐
                  │              │ setupModeSelection  │
                  │              └───────┬─────────────┘
                  │                      │
                  │              ┌───────▼───────────────────┐
                  │              │ setupDifficultySelection   │
                  │              └───────┬───────────────────┘
                  │                      │
                  │              ┌───────▼──────────┐
                  │              │  setupCardSet     │
                  │              └───────┬───────────┘
                  │                      │
                  │              ┌───────▼──────────┐
                  │              │  setupHouseRules  │
                  │              └───────┬───────────┘
                  │                      │ confirmSetup
                  └─────────┐   ┌────────┘
                            ▼   ▼
                        ┌─────────┐
                        │ dealing │
                        └────┬────┘
                             │ dealComplete
                             ▼
              ┌──────────────────────────────────────┐
              │           TURN LOOP                  │
              │                                      │
              │  ┌─────────────────┐                 │
              │  │awaitingHumanTurn│◄────────────────┤
              │  └────────┬────────┘                 │
              │           │                          │
              │    ┌──────┴──────────────────┐       │
              │    │ play card / draw / pass  │       │
              │    └──────┬──────────────────┘       │
              │           │                          │
              │  ┌────────▼──────────┐               │
              │  │awaitingHumanDraw  │               │
              │  │(if no valid play) │               │
              │  └────────┬──────────┘               │
              │           │                          │
              │  ┌────────▼──────────────┐            │
              │  │ awaitingHumanColour   │            │
              │  │ Choice (if wild)      │            │
              │  └────────┬──────────────┘            │
              │           │                          │
              │  ┌────────▼──────────────┐            │
              │  │ awaitingHumanTarget   │            │
              │  │ Choice (if targeted)  │            │
              │  └────────┬──────────────┘            │
              │           │                          │
              │  ┌────────▼──────────────┐            │
              │  │ resolvingHumanMove    │            │
              │  └────────┬──────────────┘            │
              │           │                          │
              │  ┌────────▼──────────┐               │
              │  │ animatingCardPlay │               │
              │  └────────┬──────────┘               │
              │           │                          │
              │  ┌────────▼──────────┐               │
              │  │checkingSoloPenalty│               │
              │  └────────┬──────────┘               │
              │           │                          │
              │      ┌────┴────┐                     │
              │      │ round   │                     │
              │      │ ended?  │                     │
              │      └────┬────┘                     │
              │      YES  │  NO                      │
              │           │                          │
              │           │  ┌──────────────────┐    │
              │           │  │  awaitingAITurn  │    │
              │           │  └────────┬─────────┘    │
              │           │           │              │
              │           │  ┌────────▼─────────┐    │
              │           │  │ resolvingAIMove  │────┘
              │           │  └──────────────────┘
              │           │
              ▼           ▼
        ┌──────────┐  ┌──────────┐
        │roundEnded│  │gameEnded │
        └──────────┘  └──────────┘
              │
              │ newRound
              ▼
           dealing
```

**Orthogonal states (can occur at any point):**

- `paused` — overlays game state; resuming pops back to prior state
- `errorRecoverable` — overlays any state; user can dismiss or retry
- `awaitingHumanTeamPassChoice` — occurs between `dealing` and first `awaitingHumanTurn` in Side-to-Side mode

---

## State Definitions

---

### `appLaunching`

**Entry conditions:** Application cold-launch or scene re-connect.

**Allowed actions:**
- `systemLaunchComplete` — triggered automatically when app initialisation finishes

**Exit transitions:**
- If a valid saved game snapshot exists on disk → `loadingSavedGame`
- If no saved game exists → `home`

**UI prompt:** Splash screen / launch screen (system-managed). No game UI visible.

**Persistence point:** No.

**Tests required:**
- App launches cold with no save file → navigates to `home`
- App launches cold with valid save file → navigates to `loadingSavedGame`
- App launches cold with corrupted save file → navigates to `home` (corrupted save discarded)

---

### `home`

**Entry conditions:** Launch (no save file), user taps "New Game" after a completed game, or user discards a loaded game.

**Allowed actions:**
- `startNewGame` → `setupModeSelection`
- `resumeSavedGame` (if save present) → `loadingSavedGame`
- `openSettings` (navigates within home, not a state change)

**Exit transitions:**
- `startNewGame` → `setupModeSelection`
- `resumeSavedGame` → `loadingSavedGame`

**UI prompt:** "Wild Pairs — New Game / Resume"

**Persistence point:** No.

**Tests required:**
- "New Game" button triggers `startNewGame`
- "Resume" button appears only when a save file exists
- "Resume" button absent when no save file exists

---

### `setupModeSelection`

**Entry conditions:** User taps "New Game" from `home`.

**Allowed actions:**
- `selectMode(GameMode)` — user selects Standard Teams, All-Wild Teams, or Side-to-Side Teams
- `goBack` → `home`

**Exit transitions:**
- `selectMode` → `setupDifficultySelection`
- `goBack` → `home`

**UI prompt:** "Choose a game mode" with three options: Standard Teams, All-Wild Teams, Side-to-Side Teams. Each option shows a brief description.

**Persistence point:** No (setup is not persisted until confirmed).

**Tests required:**
- All three modes are presented
- Selecting each mode records the correct `GameMode` in pending setup config
- Back navigates to `home`

---

### `setupDifficultySelection`

**Entry conditions:** User selects a mode in `setupModeSelection`.

**Allowed actions:**
- `selectDifficulty(AIDifficulty)` — Easy, Medium, Hard, Expert
- `goBack` → `setupModeSelection`

**Exit transitions:**
- `selectDifficulty` → `setupCardSet`
- `goBack` → `setupModeSelection`

**UI prompt:** "Choose AI difficulty" with four options and brief descriptions of each.

**Persistence point:** No.

**Tests required:**
- All four difficulty levels are presented
- Selected difficulty is stored in pending config
- Back returns to `setupModeSelection` without losing mode selection

---

### `setupCardSet`

**Entry conditions:** User selects difficulty in `setupDifficultySelection`.

**Allowed actions:**
- `selectCardSet(CardSet)` — Beginner, Standard, Advanced
- `goBack` → `setupDifficultySelection`

**Exit transitions:**
- `selectCardSet` → `setupHouseRules`
- `goBack` → `setupDifficultySelection`

**UI prompt:** "Choose a card set" with descriptions of Beginner, Standard, and Advanced sets and their card contents.

**Persistence point:** No.

**Tests required:**
- All three card sets are presented with accurate card-type descriptions
- Selected card set stored in pending config
- Back returns to `setupDifficultySelection`

---

### `setupHouseRules`

**Entry conditions:** User selects card set in `setupCardSet`.

**Allowed actions:**
- `toggleHouseRule(HouseRule, Bool)` — toggle any house rule on/off
- `confirmSetup` → `dealing`
- `goBack` → `setupCardSet`

**Exit transitions:**
- `confirmSetup` → `dealing`
- `goBack` → `setupCardSet`

**UI prompt:** "House Rules (optional)" — list of all house rules with toggle controls and default-off state. "Start Game" button to confirm.

**Persistence point:** No (setup snapshot is written only when `dealing` is entered).

**Tests required:**
- All house rules are listed with correct defaults (see game-rules.md)
- Toggling a rule updates pending config
- Team Pass rule is only shown when Side-to-Side mode was selected
- "Start Game" triggers `confirmSetup`
- Back returns to `setupCardSet` retaining house rule changes

---

### `loadingSavedGame`

**Entry conditions:** `appLaunching` (valid save detected) or `home` (user taps Resume).

**Allowed actions:**
- `systemSaveLoaded(GameState)` — internal action fired when deserialisation succeeds
- `systemSaveLoadFailed` — internal action fired when deserialisation fails

**Exit transitions:**
- `systemSaveLoaded` → the state stored in the snapshot (typically `awaitingHumanTurn` or `awaitingHumanColourChoice`)
- `systemSaveLoadFailed` → `home` (save file deleted, error shown briefly)

**UI prompt:** Loading indicator: "Resuming your game…"

**Persistence point:** No (we are reading, not writing).

**Tests required:**
- Valid snapshot deserialises and restores correct game state including all pending actions
- Corrupted snapshot causes navigation to `home` and deletion of save file
- Snapshot with mismatched schema version is treated as corrupted
- A game paused mid-colour-choice resumes at `awaitingHumanColourChoice` with pending choice preserved

---

### `dealing`

**Entry conditions:** `confirmSetup` from `setupHouseRules`, or `newRound` from `roundEnded`.

**Allowed actions:**
- `systemDealComplete` — internal action fired after deal animation completes

**Exit transitions:**
- If mode is Side-to-Side and team pass is enabled → `awaitingHumanTeamPassChoice`
- Otherwise → `awaitingHumanTurn`

**UI prompt:** Cards are animated to each player's hand. No user interaction required.

**Persistence point:** Yes — a snapshot is written after dealing completes and the initial game state is established. This ensures the game can be resumed even if the app is killed before the first turn.

**Tests required:**
- Correct number of cards dealt to each player (7 each)
- Draw pile and discard pile initialised correctly
- Starting discard card is never a wild-type card
- Snapshot written after deal completes
- Side-to-Side mode proceeds to `awaitingHumanTeamPassChoice`
- Standard/All-Wild modes proceed to `awaitingHumanTurn`

---

### `awaitingHumanTeamPassChoice`

**Entry conditions:** `dealing` completes in Side-to-Side mode with team pass enabled.

**Allowed actions:**
- `selectTeamPassCard(CardID)` — human selects which card to pass to partner
- `declineTeamPass` — human opts not to pass
- `confirmTeamPass` — human confirms selected card (may be same action as `selectTeamPassCard` depending on UX flow)

**Exit transitions:**
- `confirmTeamPass` or `declineTeamPass` → `awaitingHumanTurn` (after AI partners also complete their pass choice internally)

**UI prompt:** "Team Pass — select one card to send to your partner (or skip)." Cards in hand are displayed; partner's card count is shown but not card identities.

**Persistence point:** Yes — snapshot written after team pass phase resolves (both teams' passes are committed simultaneously).

**Tests required:**
- Human can select any card in hand
- Human can decline pass
- Partner AI selects a card using its difficulty heuristic (not visible to human)
- Cards are swapped simultaneously, hidden from opponents
- Snapshot written after resolution
- State only appears in Side-to-Side mode; never appears in Standard or All-Wild

---

### `awaitingHumanTurn`

**Entry conditions:** It is the human player's turn. Entered after: `dealing` (first turn), `resolvingAIMove` (AI turn complete), `animatingSkip` (human's skip resolved — actually this means human was NOT skipped; see note), `checkingSoloPenalty` (penalty resolved or no penalty), `awaitingHumanTeamPassChoice` (team pass phase complete, if human goes first).

**Allowed actions:**
- `playCard(CardID)` — play a specific card from hand
- `drawCard` — draw from the draw pile (only valid if no legal play exists)
- `callSolo` — call "Solo!" if Solo! declaration is still pending (edge case: human can call it proactively)
- `openPauseMenu` → `paused`

**Exit transitions:**
- `playCard` where card requires colour selection → `awaitingHumanColourChoice`
- `playCard` where card requires target selection → `awaitingHumanTargetChoice`
- `playCard` where card requires no further input → `resolvingHumanMove`
- `drawCard` → `awaitingHumanDraw`
- `openPauseMenu` → `paused`

**UI prompt:** "Your turn — play a card or draw." Valid cards are highlighted; invalid cards are dimmed. Draw pile is tappable if no valid play exists.

**Persistence point:** Yes — snapshot written on entry.

**Tests required:**
- All valid cards are highlighted; invalid cards are dimmed
- Draw pile is tappable only when no valid play exists
- Playing a wild navigates to `awaitingHumanColourChoice`
- Playing a targeted card navigates to `awaitingHumanTargetChoice`
- Playing a normal card navigates to `resolvingHumanMove`
- Tapping draw navigates to `awaitingHumanDraw`
- All-Wild mode: all cards are highlighted regardless of colour/number
- Snapshot is written on entry

---

### `awaitingHumanDraw`

**Entry conditions:** Human has no legal play and taps the draw pile from `awaitingHumanTurn`.

**Allowed actions:**
- `confirmDrawnCard(play: Bool)` — after seeing the drawn card, human elects to play it (if legal) or end their turn
- `openPauseMenu` → `paused`

**Exit transitions:**
- `confirmDrawnCard(play: true)` → `resolvingHumanMove` (if drawn card is a wild, may instead go to `awaitingHumanColourChoice`)
- `confirmDrawnCard(play: false)` → `awaitingAITurn` (turn ends)
- `openPauseMenu` → `paused`

**UI prompt:** The drawn card is revealed to the human. "Play [card name]?" with Play / Pass options. Pass option available even if card is playable.

**Persistence point:** Yes — snapshot written immediately after the card is drawn (so resume is consistent with what card was drawn).

**Tests required:**
- Drawn card is shown to human player only (AI hands masked)
- Play option appears only if drawn card is legal
- Pass option always appears
- Choosing play with a wild navigates to `awaitingHumanColourChoice`
- Choosing pass advances to `awaitingAITurn`
- Snapshot captures drawn card in hand before decision

---

### `awaitingHumanColourChoice`

**Entry conditions:** Human plays a wild-type card (Change Colour, Draw Four, Discard All) that requires colour selection.

**Pending decision state:** `{ pendingCard: CardID, pendingColourChoice: nil }`

**Allowed actions:**
- `selectColour(CardColour)` — choose Crimson, Cobalt, Jade, or Amber
- `openPauseMenu` → `paused`

**Exit transitions:**
- `selectColour` → `resolvingHumanMove` (with colour attached to pending action)
- `openPauseMenu` → `paused`

**UI prompt:** "Choose a colour:" with four colour buttons (Crimson/Flame, Cobalt/Wave, Jade/Leaf, Amber/Sun). Each button shows the colour name, symbol, and a colour swatch.

**Persistence point:** Yes — snapshot written on entry with `pendingColourChoice: nil`. On resume, the engine re-enters this state and shows the colour picker again.

**Background/resume handling:** If the app is backgrounded mid-choice, the snapshot preserves `pendingCard` and `pendingColourChoice: nil`. On resume, `loadingSavedGame` restores to `awaitingHumanColourChoice`. The human sees the colour picker again and makes their choice fresh.

**Tests required:**
- All four colour options displayed
- Selected colour stored and passed to `resolvingHumanMove`
- Resume from background mid-colour-choice re-presents colour picker
- VoiceOver announces each colour option with its symbol name
- Discard All card correctly routes through this state for its colour selection

---

### `awaitingHumanTargetChoice`

**Entry conditions:** Human plays a card that requires choosing a target player (Targeted Draw, Forced Swap).

**Pending decision state:** `{ pendingCard: CardID, pendingTarget: PlayerID? }`

**Allowed actions:**
- `selectTarget(PlayerID)` — choose an opponent (or any player for Forced Swap)
- `openPauseMenu` → `paused`

**Exit transitions:**
- `selectTarget` → `resolvingHumanMove` (with target attached to pending action)
- `openPauseMenu` → `paused`

**UI prompt:** "Choose a target:" with player indicators for each eligible player. Targeted Draw: opponents only. Forced Swap: any other player (opponents and partner).

**Persistence point:** Yes — snapshot written on entry with `pendingTarget: nil`.

**Background/resume handling:** Same as `awaitingHumanColourChoice` — resume re-presents the target picker.

**Tests required:**
- Targeted Draw: only opponents are selectable; partner is not a valid target
- Forced Swap: all other players (including partner) are selectable
- Selected target stored and passed to `resolvingHumanMove`
- Resume from background mid-target-choice re-presents target picker
- Players who have already gone out are not valid targets

---

### `resolvingHumanMove`

**Entry conditions:** Human has completed all required sub-choices (colour, target) and the engine is ready to apply the full move.

**Allowed actions:** None — this is an internal transition state. No user input is accepted.

**Exit transitions:**
- → `animatingCardPlay` (immediately, synchronously)

**Processing:**
1. Validate move (defence against stale UI state).
2. Remove card from human's hand.
3. Place card on discard pile.
4. Update active colour (for wilds).
5. Compute effects (skip targets, draw targets, swap targets, etc.).
6. Check if human's hand is now empty → if yes, flag for round-end check.
7. Check if human's hand is now 1 card → flag Solo! pending.
8. Return updated `GameState` and list of `GameEffect` values for animation.

**Persistence point:** No (snapshot will be written at next stable waiting state).

**Tests required:**
- Card is removed from hand and added to discard pile
- Active colour updates correctly for wild cards
- Solo! flag is set when hand drops to 1
- Round-end flag is set when hand reaches 0
- All action effects are computed correctly (Draw Two targets correct player, etc.)
- Invalid move (e.g., replaying a card not in hand) is rejected with `errorRecoverable`

---

### `awaitingAITurn`

**Entry conditions:** It is an AI player's turn. Entered after: `resolvingHumanMove` (and animations complete), `resolvingAIMove` (previous AI turn complete, next player is also AI), `animatingSkip` (AI skip resolved — actually next AI takes turn).

**Allowed actions:**
- `systemAITurnReady` — internal action fired after a short delay (simulated thinking time). The AI's chosen action is attached to this action.

**Exit transitions:**
- `systemAITurnReady` → `resolvingAIMove`

**UI prompt:** "[Player name] is thinking…" — opponents' hands show card backs only. Partner's hand shows card backs only (masked observation).

**Persistence point:** Yes — snapshot written on entry (captures whose turn it is and full game state).

**Tests required:**
- AI chooses a valid card or draw according to its difficulty level
- AI cannot observe human hand or partner hand content (masked state)
- AI calls Solo! correctly when its hand drops to 1
- Easy AI selects random valid move
- Medium AI uses heuristic
- Hard AI uses scored heuristic
- Expert AI uses lookahead simulation
- Snapshot written on entry

---

### `resolvingAIMove`

**Entry conditions:** `awaitingAITurn` receives `systemAITurnReady` with AI's chosen move.

**Allowed actions:** None — internal transition state.

**Exit transitions:**
- → `animatingCardPlay` (immediately, synchronously)

**Processing:** Same as `resolvingHumanMove` but for the AI player. AI move has already been selected; this state applies it to game state and produces effects.

**Persistence point:** No.

**Tests required:**
- All same tests as `resolvingHumanMove` but for each AI player position
- Colour choices for AI wilds are made by AI heuristic (not human input)
- Target choices for AI targeted cards are made by AI heuristic

---

### `animatingCardPlay`

**Entry conditions:** `resolvingHumanMove` or `resolvingAIMove` — card has been placed on discard pile in game state.

**Allowed actions:**
- `animationComplete(AnimationType.cardPlay)` — fired by UI layer when animation finishes

**Exit transitions:**
- If card effect includes draw → `animatingDraw`
- If card effect includes skip → `animatingSkip`
- If card effect includes reverse → `animatingReverse`
- If no pending effect animations → `checkingSoloPenalty`

**UI prompt:** Card slides from player's hand to discard pile. No user interaction during animation. Reduced Motion mode: instant transition (no slide).

**Persistence point:** No (game state is already correct; animation is cosmetic).

**Tests required:**
- Animation plays for each player position (human, partner, left AI, right AI)
- Animation skipped when Reduce Motion accessibility setting is on
- Correct subsequent state entered based on card type

---

### `animatingDraw`

**Entry conditions:** A card effect requires one or more cards to be drawn by a player.

**Allowed actions:**
- `animationComplete(AnimationType.draw)` — fired by UI when draw animation finishes

**Exit transitions:**
- → `checkingSoloPenalty`
- → `animatingCardPlay` if more animations are queued

**UI prompt:** Card(s) slide from draw pile to target player's hand. Target player's card count updates visually.

**Persistence point:** No.

**Tests required:**
- Draw animation plays for correct target player
- Multiple draws (Draw Four) animate each card sequentially or as a group
- Reshuffle of discard pile animates correctly when draw pile exhausted
- Reduced Motion: instant transition

---

### `animatingSkip`

**Entry conditions:** A skip or Skip Two effect is pending.

**Allowed actions:**
- `animationComplete(AnimationType.skip)` — fired by UI when skip animation finishes

**Exit transitions:**
- → `checkingSoloPenalty`
- → `awaitingHumanTurn` or `awaitingAITurn` (depending on who plays next after the skip)

**UI prompt:** Skipped player's seat is briefly highlighted (e.g., an X overlay). VoiceOver announces "[Player name]'s turn is skipped."

**Persistence point:** No.

**Tests required:**
- Correct player(s) marked as skipped
- Skip Two marks two players
- VoiceOver announcement fires
- Reduced Motion: no highlight animation, but VoiceOver still fires

---

### `animatingReverse`

**Entry conditions:** A Reverse card effect is pending.

**Allowed actions:**
- `animationComplete(AnimationType.reverse)` — fired by UI when reverse animation finishes

**Exit transitions:**
- → `checkingSoloPenalty`

**UI prompt:** Turn direction indicator animates (e.g., arrow reverses direction). VoiceOver announces "Turn direction reversed."

**Persistence point:** No.

**Tests required:**
- Turn direction in game state is already flipped before animation (animation is cosmetic)
- VoiceOver fires
- Reduced Motion: no animation, VoiceOver still fires

---

### `checkingSoloPenalty`

**Entry conditions:** After all animations complete for a played move, the engine checks whether any Solo! violations occurred.

**Allowed actions:**
- `humanCallSolo` — human taps "Solo!" button (only valid if human's hand is at 1 and Solo! is pending)
- `systemSoloPenaltyApplied(PlayerID)` — internal: penalty drawn, back to normal flow
- `systemSoloWindowClosed` — internal: Solo! window expired without penalty

**Exit transitions:**
- If round-end condition met → `roundEnded`
- If human turn is next → `awaitingHumanTurn`
- If AI turn is next → `awaitingAITurn`

**Processing:**
1. Check whether any player's hand just dropped to 1 card.
2. For human: display "Solo!" button with countdown timer. If tapped in time → no penalty. If not tapped → apply +2 draw penalty.
3. For AI: auto-call Solo! after a simulated delay (no penalty).
4. Check whether Solo! penalty house rule is disabled (skip all penalty logic if so).
5. Check round-end conditions (see Win Conditions in game-rules.md).

**Persistence point:** Yes — if a Solo! penalty is applied, snapshot is written after penalty draw completes.

**Tests required:**
- Human Solo! button appears when hand drops to 1
- Human penalty applied when button not tapped within window
- AI always calls Solo! in time (no AI penalty)
- Solo! penalty house rule disabled: no button, no penalty, no timer
- Round ends correctly when both teammates' hands are empty
- Solo! check after Discard All correctly handles hand dropping from many cards to 0 (no Solo! needed) or to 1 (Solo! needed)

---

### `roundEnded`

**Entry conditions:** One team's win condition is satisfied (both hands empty, or one hand under single-out rule).

**Allowed actions:**
- `startNewRound` → `dealing`
- `endGame` → `gameEnded`
- `openPauseMenu` → `paused`

**Exit transitions:**
- `startNewRound` → `dealing`
- `endGame` → `gameEnded`
- `openPauseMenu` → `paused`

**UI prompt:** Round summary screen: "Team [X] wins the round!" If scoring is enabled: score breakdown for both teams. Options: "New Round" and "End Game."

**Persistence point:** Yes — round results and cumulative score snapshot written on entry.

**Tests required:**
- Winning team identified correctly
- Score calculated correctly for all card types when scoring is enabled
- "New Round" triggers deal with same configuration
- "End Game" navigates to `gameEnded`

---

### `gameEnded`

**Entry conditions:** `endGame` from `roundEnded`, or target score reached in scoring mode.

**Allowed actions:**
- `newGame` → `home`
- `openPauseMenu` → `paused`

**Exit transitions:**
- `newGame` → `home`
- `openPauseMenu` → `paused`

**UI prompt:** Game-over summary: overall winner (if scoring), final scores, match history. "New Game" button.

**Persistence point:** Yes — final game result snapshot written. Save file is then cleared (no resumable game).

**Tests required:**
- Final scores correct
- Save file cleared after game ends
- "New Game" returns to `home` with no save file

---

### `paused`

**Entry conditions:** User opens pause menu from any active game state (`awaitingHumanTurn`, `awaitingHumanDraw`, `awaitingHumanColourChoice`, `awaitingHumanTargetChoice`, `awaitingHumanTeamPassChoice`, `roundEnded`, `gameEnded`).

**Prior state:** The state machine records `priorState` on entry.

**Allowed actions:**
- `resumeGame` → restores `priorState`
- `saveAndQuit` → `home` (snapshot written)
- `abandonGame` → `home` (snapshot deleted)

**Exit transitions:**
- `resumeGame` → `priorState`
- `saveAndQuit` → `home`
- `abandonGame` → `home`

**UI prompt:** Pause overlay: "Game Paused." Options: Resume, Save & Quit, Abandon Game. House rule toggles visible (read-only during game). Card set and mode info visible.

**Persistence point:** Yes — `saveAndQuit` writes snapshot. `abandonGame` deletes snapshot.

**Tests required:**
- Pause available from all listed states
- Resume returns to exact prior state (including pending colour/target choices)
- Save & Quit writes snapshot and navigates home
- Abandon deletes snapshot and navigates home
- Pause not available during AI turn or animations (pause button hidden)

---

### `errorRecoverable`

**Entry conditions:** Any non-fatal error in the engine (invalid move submitted, snapshot write failure, draw pile empty after reshuffle, etc.).

**Allowed actions:**
- `dismissError` → `priorState`
- `retry` → re-attempts the failed operation

**Exit transitions:**
- `dismissError` → `priorState`
- `retry` → `priorState` (operation retried)

**UI prompt:** Error banner or modal: human-readable error description with Dismiss / Retry buttons. Does not block AI or interrupt the core game state.

**Persistence point:** No.

**Tests required:**
- Error shown when invalid move submitted
- Dismiss returns to `awaitingHumanTurn` unchanged
- Retry re-attempts snapshot write
- No unrecoverable crashes in any tested game flow

---

## Concurrency Notes

The engine is **fully synchronous** and **single-threaded** from the perspective of game logic:

- All `GameAction` values are processed on the **main actor**.
- The reducer is a pure function: `(GameState, GameAction) -> (GameState, [GameEffect])`. It has no side effects.
- `GameEffect` values (animations, autosave writes, AI think timers) are executed outside the reducer by the coordinator layer. They generate new `GameAction` values when complete, which are dispatched back through the normal action queue.
- AI computation at Expert difficulty (lookahead simulation) is dispatched to a background queue and returns a `systemAITurnReady` action on the main actor. The state machine remains in `awaitingAITurn` while the AI computes.
- No two actions are ever processed simultaneously. The action queue is strictly FIFO.

---

## Persistence Strategy

### Autosave Trigger States

Autosave is written (using `FileManager` + `Codable`) when entering these states:

| State | Reason |
|---|---|
| `dealing` (on completion) | Establishes round start baseline |
| `awaitingHumanTeamPassChoice` (on completion) | Team pass committed |
| `awaitingHumanTurn` | Start of human turn — most important checkpoint |
| `awaitingHumanDraw` | Card drawn — must persist which card was drawn |
| `awaitingHumanColourChoice` | Pending decision must survive backgrounding |
| `awaitingHumanTargetChoice` | Pending decision must survive backgrounding |
| `awaitingAITurn` | Start of AI turn — game state fully resolved |
| `checkingSoloPenalty` (after penalty applied) | Penalty draw committed |
| `roundEnded` | Round results committed |
| `gameEnded` | Final results committed |
| `paused` (Save & Quit) | Explicit user save |

### Snapshot Format

```
GameSnapshot (Codable)
├── schemaVersion: Int           // Increment on breaking changes
├── savedAt: Date
├── currentState: GameStateName  // The state enum case to restore to
├── pendingDecision: PendingDecision?
│   ├── type: .colourChoice | .targetChoice | .teamPassChoice
│   ├── pendingCard: CardID?
│   └── pendingTarget: PlayerID?
├── gameConfig: GameConfig
│   ├── mode: GameMode
│   ├── difficulty: AIDifficulty
│   ├── cardSet: CardSet
│   └── houseRules: HouseRuleSet
├── gameState: GameState
│   ├── players: [PlayerState]   // Hands, scores, seatPosition
│   ├── drawPile: [Card]
│   ├── discardPile: [Card]
│   ├── activeColour: CardColour
│   ├── turnDirection: TurnDirection
│   ├── currentPlayerIndex: Int
│   ├── soloFlags: [PlayerID: Bool]
│   └── roundScores: [TeamID: Int]
└── roundHistory: [RoundResult]
```

### Recovery from Corrupted Save

1. Attempt `JSONDecoder.decode(GameSnapshot.self, from: data)`.
2. If decoding fails (throws) → log error, delete save file, proceed to `home`.
3. If `schemaVersion` does not match current version → treat as corrupted.
4. If any required field is nil or out of range → treat as corrupted.
5. Never crash on corrupted save; always fall back to `home` gracefully.

### Pending Decision Resume

When the app is suspended mid-decision (colour choice or target choice):

1. The snapshot at `awaitingHumanColourChoice` or `awaitingHumanTargetChoice` contains `pendingDecision` with `pendingCard` set and `pendingColourChoice`/`pendingTarget` as nil.
2. On resume, `loadingSavedGame` reads the snapshot and restores to the correct awaiting state.
3. The UI re-presents the colour picker or target picker.
4. The human makes their choice fresh; it is applied to the pending card and resolution continues normally.
5. The partially-played card is already removed from the player's hand in the snapshot (it was removed in `resolvingHumanMove` which ran before the choice state was entered). If the choice is never completed and the game is abandoned, the card is simply lost — this is acceptable and rare.
