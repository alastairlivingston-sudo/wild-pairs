# Wild Pairs — Complete Game Rules

> *Canonical sources: this document is authoritative for all game rules and rule defaults. For data models, `technical-architecture.md` §Model Reference is canonical. For visual tokens, `design-system.md`. Where any other document disagrees with this document on rules, this document wins.*

## TL;DR

Wild Pairs is an offline 2v2 team card game for four players (one human and three AI) where teammates must both empty their hands to win a round. Players match cards by colour, number, or action type, use special action cards to disrupt opponents or support their partner, and must call "Solo!" when reduced to one card or face a penalty draw. Three game modes, four difficulty levels, and a suite of house rules keep every session fresh.

---

## Overview

Wild Pairs is a fast-paced colour-and-number matching card game built around team strategy. You and your AI partner sit across from each other at the table while two AI opponents sit to your left and right. Your goal is to empty your hand — and make sure your partner empties theirs — before the opposing team does the same.

The game is inspired by the classic genre of shedding card games but uses original card colours, symbols, and mechanics. It is entirely offline with no accounts, no internet connection, and no ads.

**Who it is for:** Anyone who wants a satisfying single-player card game experience with meaningful team strategy. The three card sets range from a gentle beginner experience to an advanced game full of disruptive action cards.

---

## Setup

### Players and Teams

Wild Pairs is always played with exactly four players:

- **You** (human) — seated at the bottom of the table — **seat index 0**
- **AI Opponent 1** — seated to your left — **seat index 1**
- **Your AI partner** — seated opposite you (top of the table) — **seat index 2**
- **AI Opponent 2** — seated to your right — **seat index 3**

**Seat → Team mapping (all three modes):**

| Seat | Player | Team |
|---|---|---|
| 0 | Human | Team A |
| 1 | Left Opponent | Team B |
| 2 | AI Partner | Team A |
| 3 | Right Opponent | Team B |

Teams always alternate seats: seat 0 + seat 2 form Team A (Human + Partner); seat 1 + seat 3 form Team B (opponents). **This mapping is identical in all three game modes.** The name "Side-to-Side Teams" refers to the card-passing mechanic (passing a card to your partner), not to any change in the seating or team geometry.

> **Canonical:** This seat → team mapping is the single source of truth. `GameState` uses seat indices 0–3. `GameStateBuilder` fixtures and scenario tests must use `teams: [[0, 2], [1, 3]]`.

### Card Set Selection

Choose the card set before the game begins:

| Card Set | Contents |
|---|---|
| Beginner | Number cards (0–9), Skip, Reverse, Change Colour |
| Standard | All Beginner cards, plus Draw Two and Draw Four |
| Advanced | All Standard cards, plus Discard All, Targeted Draw, Forced Swap, Skip Two, and Team Play |

### Deck Composition

The following table gives the **canonical card count** for each set. `CardFactory` and `DeckTests` must use these exact numbers.

#### Beginner Deck — 60 cards

| Card type | Count per colour | Colours | Total |
|---|---|---|---|
| Number 0 | 1 | 4 | 4 |
| Number 1–9 | 1 each | 4 | 36 |
| Skip | 2 | 4 | 8 |
| Reverse | 2 | 4 | 8 |
| Change Colour | — (wild, no colour) | — | 4 |
| **Beginner total** | | | **60** |

#### Standard Deck — 72 cards (Beginner + 12)

| Card type | Count per colour | Colours | Total added |
|---|---|---|---|
| Draw Two | 2 | 4 | 8 |
| Draw Four | — (wild, no colour) | — | 4 |
| **Standard total** | | | **72** |

#### Advanced Deck — 96 cards (Standard + 24)

| Card type | Count per colour | Colours | Total added |
|---|---|---|---|
| Discard All | — (wild, no colour) | — | 4 |
| Targeted Draw | 2 | 4 | 8 |
| Forced Swap | 1 | 4 | 4 |
| Skip Two | 1 | 4 | 4 |
| Team Play | 1 | 4 | 4 |
| **Advanced total** | | | **96** |

**Draw pile after dealing** (4 players × 7 cards = 28 dealt):
- Beginner: 60 − 28 = 32 cards in draw pile
- Standard: 72 − 28 = 44 cards in draw pile
- Advanced: 96 − 28 = 68 cards in draw pile

> **Gate:** `DeckTests` must assert these exact counts per set and confirm that Advanced-only card types are absent from Beginner and Standard decks.

### Game Mode Selection

Choose one of three modes:

- **Standard Teams** — match by colour, number, or action type; the default mode
- **All-Wild Teams** — every card plays on every turn; pure action chaos
- **Side-to-Side Teams** — Standard Teams rules plus optional team-pass mechanic at round start

### Difficulty Selection

Choose the AI difficulty for all three AI players:

- **Easy** — AI plays a random valid card
- **Medium** — AI uses a basic heuristic (prefer action cards; hold wilds)
- **Hard** — AI uses a scored heuristic (values hand-size reduction, penalises leaving partner vulnerable)
- **Expert** — AI performs a lookahead simulation to select the highest-expected-value move
- **Master** — same strategy as Expert; rewards beating it with the highest score multiplier (see
  [Score Multiplier](#score-multiplier) below)

#### Score Multiplier

Winning a round against tougher AI is worth more. The points a team is awarded for winning a
round (see [Scoring Mode](#scoring-mode)) are multiplied by the difficulty of the toughest
opponent faced:

| Difficulty | Multiplier |
|---|---|
| Easy | x1 |
| Medium | x2 |
| Hard | x4 |
| Expert | x8 |
| Master | x24 |

### Dealing

- Shuffle the full deck for the selected card set.
- Deal **7 cards** to each player (28 cards total).
- Place the remaining cards face-down as the **draw pile**.
- Flip the top card of the draw pile to start the **discard pile**.
  - If the starting card is a wild-type card (Change Colour or Draw Four), shuffle it back and flip again.
- The human player (bottom seat) takes the first turn.
- Initial turn direction is **clockwise** (Human → Left Opponent → Partner → Right Opponent → repeat).

---

## Core Mechanics

### Matching Rules (Standard Teams Mode)

On your turn you must play a card that matches the top card of the discard pile in at least one of the following ways:

1. **Same colour** — your card shares the colour of the current discard top.
2. **Same number** — your card shares the number (for number cards).
3. **Same action type** — your card is the same action type as the discard top (e.g., a Skip played on a Skip).
4. **Wild-type card** — Change Colour and Draw Four cards may always be played regardless of the top card (subject to house rules for Draw Four).

The **current colour** is:
- The colour of the most recently played non-wild card, or
- The colour chosen by the most recent wild-card player if no non-wild card has been played since.

### Card Play Procedure

1. Select a valid card from your hand.
2. Place it face-up on the discard pile.
3. Resolve the card's effect (see Card Catalogue).
4. If you now hold exactly one card, call "Solo!" immediately (see Solo! Mechanic).
5. If your hand is now empty, declare victory for your turn (see Win Conditions).
6. Play passes to the next player in the current turn direction.

### Draw Procedure

If you have no valid card to play, you must draw one card from the draw pile. After drawing:

- If the drawn card is immediately playable, you **may** play it on the same turn.
- If the drawn card is not playable (or you choose not to play it), your turn ends and play passes to the next player.

You may never voluntarily draw when you have a legal play available (unless a house rule enables stacking — see House Rules).

---

## Turn Structure

Each player's turn proceeds in this exact order:

1. **Check for forced draw.** If an unresolved Draw Two or Draw Four penalty targets this player, they draw the required number of cards and lose their turn. (Unless draw stacking is enabled — see House Rules.)
2. **Check for skip.** If a Skip or Skip Two (that includes this player's seat) is in effect, this player loses their turn. No action is taken.
3. **Play or draw.** If the player has a valid card, they must play one. If they have no valid card, they draw one from the draw pile (then optionally play the drawn card if valid).
4. **Resolve card effect.** Apply the played card's effect immediately (see Card Catalogue).
5. **Solo! check.** If the player now holds exactly one card, they must call "Solo!" before the next player acts. Failure to call Solo! within the window results in a +2 draw penalty (see Solo! Mechanic).
6. **Empty-hand check.** If the player's hand is now empty, the round-end sequence begins (see Win Conditions).
7. **Advance turn.** Move to the next player in current turn direction (modified by any Reverse effect just applied).

---

## Card Catalogue

### Number Cards (0–9)

| Property | Value |
|---|---|
| Available in | Beginner, Standard, Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches current colour OR number matches top card's number |
| Effect | None — the card changes the active colour to its own colour |
| Solo!/penalty interaction | Normal — going to 1 card requires Solo! call |
| VoiceOver label | "Fire Five" / "Earth Zero" / etc. |
| In-app rules text | "Play this card if the top card shares its colour or number. No special effect." |

Number cards 0–9 exist in each of the four colours, giving 40 number cards in a full set (ten per colour: one 0 and one each of 1–9 per colour in Standard and Advanced; adjusted counts per card set configuration).

### Skip

| Property | Value |
|---|---|
| Available in | Beginner, Standard, Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Skip |
| Effect | The next player in turn order loses their turn entirely |
| Solo!/penalty interaction | Normal |
| VoiceOver label | "Fire Skip" |
| In-app rules text | "The next player loses their turn." |

When a Skip is played, the skipped player's turn is silently consumed. The turn then advances to the player after the skipped player.

### Reverse

| Property | Value |
|---|---|
| Available in | Beginner, Standard, Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Reverse |
| Effect | Turn direction flips (clockwise becomes counter-clockwise, and vice versa) |
| Solo!/penalty interaction | Normal |
| VoiceOver label | "Earth Reverse" |
| In-app rules text | "Turn direction reverses. If play was going clockwise, it now goes counter-clockwise, and vice versa." |

With four players, Reverse effectively changes who plays next. If it was Human → Left → Partner → Right, after Reverse it becomes Human → Right → Partner → Left.

### Change Colour (wild)

| Property | Value |
|---|---|
| Available in | Beginner, Standard, Advanced |
| Colour | None (wild) — displayed with all four colour segments |
| Matching rule | Can always be played regardless of current colour or top card |
| Effect | The player who plays this card chooses the new active colour |
| Solo!/penalty interaction | Normal |
| VoiceOver label | "Change Colour — choose new colour" |
| In-app rules text | "Play on any card. Choose the new colour for the next player to match." |

Change Colour cards have no base colour. After playing, the player selects Fire, Rain, Earth, or Wind; that becomes the required colour for the next player.

### Draw Two

| Property | Value |
|---|---|
| Available in | Standard, Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Draw Two |
| Effect | The next player draws 2 cards and loses their turn |
| Solo!/penalty interaction | Normal for the player playing it; the targeted player may fall below Solo! threshold after drawing — Solo! check applies to the targeted player at that moment |
| VoiceOver label | "Wind Draw Two" |
| In-app rules text | "The next player draws 2 cards and loses their turn." |

If draw stacking is enabled (house rule), the next player may play their own Draw Two (or Draw Four) to pass the cumulative penalty further down the chain.

### Draw Four (wild)

| Property | Value |
|---|---|
| Available in | Standard, Advanced |
| Colour | None (wild) |
| Matching rule | By default, can only be played when you have no other card that legally matches the current colour. (House rule: can be played anytime.) |
| Effect | Player chooses new active colour; the next player draws 4 cards and loses their turn |
| Solo!/penalty interaction | Normal for the player playing it; targeted player draws 4 |
| VoiceOver label | "Draw Four — choose new colour" |
| In-app rules text | "Play only when you have no other matching card (unless the 'Draw Four Anytime' house rule is on). Choose the new colour. The next player draws 4 cards and loses their turn." |

### Discard All

| Property | Value |
|---|---|
| Available in | Advanced |
| Colour | None (wild-type effect) — but matches colour of top card or can be played as colour-agnostic per mode |
| Matching rule | Play if current colour matches the colour you intend to discard, OR play as a wild in All-Wild mode |
| Effect | The player who plays it chooses a colour; they then discard ALL cards of that colour from their hand simultaneously. The discarded cards go to the discard pile (top card is the last one placed, which becomes the new top). |
| Solo!/penalty interaction | Critical — if discarding all cards of the chosen colour results in an empty hand, that is a valid win. If the player reaches exactly 1 card remaining after discarding, they must call Solo! |
| VoiceOver label | "Discard All — choose a colour to discard" |
| In-app rules text | "Choose a colour. Discard every card of that colour from your hand. If your hand is now empty, you go out." |

Note: The player chooses the colour to discard after playing the card, not before. The engine must prompt for colour selection mid-resolution.

### Targeted Draw

| Property | Value |
|---|---|
| Available in | Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Targeted Draw |
| Effect | The playing player chooses any single opponent; that opponent draws 2 cards |
| Solo!/penalty interaction | Normal; the targeted opponent's Solo! status is checked after they draw (if they were at Solo! before drawing, they are no longer) |
| VoiceOver label | "Earth Targeted Draw — choose an opponent" |
| In-app rules text | "Choose any opponent. That player draws 2 cards. (Does not skip their turn.)" |

Unlike Draw Two, Targeted Draw does **not** skip the targeted player's turn. The targeted player draws 2 cards and then takes their turn normally. This is the canonical rule; any test or document asserting a skip for Targeted Draw is incorrect and must be corrected.

### Forced Swap

| Property | Value |
|---|---|
| Available in | Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Forced Swap |
| Effect | The playing player chooses any other player (teammate or opponent). Both players swap their entire hands simultaneously |
| Solo!/penalty interaction | Both players' Solo! status is re-evaluated after the swap. If either player now holds exactly 1 card and did not hold 1 card before, they must call Solo! |
| VoiceOver label | "Fire Forced Swap — choose any player" |
| In-app rules text | "Choose any other player. You and that player swap your entire hands." |

A player may swap with their own partner. This can be a strategic move (giving the partner a better hand, or taking a partner's near-empty hand to go out faster).

### Skip Two

| Property | Value |
|---|---|
| Available in | Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Skip Two |
| Effect | The next two players in turn order each lose their turn |
| Solo!/penalty interaction | Normal |
| VoiceOver label | "Rain Skip Two" |
| In-app rules text | "The next two players each lose their turn." |

With four players, Skip Two effectively means both players on the opposing team (or, if direction has reversed, both players on your own team and partner — plan carefully).

### Team Play

| Property | Value |
|---|---|
| Available in | Advanced |
| Colour | Fire, Rain, Earth, or Wind |
| Matching rule | Play if colour matches OR top card is also a Team Play |
| Effect | Default rule: Both the playing player and their partner each immediately draw 1 card from the draw pile as a bonus draw. (Optional house rule variant: the partner may immediately play one card from their hand.) |
| Solo!/penalty interaction | Both players' Solo! status is re-evaluated after any draws or plays triggered by Team Play |
| VoiceOver label | "Wind Team Play" |
| In-app rules text | "You and your partner each draw 1 card from the draw pile. (With the house rule variant, your partner may immediately play one card instead.)" |

Team Play is double-edged: it gives both teammates more cards (potentially valuable), but may push either player above the Solo! threshold unexpectedly.

---

## Game Modes

### Standard Teams

**Matching rule:** A played card must match the discard top by colour, number, action type, or be a wild-type card (Change Colour, Draw Four). This is the core rule described throughout this document.

**Team mechanic:** Human + Partner form one team; Left Opponent + Right Opponent form the other. Both teammates must empty their hands to win the round (unless the single-out house rule is enabled).

**Win condition:** The round ends when both members of one team have empty hands. The other team loses the round. Score is calculated from the losing team's remaining cards (if scoring is enabled).

**Mode identifier:** `standardTeams`

---

### All-Wild Teams

**Matching rule:** Every card may be played on every turn, regardless of colour, number, or the top card of the discard pile. There are no colour or number restrictions.

**Action effects:** All action card effects (Skip, Reverse, Draw Two, Draw Four, etc.) still apply in full. The difference is only in what cards are legally playable — all of them, always.

**Team mechanic:** Identical to Standard Teams (2v2, alternating seats, single-out win by default).

**Strategy shift:** Without colour/number constraints, the game becomes a race to deplete hands through action cards. Action card selection becomes the primary decision. Wilds are less special since every card is effectively "wild."

**Wild-card colour choice:** When a Change Colour or Draw Four is played in All-Wild mode, the player still chooses the active colour — but since that colour does not restrict the next player's options, the colour choice primarily matters for any stacking interactions.

**Mode identifier:** `allWild`

---

### Side-to-Side Teams

**Base rules:** All Standard Teams rules apply (colour/number/action-type matching, same win conditions).

**Team Pass (optional, configurable):** At the very start of each round, after dealing but before the first card is played, each team may perform a team pass:

1. Each player privately selects exactly one card from their hand.
2. Both players on the team reveal and exchange their selected cards simultaneously (the exchange is face-down from the perspective of opponents — opponents cannot see which card was passed).
3. The team pass phase ends; play begins normally.

Team pass is optional per team. A team may decline to pass. The house rule setting controls whether team pass is available at all.

**Team communication:** See [Team Communication Rules](#team-communication-rules) — partner hands are open between teammates; opponent hands remain hidden. The Team Pass card choice above is the one exception made privately, before either teammate sees the other's selection.

**Team play cards in Side-to-Side mode:** Team Play cards in this mode may use the partner-plays-immediately variant (configurable as a house rule).

**Mode identifier:** `sideToSide`

---

## Win Conditions

### Standard Win (Single-Out)

The round ends immediately the moment **any** player empties their hand — an individual
achievement that credits their whole team with the round. This is the default for all three game
modes (`standardTeams`, `allWild`, `sideToSide`).

The winning team scores zero for the round. The losing team's score (if scoring is enabled)
equals the sum of face values of all cards remaining in every other player's hand, multiplied by
the [score multiplier](#score-multiplier) of the toughest AI opponent faced.

### Round Timer Fallback (Lowest Score Wins)

Every round also runs a **3-minute wall-clock timer** (`RuleProfile.roundTimeLimitSeconds`,
default 180 seconds). Emptying your hand still wins immediately regardless of time left on the
clock — the timer is a fallback, not a replacement, for when nobody empties their hand in time.

If the timer elapses with the round still in progress, the round is decided by score instead: the
player holding the **lowest card-point total** wins, crediting their team. Ties break by fewest
cards remaining, then by lowest seat position. The winning team is awarded the combined card-point
value of every other player's hand, multiplied by the toughest opponent's
[score multiplier](#score-multiplier).

Each individual move also has a **10-second limit** (`RuleProfile.moveTimeLimitSeconds`, default
10 seconds) for the local human player — AI already moves well within this window via its
think-delay. If the human doesn't act in time, the engine plays a random legal card on their
behalf (or draws, if none exists) — the same fallback `EasyAI` uses.

### Both-Teammates-Out House Rule

When `winCondition` is set to `.bothTeammatesOut` (not the default — opt in explicitly), the round
instead requires **both** members of a team to empty their hands before it ends:

- Player A empties their hand on their turn, then Player B (their teammate) empties their hand on a subsequent turn.
- A single action (e.g., Discard All emptying the hand) causes both players to go out simultaneously only in edge cases — the engine resolves both players' out-states and declares the win.

The round timer fallback above still applies under this house rule.

### Scoring Mode

When scoring is enabled:

| Card type | Points |
|---|---|
| Number cards (0–9) | Face value (0 = 0 pts, 9 = 9 pts) |
| Action cards (Skip, Reverse, Draw Two, Skip Two, Targeted Draw, Forced Swap, Team Play, Discard All) | 20 points each |
| Wild cards (Change Colour, Draw Four) | 50 points each |

Points are tallied from the losing side's remaining cards and multiplied by the
[score multiplier](#score-multiplier) of the toughest AI opponent faced. Play continues over
multiple rounds until one team reaches a target score threshold (configurable) or a fixed number
of rounds is completed.

### Game End

The game ends when:
- A target score is reached (scoring mode), or
- A fixed round count is completed (scoring mode), or
- The player manually ends the game from the pause menu.

---

## Solo! Mechanic

### Rule

When a player plays a card that reduces their hand to exactly **one card**, they must declare "Solo!" before the next player takes any action (including drawing).

### Penalty

If a player fails to call "Solo!" and any other player notices before the Solo!-holding player's next turn begins, the caught player draws **2 cards** as a penalty.

The window for catching a Solo! failure closes when:
- The Solo!-holding player begins their next turn (draws or plays their next card), or
- The round ends.

### Engine Handling

The app tracks Solo! status automatically:
- When a player's hand count drops to 1, the engine flags that player as needing a Solo! declaration.
- For human players: a "Solo!" button appears (and VoiceOver announces the prompt). The human must tap it within the timeout window. **The call is manual — it is never fired automatically for the human player.**
- For AI players: the AI automatically calls Solo! with a short simulated delay (to feel natural).
- If the human fails to tap Solo! within the timeout, the penalty is applied automatically.

**Solo! timeout default: 5 seconds.** This is the value returned by all `RuleProfile` factory methods. It is configurable via `RuleProfile.soloCallTimeoutSeconds`; future house-rule UI may expose it. A timeout of 0 means no time limit (but the penalty still applies if an opponent calls the catch before the next turn).

### Solo! Disabled (House Rule)

When the Solo! penalty is disabled, no penalty is applied for failing to call Solo! The Solo! call becomes optional/cosmetic.

### VoiceOver

- When a player's hand drops to 1: VoiceOver announces "[Player name] has one card left — call Solo!"
- When a player calls Solo!: VoiceOver announces "[Player name] called Solo!"
- When a penalty is applied: VoiceOver announces "[Player name] did not call Solo! — drawing 2 cards."

---

## Team Rules

### Why It's an Individual Race by Default

Wild Pairs is a cooperative-competitive game: you and a partner share a win, but the win itself is
triggered by individual play — whoever empties their hand first (or, failing that, holds the
lowest score when the round timer expires) carries the team. For a more traditional Uno-style
"both of us must finish" feel, with the strategic depth of one player going out first and
watching their partner finish alone, enable the **Both-Teammates-Out house rule**.

### Partner Goes Out First

By default (single-out), the round ends the instant one player empties their hand — their
partner doesn't need to. Under the **Both-Teammates-Out house rule**:
- That player is out of the round.
- Their partner continues playing alone against two opponents.
- The round only ends when the partner also empties their hand.
- The player who went out first cannot be targeted by Targeted Draw, Forced Swap, or similar cards once they are out.

### Team Communication Rules

**Open partner hands (canonical).** Teammates play with open hands between each other: each
player can see their partner's hand contents in full, at all times. This is a deliberate
teamwork mechanic, not a leak — Wild Pairs is cooperative-competitive, and seeing your partner's
hand is how you coordinate which colour to steer toward, when to hold a Draw Four, and when to
set up their out. The rule applies symmetrically: the human sees the AI partner's hand, and the
AI partner equally "sees" the human's hand and may use it when choosing moves, colours, and
targets (see `AIObservation.partnerHand` and the fairness note below).

Opponent hands remain hidden. Players (human and AI alike) may observe about opponents only:
- How many cards each player holds (visible at all times).
- Which cards have been played (visible in the discard pile).

Players may NOT signal anything about an opponent's hand beyond the above, and may NOT use any
information besides what this section grants. In Side-to-Side mode, the Team Pass card choice is
still made privately per-player, simultaneously, before either teammate sees the other's pass
selection.

---

## House Rules Catalogue

All house rules default to OFF unless otherwise noted.

| House Rule | Default | Effect |
|---|---|---|
| Draw Four Anytime | OFF | Draw Four can be played on any card regardless of whether the player has another legal play. Default requires no other legal play. |
| Both-Teammates-Out Win | OFF | Round ends only when both teammates empty their hands, not the single-out default. |
| Draw Stacking | OFF | Players may stack Draw Two and Draw Four penalties. The target player must either play their own Draw Two/Four to pass the cumulative penalty, or draw the full stack. When stacking, colour-matching still applies (Draw Two stacks onto Draw Two/Four, etc.). |
| Solo! Penalty Disabled | OFF | No penalty for failing to call Solo!. |
| Team Pass (Side-to-Side) | ON (when mode is Side-to-Side) | At round start, each team may privately swap one card between partners before play begins. Setting to OFF disables this phase entirely. |
| Partner Plays Immediately (Team Play variant) | OFF | When a Team Play card is played, the partner immediately plays one card from their hand instead of drawing a card. Both players draw if this rule is OFF. |
| Scoring Enabled | OFF | Enable round-by-round scoring and track cumulative score across rounds. |

### RuleProfile Factory Defaults

The following table gives the **exact field values** returned by each `RuleProfile` factory method. Phase 2 must implement these without deviation; the `RuleProfileTests` suite asserts each field value.

| Field | `standardTeams()` | `allWild()` | `sideToSide()` | Notes |
|---|---|---|---|---|
| `initialHandSize` | 7 | 7 | 7 | Cards dealt per player |
| `winCondition` | `.singleOut` | `.singleOut` | `.singleOut` | Default; Both-Teammates-Out is a house rule |
| `targetScore` | 0 | 0 | 0 | 0 = single-round, no cumulative score |
| `mustPlayAfterDraw` | `true` | `true` | `true` | Player must play drawn card if legal |
| `drawUntilPlayable` | `false` | `false` | `false` | Draw stacking off by default |
| `stackDrawCards` | `false` | `false` | `false` | House rule; default OFF |
| `drawFourRestrictedToNone` | `true` | `true` | `true` | Draw Four requires no other legal play |
| `discardAllEnabled` | `false` | `false` | `false` | Advanced card; controlled by `cardSet` |
| `targetedDrawEnabled` | `false` | `false` | `false` | Advanced card; controlled by `cardSet` |
| `forcedSwapEnabled` | `false` | `false` | `false` | Advanced card; controlled by `cardSet` |
| `skipTwoEnabled` | `false` | `false` | `false` | Advanced card; controlled by `cardSet` |
| `teamPlayEnabled` | `false` | `false` | `false` | Advanced card; controlled by `cardSet` |
| `cardSet` | `.standard` | `.standard` | `.standard` | UI selection overrides this |
| `teamPassEnabled` | `false` | `false` | `true` | ON by default in Side-to-Side |
| `teamPassCooldown` | 0 | 0 | 0 | 0 = available every round |
| `soloCallEnabled` | `true` | `true` | `true` | Solo! penalty on by default |
| `soloCallPenaltyCards` | 2 | 2 | 2 | Cards drawn if caught without calling |
| `soloCallTimeoutSeconds` | 5 | 5 | 5 | Seconds before auto-penalty |
| `partnerPlaysImmediately` | `false` | `false` | `false` | Team Play house-rule variant; default OFF |
| `scoringEnabled` | `false` | `false` | `false` | Multi-round scoring; default OFF |
| `maxTurnsPerRound` | 300 | 300 | 300 | Stuck-game safety cap |
| `roundTimeLimitSeconds` | 180 | 180 | 180 | Round timer fallback (lowest score wins) |
| `moveTimeLimitSeconds` | 10 | 10 | 10 | Per-move limit for the local human |

> **Note on advanced card fields:** `discardAllEnabled`, `targetedDrawEnabled`, etc. are set to `false` in all factory defaults because advanced card enablement is driven by the `cardSet` field. When `cardSet == .advanced`, the engine enables all advanced card types regardless of these flags. The flags allow individual advanced cards to be disabled independently (post-MVP customisation).

---

## Turn Direction and Skip Logic

### Reverse with Four Players

Turn direction at game start is **clockwise**: Human (bottom) → Left Opponent → Partner (top) → Right Opponent → Human → …

When a Reverse card is played, direction becomes **counter-clockwise**: Human (bottom) → Right Opponent → Partner (top) → Left Opponent → Human → …

Another Reverse switches back to clockwise. The current direction is always visible in the UI.

### Skip Logic

When a Skip is played:
1. The next player in the current turn direction is marked as skipped.
2. That player's turn token is consumed without them taking any action.
3. Turn advances to the player after the skipped player in the current direction.

A skipped player does not draw, does not play, and does not trigger Solo! — their turn is simply consumed.

### Skip Two Logic

Skip Two skips the **next two** players in turn order:
1. The first player after the Skip Two player is skipped.
2. The second player after the Skip Two player is also skipped.
3. The third player (the one who would have been the Skip Two player's "next-next-next") takes the next turn.

With four players, Skip Two always skips two consecutive players. Because opponents and teammates alternate seats, a Skip Two played by the human always skips Left Opponent and Partner (the next two in clockwise order), landing on Right Opponent — skipping the human's own partner. Players should be strategic about when to use Skip Two.

---

## Draw Pile Exhaustion

When the draw pile is exhausted and a player needs to draw:

1. **Collect all discard pile cards except the top card.** The top card stays in place as the new discard pile starter.
2. **Shuffle** the collected cards thoroughly.
3. **Place** the shuffled cards face-down as the new draw pile.
4. **Continue** play — the player who triggered the reshuffle now draws from the new draw pile.

If after reshuffling the draw pile is still empty (extremely rare — only if all cards are in players' hands), the player who needs to draw skips their draw and their turn ends without drawing.

---

## Glossary

| Term | Definition |
|---|---|
| Active colour | The colour that the next player must match (or use a wild to override). Set by the most recently played non-wild card, or chosen by the most recent wild-card player. |
| All-Wild mode | The game mode where every card is legally playable on every turn. |
| Wind | One of the four card colours. Symbol: Gust. |
| Rain | One of the four card colours. Symbol: Wave. |
| Fire | One of the four card colours. Symbol: Flame. |
| Current top | The top-most face-up card on the discard pile, used to determine what may be played next. |
| Discard pile | The face-up pile of cards that have been played. |
| Draw pile | The face-down pile of remaining cards not yet in play. |
| Forced Swap | Action card: both the playing player and a chosen player exchange entire hands. |
| Go out | To play the last card from one's hand, resulting in an empty hand. |
| House rule | An optional rule variant that modifies the standard game rules, configurable in app settings. |
| Earth | One of the four card colours. Symbol: Crystal. |
| Round | A single game from dealing to one team emptying both hands. A full game session may span multiple rounds. |
| Side-to-Side mode | The game mode that adds an optional team pass phase at round start. |
| Skip | Action card: the next player loses their turn. |
| Skip Two | Advanced action card: the next two players each lose their turn. |
| Solo! | The required declaration when a player's hand is reduced to exactly one card. |
| Standard Teams mode | The default game mode with full colour/number/action-type matching rules. |
| Team pass | In Side-to-Side mode: the optional exchange of one card between teammates at round start. |
| Wild-type card | A card with no base colour that can be played on any card (Change Colour, Draw Four). Also called a wild. |
