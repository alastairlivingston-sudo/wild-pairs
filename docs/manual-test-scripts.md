# Wild Pairs — Manual Test Scripts

> Last updated: 2026-06-21  
> How to use: run each script in order within its test session. Record pass/fail per step. A script is PASS only if every step passes. Record results in a test log with date, tester name, device/simulator, and OS version.

---

## MTS-001: First Launch Experience

**ID:** MTS-001  
**Title:** First launch experience  
**Prerequisites:** App has never been installed on this device/simulator; or app data has been fully reset via "Reset All Data" and app was force-quit  
**Device/Environment:** iPhone 15 simulator (iOS 17+) — primary; iPad Air simulator (iOS 17+) — secondary  
**Estimated duration:** 5 minutes  

### Steps

1. Install the app (or ensure it is freshly installed with no prior data).
2. Tap the Wild Pairs icon to launch the app.
3. Observe the launch screen / splash.
4. Observe the home screen that appears after launch.
5. Confirm the "Resume Game" button or option is absent (no saved game exists).
6. Confirm the "New Game" button is present and prominently visible.
7. Confirm the "Settings" button or navigation item is present.
8. Confirm the "Statistics" button or navigation item is present.
9. Confirm the "Rules" button or navigation item is present.
10. Tap "Statistics". Observe the stats screen.
11. Confirm all stat values show zero or "—" (no games played yet).
12. Return to home screen.
13. Confirm no network activity indicator appears in the status bar or anywhere in the app during this entire session.

### Expected results

- Step 2: App launches without crash or error dialog.
- Step 3: Launch screen is brief (< 2 seconds) and does not request any permission.
- Step 4: Home screen is presented cleanly with no loading spinner.
- Step 5: No "Resume Game" element is visible.
- Step 6: "New Game" button is clearly labelled and tappable.
- Step 7–9: All three navigation items are present and accessible.
- Step 10–11: Stats screen shows zeros or empty state; no crash.
- Step 12: Navigation back to home works correctly.
- Step 13: No network indicator, no permission dialog at any point.

### Pass criteria

All 13 steps produce the expected result. Any unexpected permission prompt, crash, network indicator, or missing UI element is a FAIL.

---

## MTS-002: First Game Onboarding Tutorial

**ID:** MTS-002  
**Title:** First game onboarding tutorial  
**Prerequisites:** MTS-001 passed; app on home screen with no saved game  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. From the home screen, tap "New Game".
2. Observe the game setup screen.
3. Confirm game mode options are displayed: Standard Teams, All-Wild Teams, Side-to-Side Teams.
4. Confirm difficulty options are displayed: Easy, Medium, Hard, Expert.
5. Confirm player configuration options are available.
6. If an onboarding tooltip or tutorial overlay appears, read through it and confirm the content is accurate and mentions card colours (Crimson, Cobalt, Jade, Amber) and the "Solo!" call.
7. Select Standard Teams mode.
8. Select Easy difficulty.
9. Keep default player names.
10. Start the game.
11. Observe the game table screen.
12. Confirm the discard pile top card is visible and shows colour and face value.
13. Confirm the human player's hand is displayed at the bottom of the screen.
14. Confirm the current player indicator shows it is the human's turn (or AI turn with appropriate indicator).
15. If a rules hint or first-move prompt appears, read it and confirm it is accurate.
16. Tap the "Rules" or "?" icon from within the game table screen.
17. Confirm the rules screen appears and covers game mechanics including action cards.
18. Close the rules screen and return to the game.

### Expected results

- Step 3: All three game modes are listed by name.
- Step 4: All four difficulty levels are listed.
- Step 6: If tutorial exists, colour names match exactly: Crimson, Cobalt, Jade, Amber; the going-out call is "Solo!", not any competitor term.
- Step 10: Game starts without error.
- Step 11–14: Game table presents all expected elements.
- Step 16–17: Rules screen is accessible from within the game and explains action cards.
- Step 18: Returning from rules does not change game state.

### Pass criteria

All steps produce expected results. Any reference to competitor game names or colours (Red, Blue, Green, Yellow, UNO, Mattel) is an automatic FAIL.

---

## MTS-003: 10-Turn Playthrough (Standard Teams)

**ID:** MTS-003  
**Title:** 10-turn playthrough in Standard Teams mode  
**Prerequisites:** MTS-002 passed; a Standard Teams / Easy game is running  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. With a Standard Teams / Easy game running, observe whose turn it is.
2. If it is an AI turn, confirm the AI plays automatically after a brief pause (< 3 seconds on Easy).
3. When it is the human's turn, look at the human hand and discard pile top card.
4. Identify at least one playable card (matching colour or number, or a Wild card).
5. Tap the playable card.
6. Confirm the card moves to the discard pile.
7. Confirm the discard pile top card updates to the played card.
8. Confirm the player's hand decreases by one card.
9. Confirm the turn passes to the next player.
10. Repeat steps 2–9 until 10 turns have been completed across all players (not just the human).
11. After 10 turns, confirm the game state is consistent: card count in hand + discard pile + draw pile = starting total.
12. Confirm no error dialogs appeared during play.
13. Confirm no permission prompts appeared during play.

### Expected results

- Steps 2: AI plays within 3 seconds.
- Steps 5–8: Card play animation completes; game state updates correctly.
- Step 9: Turn indicator advances to the correct next player given game direction.
- Step 11: Card count is consistent (no cards disappear or duplicate).
- Steps 12–13: Zero error dialogs, zero permission prompts.

### Pass criteria

All 13 steps produce expected results. Any card count discrepancy, missed turn, or stuck state is a FAIL.

---

## MTS-004: Full Round Completion (Standard Teams)

**ID:** MTS-004  
**Title:** Full round completion in Standard Teams mode  
**Prerequisites:** iPhone 15 simulator; fresh Standard Teams / Easy game  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 20 minutes  

### Steps

1. Start a Standard Teams / Easy game with default settings.
2. Play through the game, making valid moves each human turn (draw if no valid card).
3. When any player reaches 1 card in hand, confirm a "Solo!" prompt or indicator appears for that player.
4. If the human reaches 1 card, tap the "Solo!" button promptly.
5. Confirm the Solo! call is registered (no penalty applied).
6. If a teammate of the human team plays their last card, confirm the game does NOT end immediately.
7. Confirm the game ends only when BOTH members of a team have played all their cards.
8. Observe the win screen when a team completes.
9. Confirm the win screen names the winning team.
10. Confirm the win screen offers a "Play Again" and/or "Return to Home" option.
11. Tap "Play Again".
12. Confirm a new game starts (new deal, cards shuffled, hands reset).
13. Open Stats screen after returning to home. Confirm games-played count increased by 1.

### Expected results

- Step 3: Solo! prompt appears when a player reaches 1 card.
- Step 5: Solo! call registered without penalty.
- Step 6: Game continues when only one team member has emptied their hand.
- Step 7: Game ends when the second team member empties their hand.
- Step 8–10: Win screen is presented correctly with correct team name.
- Step 11–12: Play Again resets the game cleanly.
- Step 13: Statistics updated by 1 game.

### Pass criteria

All 13 steps produce expected results. A premature win declaration (one player out but partner still has cards) is an automatic FAIL.

---

## MTS-005: All-Wild Teams Full Round

**ID:** MTS-005  
**Title:** Full round in All-Wild Teams mode  
**Prerequisites:** iPhone 15 simulator; home screen  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 15 minutes  

### Steps

1. Start a new game with mode: All-Wild Teams, difficulty: Easy.
2. Observe the initial deal.
3. Confirm every card dealt to the human hand appears to be playable (All-Wild mode rule: every card is treated as a Wild or can match any colour).
4. On the human's first turn, confirm that all cards in hand are highlighted as playable options.
5. Play any card from hand.
6. Confirm the colour picker appears (since in All-Wild mode, every card played prompts a colour choice).
7. Choose a colour (e.g. Jade).
8. Confirm the active colour updates to Jade.
9. Confirm the AI players' turns proceed without error.
10. Play through to completion of the round.
11. Confirm the win condition is the same as Standard Teams (both team members empty their hands).

### Expected results

- Step 3–4: All cards are playable; no "no valid card" state occurs during normal play.
- Steps 6–8: Colour picker appears and correctly sets the active colour.
- Step 9: AI plays without error in All-Wild mode.
- Step 11: Win condition functions correctly.

### Pass criteria

All 11 steps produce expected results. If any card is shown as non-playable in All-Wild mode, it is a FAIL.

---

## MTS-006: Side-to-Side Teams Full Round with Team Pass

**ID:** MTS-006  
**Title:** Full round in Side-to-Side Teams mode including Team Pass card  
**Prerequisites:** iPhone 15 simulator; home screen  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 20 minutes  

### Steps

1. Start a new game with mode: Side-to-Side Teams, difficulty: Easy.
2. Observe the initial deal.
3. Play through turns until the human draws or is dealt a Team Pass card. If needed, use seeded tests to confirm Team Pass is in the deck. For this manual test, play until Team Pass naturally appears or until 20 turns have elapsed.
4. When a Team Pass card is available and playable, play it.
5. Confirm the Team Pass action prompts the player to choose one card from their hand to pass to their partner.
6. Select a card to pass.
7. Confirm the selected card leaves the human's hand.
8. Confirm the partner's hand size increases by 1 (the card is passed, not discarded).
9. Confirm the turn passes to the next player after the Team Pass action.
10. Continue playing to round completion.
11. Confirm win condition functions (both team members must empty their hands).

### Expected results

- Step 5: Team Pass prompts a card selection UI.
- Step 7: Selected card removed from human's hand.
- Step 8: Partner's hand count increases by 1.
- Step 9: Turn advances correctly after the pass.
- Step 11: Win condition works as in Standard Teams.

### Pass criteria

All 11 steps produce expected results.

---

## MTS-007: Each Difficulty Level — Verify Distinct AI Behaviour

**ID:** MTS-007  
**Title:** Verify distinct AI behaviour across Easy, Medium, Hard, Expert difficulty  
**Prerequisites:** iPhone 15 simulator; home screen  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 30 minutes (15–20 turns per difficulty)  

### Steps — Easy

1. Start a Standard Teams game with all AI players set to Easy.
2. Observe AI turn decisions over 15 turns.
3. Note: Easy AI should play the first valid card in hand without apparent strategy. Wild cards may be played even when other valid cards exist. Colour choices for Wilds appear random.

### Steps — Medium

4. Start a new game with all AI players set to Medium.
5. Observe AI turn decisions over 15 turns.
6. Note: Medium AI should prefer action cards when available. Wild cards should be played less freely than Easy.

### Steps — Hard

7. Start a new game with all AI players set to Hard.
8. Observe AI turn decisions over 15 turns.
9. Note: Hard AI should appear to track colour preferences. Draw Four Wild should be played less frequently and more tactically than Medium.

### Steps — Expert

10. Start a new game with all AI players set to Expert.
11. Observe AI turn decisions over 15 turns.
12. Note: Expert AI should appear to coordinate with its partner (e.g. playing a colour the partner appears to favour based on prior plays). Solo! calls should be timely. Expert should be noticeably more challenging to beat than Easy.
13. Across all four difficulties, confirm no AI player ever crashes or causes an error.
14. Confirm AI decision time is perceptually instant or very brief (< 3 seconds) on Easy, with Hard and Expert potentially taking slightly longer but still < 5 seconds per turn.

### Expected results

- Easy AI plays noticeably differently from Expert AI.
- No difficulty crashes or errors.
- Decision times are within acceptable bounds.

### Pass criteria

Distinct observable behaviour difference between Easy and Expert. Zero errors or crashes across all four difficulty tests.

---

## MTS-008: Colour Picker (Change Colour / Wild Card)

**ID:** MTS-008  
**Title:** Colour picker interaction after playing a Wild card  
**Prerequisites:** iPhone 15 simulator; a game in progress where the human has a Wild card in hand  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. From a game in progress, ensure the human has a Wild card (or Draw Four Wild) in hand. If not, draw cards until one appears.
2. Play the Wild card by tapping it.
3. Confirm a colour picker overlay appears.
4. Confirm the picker shows all four colours: Crimson, Cobalt, Jade, Amber.
5. Confirm the picker does not show Red, Blue, Green, or Yellow (competitor colour names must not appear).
6. Confirm no other action is possible while the colour picker is shown (game is correctly paused awaiting choice).
7. Tap "Cobalt" to select it.
8. Confirm the overlay dismisses.
9. Confirm the active colour indicator updates to Cobalt.
10. Confirm it is now the next player's turn.
11. Repeat steps 1–10 but choose "Crimson" this time. Confirm Crimson is set correctly.

### Expected results

- Step 3: Colour picker appears immediately after playing Wild card.
- Step 4: All four Wild Pairs colours are shown with correct names.
- Step 5: No competitor colour names appear anywhere.
- Step 6: No other taps are accepted while picker is shown.
- Steps 9–10: Active colour set correctly; turn advances.

### Pass criteria

All 11 steps produce expected results. Any competitor colour name is an automatic FAIL.

---

## MTS-009: Target Picker (Targeted Draw Card)

**ID:** MTS-009  
**Title:** Target picker interaction after playing a Targeted Draw card  
**Prerequisites:** iPhone 15 simulator; a game in progress where the human has a Targeted Draw card in hand  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. From a game in progress, ensure the human has a Targeted Draw card matching the current active colour or a Wild Targeted Draw (if applicable). Draw cards if needed.
2. Play the Targeted Draw card by tapping it.
3. Confirm a target picker overlay appears.
4. Confirm the picker lists all eligible targets (opponents, not the player's own partner in team modes — confirm the exact eligibility rule from game design).
5. Confirm the human player's own name is not listed as a target.
6. Tap one of the listed opponents as the target.
7. Confirm the overlay dismisses.
8. Confirm the targeted player draws 2 cards (hand count increases by 2).
9. Confirm the targeted player's turn is skipped.
10. Confirm the turn passes to the player after the skipped target.

### Expected results

- Step 3: Target picker appears immediately.
- Step 4–5: Eligible targets listed; self not listed.
- Steps 8–10: Target draws 2 cards and loses a turn.

### Pass criteria

All 10 steps produce expected results.

---

## MTS-010: Forced Swap Card

**ID:** MTS-010  
**Title:** Forced Swap card effect  
**Prerequisites:** iPhone 15 simulator; a game in progress where the human has a Forced Swap card  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. Ensure the human has a Forced Swap card matching the active colour.
2. Note the human's current hand size (count of cards).
3. Note the hand sizes of each other player (displayed as counts).
4. Play the Forced Swap card.
5. Confirm a target picker appears listing eligible swap targets.
6. Choose a target player.
7. Note the target player's hand size before confirming.
8. Confirm the swap.
9. Confirm the human's hand now contains the target's former cards (hand size equals the target's former hand size).
10. Confirm the target player's hand now contains the human's former cards (target's new hand size equals human's former hand size).
11. Confirm the turn advances correctly after the swap.

### Expected results

- Steps 9–10: Complete hand exchange; sizes swapped correctly.
- Step 11: Turn advances normally.

### Pass criteria

All 11 steps produce expected results. Any partial swap (only some cards exchanged) is a FAIL.

---

## MTS-011: Skip Two Card

**ID:** MTS-011  
**Title:** Skip Two card effect — two players skipped  
**Prerequisites:** iPhone 15 simulator; Standard Teams / Easy game with 4 players; human has a Skip Two card  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. Ensure the human has a Skip Two card matching the active colour. Note the current turn order (player 0 → 1 → 2 → 3 in clockwise direction).
2. It is the human's (player 0's) turn.
3. Play the Skip Two card.
4. Confirm player 1 is indicated as skipped (their turn is skipped without action).
5. Confirm player 2 is also indicated as skipped.
6. Confirm the turn passes to player 3 (the player two positions after the human in turn order).
7. Confirm player 3 takes their turn normally.
8. After player 3's turn, confirm the turn returns to the normal sequence (player 0 → 1 → 2 → 3).

### Expected results

- Steps 4–5: Two consecutive players skipped.
- Step 6: Turn correctly reaches player 3.
- Step 8: Normal turn order resumes.

### Pass criteria

All 8 steps produce expected results.

---

## MTS-012: Team Play Card

**ID:** MTS-012  
**Title:** Team Play card effect — both partners draw a bonus card  
**Prerequisites:** iPhone 15 simulator; Standard Teams / Easy game; human has a Team Play card  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. Note the hand sizes of the human and the human's partner before play.
2. Note the hand sizes of the two opponents.
3. Ensure the human has a Team Play card matching the active colour.
4. Play the Team Play card.
5. Confirm the human draws 1 bonus card (human's hand size increases by 1 relative to step 1).
6. Confirm the human's partner also draws 1 bonus card (partner's hand size increases by 1).
7. Confirm the opponents' hand sizes are unchanged.
8. Confirm the turn advances to the next player.

### Expected results

- Steps 5–6: Both team members' hands increase by exactly 1.
- Step 7: Opponents unaffected.
- Step 8: Turn advances normally.

### Pass criteria

All 8 steps produce expected results.

---

## MTS-013: Solo! Call by Human

**ID:** MTS-013  
**Title:** Human player successfully calls Solo! at the correct moment  
**Prerequisites:** iPhone 15 simulator; a game in progress where the human is close to going out  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Play through a game until the human has exactly 2 cards in hand.
2. Play one of the 2 cards (a valid move).
3. Confirm the human now has 1 card in hand.
4. Confirm a "Solo!" button or prompt appears (the window for calling Solo! has opened).
5. Tap the "Solo!" button promptly (within the allowed window).
6. Confirm the Solo! call is registered (visual or haptic confirmation).
7. Confirm no penalty cards are drawn.
8. Continue play. Eventually play the final card.
9. Confirm the human going out triggers the team win check (partner must also be out for win).

### Expected results

- Step 4: Solo! prompt appears when hand drops to 1 card.
- Steps 6–7: Solo! registered without penalty.
- Step 9: Win condition check is performed correctly.

### Pass criteria

All 9 steps produce expected results.

---

## MTS-014: Solo! Penalty (Forget to Call, Caught by AI)

**ID:** MTS-014  
**Title:** Human forgets to call Solo! and is caught by an AI opponent  
**Prerequisites:** iPhone 15 simulator; a game in progress  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Play through a game until the human has exactly 2 cards in hand.
2. Play one of the 2 cards (a valid move) — the human now has 1 card.
3. Do NOT tap the Solo! button. Wait.
4. Observe whether an AI player "catches" the human for failing to call Solo!. (In Easy mode, AI may not catch reliably — test at Medium or Hard for reliable catching.)
5. Confirm that when caught, the human receives a penalty (draws 2 cards).
6. Confirm the human's hand size increases by 2.
7. Confirm a visual or text indicator shows the penalty was applied.
8. Confirm the game continues normally after the penalty.

### Expected results

- Step 4: At Medium or Hard difficulty, AI catches the missing Solo! call.
- Step 5–6: Human receives 2-card penalty.
- Step 8: Game continues normally.

### Pass criteria

Steps 5–8 produce expected results at Medium difficulty. Note in results if Easy AI does not catch — this is acceptable by design.

---

## MTS-015: Save Mid-Game and Resume After App Close

**ID:** MTS-015  
**Title:** Game state saves and resumes correctly after app close  
**Prerequisites:** iPhone 15 simulator; a Standard Teams / Easy game in progress with at least 5 turns played  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Play a Standard Teams / Easy game for at least 5 turns. Note the following state: current player, discard pile top card colour and face, human's hand contents (count and card types).
2. Press the Home button (or use simulator Device menu → Home) to background the app.
3. Wait 5 seconds.
4. In the simulator, simulate app termination: Device → Force Quit (or Shift+Cmd+H twice on physical device).
5. Relaunch Wild Pairs from the app icon.
6. Confirm the home screen shows a "Resume Game" option.
7. Tap "Resume Game".
8. Confirm the game resumes to exactly the state noted in step 1: same current player, same discard pile top, same hand contents.
9. Continue playing for 3 more turns.
10. Confirm play proceeds normally after resume.

### Expected results

- Step 6: Resume option is present.
- Step 8: All noted state details match exactly.
- Steps 9–10: No post-resume errors or glitches.

### Pass criteria

All 10 steps produce expected results. Any state mismatch after resume is a FAIL.

---

## MTS-016: Airplane Mode — Full Game Without Network

**ID:** MTS-016  
**Title:** Full game played in airplane mode — verify zero network dependency  
**Prerequisites:** iPhone 15 simulator; home screen  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 20 minutes  

### Steps

1. Enable Airplane Mode: in the simulator, use Settings app → enable Airplane Mode. Or use the macOS menu bar Network Link Conditioner if available.
2. Return to Wild Pairs.
3. Confirm the app is still showing the home screen (no crash, no network error).
4. Start a new Standard Teams / Easy game.
5. Confirm the game starts without error.
6. Play 10 turns. Confirm all AI turns, card effects, and UI interactions work normally.
7. Background the app (Home button).
8. Wait 5 seconds.
9. Foreground the app.
10. Confirm the game resumes without error.
11. Complete the full round.
12. Observe the win screen. Confirm it appears without error.
13. Check the Stats screen. Confirm stats updated.
14. Disable Airplane Mode and confirm no retroactive sync or network call occurs.

### Expected results

- Step 3: App unaffected by airplane mode.
- Steps 5–13: All gameplay functions normally with zero network-related errors.
- Step 14: No network activity occurs when airplane mode is disabled (nothing to sync).

### Pass criteria

Zero network error dialogs, zero crashed, zero degraded functionality across all 14 steps.

---

## MTS-017: iPhone SE Layout (Smallest Supported)

**ID:** MTS-017  
**Title:** Layout verification on iPhone SE (smallest supported iPhone)  
**Prerequisites:** iPhone SE (3rd generation) simulator (iOS 17+) configured in Xcode  
**Device/Environment:** iPhone SE simulator (4.7" screen, 375×667 logical pixels)  
**Estimated duration:** 10 minutes  

### Steps

1. Launch Wild Pairs on the iPhone SE simulator.
2. Observe the home screen. Confirm all buttons are visible and not truncated. Confirm no UI element is cut off by screen edges.
3. Start a Standard Teams / Easy game.
4. Observe the game table. Confirm the discard pile, draw pile, and hand cards are all visible simultaneously.
5. Confirm card text is readable without magnification (card colour name, face value).
6. Confirm the hand cards are scrollable if they do not all fit in one row.
7. Play 5 turns. Confirm all taps register correctly (no hit targets too small to use with a fingertip).
8. Open the colour picker. Confirm all 4 colour buttons are visible and tappable without scrolling.
9. Open the rules screen. Confirm text is readable and scrollable.
10. Rotate to landscape. Confirm the layout adapts without truncation.

### Expected results

- Steps 2, 4–5: No truncation, overlap, or off-screen elements.
- Step 6: Hand cards scroll correctly if needed.
- Step 7: All taps register.
- Step 8: Colour picker fits on screen.
- Step 10: Landscape layout is correct.

### Pass criteria

All 10 steps produce expected results. Any off-screen UI element or unresponsive tap target is a FAIL.

---

## MTS-018: Large iPhone Layout (Pro Max)

**ID:** MTS-018  
**Title:** Layout verification on large iPhone (Pro Max)  
**Prerequisites:** iPhone 15 Pro Max simulator (iOS 17+)  
**Device/Environment:** iPhone 15 Pro Max simulator (6.7" screen)  
**Estimated duration:** 10 minutes  

### Steps

1. Launch Wild Pairs on the iPhone 15 Pro Max simulator.
2. Observe the home screen. Confirm the layout fills the screen appropriately without excessive empty space.
3. Start a Standard Teams / Easy game.
4. Observe the game table. Confirm cards are appropriately sized — not too small (wasted space) and not stretched or distorted.
5. Confirm the hand cards display comfortably.
6. Play 5 turns. Confirm all interactions work correctly.
7. Rotate to landscape. Confirm landscape layout uses the wide screen well.
8. Open Settings. Confirm settings list is legible and not excessively spaced.

### Expected results

- Step 2: No vast empty areas that suggest layout is not adapted for large screen.
- Steps 4–5: Cards are appropriately sized.
- Step 7: Landscape layout makes good use of the wide format.

### Pass criteria

All 8 steps produce expected results. Any obviously broken or unintentionally sparse layout is a FAIL.

---

## MTS-019: iPad Mini Layout

**ID:** MTS-019  
**Title:** Layout verification on iPad mini  
**Prerequisites:** iPad mini (6th generation) simulator (iOS 17+)  
**Device/Environment:** iPad mini simulator (8.3" screen)  
**Estimated duration:** 10 minutes  

### Steps

1. Launch Wild Pairs on the iPad mini simulator.
2. Observe the home screen. Confirm the layout uses a tablet-appropriate design (not simply a stretched iPhone layout).
3. Start a Standard Teams / Easy game.
4. Observe the game table. Confirm the tablet layout presents more game information simultaneously compared to iPhone (e.g. hand and table visible at once without scrolling).
5. Play 5 turns.
6. Rotate to landscape. Confirm landscape layout adapts correctly.
7. Open the rules screen. Confirm it is presented in a tablet-appropriate style (e.g. popover or wider sheet).

### Expected results

- Step 2: Tablet layout evident (not just stretched iPhone).
- Steps 4–5: Game playable and comfortable on iPad mini.
- Step 6: Landscape works correctly.

### Pass criteria

All 7 steps produce expected results.

---

## MTS-020: iPad Portrait Layout

**ID:** MTS-020  
**Title:** Layout verification on iPad in portrait orientation  
**Prerequisites:** iPad Air (5th generation) simulator (iOS 17+)  
**Device/Environment:** iPad Air simulator (10.9" screen), portrait  
**Estimated duration:** 10 minutes  

### Steps

1. Launch Wild Pairs on the iPad Air simulator in portrait orientation.
2. Observe the home screen. Confirm the layout is appropriate for the tall portrait aspect ratio.
3. Start a Standard Teams / Easy game.
4. Observe the game table. Confirm the portrait layout is well-organised.
5. Play 5 turns. Confirm all interactions work correctly.
6. Open Settings. Confirm settings screen is correct in portrait.
7. Open Rules. Confirm rules screen is correct in portrait.

### Expected results

- Steps 2, 4: Appropriate portrait layout.
- Steps 5–7: All screens function correctly.

### Pass criteria

All 7 steps produce expected results.

---

## MTS-021: iPad Landscape Layout

**ID:** MTS-021  
**Title:** Layout verification on iPad in landscape orientation  
**Prerequisites:** iPad Air (5th generation) simulator (iOS 17+)  
**Device/Environment:** iPad Air simulator, landscape  
**Estimated duration:** 10 minutes  

### Steps

1. Launch Wild Pairs on the iPad Air simulator in landscape orientation.
2. Observe the home screen. Confirm landscape layout is appropriate.
3. Start a Standard Teams / Easy game.
4. Observe the game table. Confirm landscape layout takes advantage of the wide format (e.g. player hands on sides, game table centred).
5. Play 5 turns. Confirm all interactions work correctly.
6. Open Settings. Confirm the settings screen uses a sidebar or two-column layout appropriate for landscape iPad.
7. Open Rules. Confirm the rules screen is appropriate for landscape.

### Expected results

- Steps 2, 4: Landscape-specific layout evident.
- Steps 5–7: All screens function correctly.

### Pass criteria

All 7 steps produce expected results.

---

## MTS-022: iPad Split View Narrow Layout

**ID:** MTS-022  
**Title:** Layout in iPad Split View (compact width) — no truncation  
**Prerequisites:** iPad Air simulator (iOS 17+); a second app to pair in Split View (e.g. Notes)  
**Device/Environment:** iPad Air simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Launch Wild Pairs on iPad Air simulator in full screen.
2. Enable Split View: swipe down from the top of the screen, tap the multi-window icon, and place another app (e.g. Notes) alongside Wild Pairs in a narrow (1/3 width) configuration.
3. Wild Pairs is now in compact-width mode (Split View narrow). Observe the home screen.
4. Confirm the home screen adapts to compact width — no truncation, no overflow.
5. Start a game from the compact-width home screen.
6. Observe the game table in compact width.
7. Confirm the hand cards and game controls are accessible (may scroll horizontally or wrap).
8. Play 3 turns. Confirm all taps register and no controls are hidden off-screen.
9. Return Wild Pairs to full screen. Confirm layout adapts back to full width immediately.

### Expected results

- Steps 3–4: Home screen adapts correctly to compact width.
- Steps 6–8: Game table is usable in compact width.
- Step 9: Full-screen layout restores correctly.

### Pass criteria

All 9 steps produce expected results. Any inaccessible control in compact width is a FAIL.

---

## MTS-023: App Rotation During Game (State Preserved)

**ID:** MTS-023  
**Title:** Rotating the device mid-game preserves game state  
**Prerequisites:** iPhone 15 simulator; a game in progress  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. Start a Standard Teams / Easy game. Play 3 turns. Note: current player, discard pile top card, human hand size.
2. Rotate the simulator to landscape (Hardware → Rotate Left or Cmd+Left).
3. Observe the game table in landscape. Confirm no crash.
4. Confirm the game state is identical to what was noted in step 1: same current player, same discard pile top, same hand size.
5. Play 1 turn in landscape orientation.
6. Rotate back to portrait (Cmd+Right).
7. Confirm the game state is correct after rotating back.
8. Play 1 turn in portrait orientation.
9. Confirm no state was lost at any rotation event.

### Expected results

- Steps 3–4: No crash; state preserved on rotation.
- Steps 6–7: State preserved on rotation back.
- Step 9: Game continues normally.

### Pass criteria

All 9 steps produce expected results. Any crash or state loss on rotation is a FAIL.

---

## MTS-024: VoiceOver — Full Game Navigation

**ID:** MTS-024  
**Title:** Play through a game using only VoiceOver navigation  
**Prerequisites:** Physical device or simulator with VoiceOver enabled; iPhone 15 simulator  
**Device/Environment:** iPhone 15 simulator with VoiceOver ON (Settings → Accessibility → VoiceOver)  
**Estimated duration:** 20 minutes  
**Note:** Enable VoiceOver in simulator Settings before launching Wild Pairs. Use standard VoiceOver gestures: swipe right/left to navigate elements, double-tap to activate.

### Steps

1. With VoiceOver enabled, launch Wild Pairs.
2. Swipe right through all home screen elements. Confirm VoiceOver reads each element with a meaningful label (e.g. "New Game, button", "Settings, button").
3. Confirm VoiceOver does NOT read any element as "button" or "image" without a descriptive label.
4. Navigate to and activate "New Game" via double-tap.
5. On the game setup screen, navigate all elements. Confirm game mode options, difficulty options, and start button are all reachable and labelled.
6. Start a Standard Teams / Easy game.
7. On the game table, swipe through all elements. Confirm: discard pile is labelled with its top card, draw pile is labelled, each hand card is labelled with its colour and face value, current player indicator is labelled.
8. Navigate to a playable card and activate it via double-tap.
9. Confirm the card is played and the game state announcement is made (e.g. VoiceOver announces the played card and whose turn it is next).
10. Play 5 turns using only VoiceOver.
11. Confirm no interactive element is unreachable by VoiceOver swipe navigation.

### Expected results

- Steps 2–3: All elements have meaningful accessibility labels.
- Steps 7: Game table elements are all labelled and reachable.
- Steps 8–10: Game is fully playable using VoiceOver only.
- Step 11: No orphaned interactive elements.

### Pass criteria

All 11 steps produce expected results. Any element that is interactive but not reachable by VoiceOver is a FAIL.

---

## MTS-025: VoiceOver — Hear Game Status on Demand

**ID:** MTS-025  
**Title:** Player can hear the current game status using VoiceOver without navigating through all cards  
**Prerequisites:** VoiceOver enabled; a game in progress (as set up in MTS-024)  
**Device/Environment:** iPhone 15 simulator with VoiceOver ON  
**Estimated duration:** 5 minutes  

### Steps

1. With a game in progress and VoiceOver on, locate the "Game Status" element (a summary region or accessibility announcement area, if implemented).
2. Navigate to the element and confirm VoiceOver reads: current player name, current active colour, number of cards in the draw pile, and the human's hand size.
3. If a dedicated "announce status" button exists, activate it and confirm the status announcement.
4. Confirm the discard pile top card is announced when focused.
5. Confirm each hand card announces its colour and face value when focused (e.g. "Skip card, Jade colour").

### Expected results

- Step 2: Status information is accessible without full card-by-card navigation.
- Step 5: Each card has a complete, accurate accessibility label.

### Pass criteria

Steps 2, 4, 5 produce expected results. Partial or absent card labels are a FAIL.

---

## MTS-026: Dynamic Type AX3 — All Text Readable

**ID:** MTS-026  
**Title:** All text remains readable with Dynamic Type set to AX3 (largest accessibility size)  
**Prerequisites:** iPhone 15 simulator; set Dynamic Type to AX3: Settings → Accessibility → Display & Text Size → Larger Text → drag slider to maximum  
**Device/Environment:** iPhone 15 simulator with Dynamic Type AX3  
**Estimated duration:** 10 minutes  

### Steps

1. With Dynamic Type at AX3, launch Wild Pairs.
2. Observe the home screen. Confirm all button labels are readable — no truncation (ellipsis) that cuts off meaning, no text overflowing its container.
3. Start a Standard Teams / Easy game.
4. Observe the game table. Confirm card labels (colour name, face value) are readable.
5. Confirm the current player indicator text is readable.
6. Confirm all controls (draw, pass, Solo!) are labelled readably.
7. Open Settings. Confirm all setting labels and toggle labels are readable.
8. Open Rules. Confirm rules text is scrollable and readable.
9. Open the colour picker. Confirm all four colour names are readable at AX3.

### Expected results

- All steps: No meaningful text is truncated. Text scales up with Dynamic Type. Layouts scroll or adapt rather than clipping text.

### Pass criteria

All 9 steps produce expected results. Any meaningfully truncated text is a FAIL.

---

## MTS-027: Large Card Mode — Enable and Play

**ID:** MTS-027  
**Title:** Enable Large Card mode and verify cards are more readable  
**Prerequisites:** iPhone 15 simulator; home screen  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 5 minutes  

### Steps

1. From the home screen, open Settings.
2. Locate the "Large Cards" toggle. Confirm it exists and is currently off.
3. Enable the "Large Cards" toggle.
4. Return to the home screen (or start a game directly).
5. Start a Standard Teams / Easy game.
6. Observe the hand cards. Confirm they are visually larger than in normal mode.
7. Confirm card text (colour name, face value, action name for action cards) is clearly readable.
8. Play 3 turns. Confirm the larger cards do not overlap other UI elements or clip off screen.
9. Return to Settings and disable Large Cards.
10. Confirm cards return to normal size.

### Expected results

- Step 6: Cards are visibly larger in Large Card mode.
- Step 7: All card text is readable.
- Step 8: Layout accommodates larger cards without overflow.
- Step 10: Normal size restored correctly.

### Pass criteria

All 10 steps produce expected results.

---

## MTS-028: Colour-Blind Mode — Verify No Colour-Only Information

**ID:** MTS-028  
**Title:** In Colour-Blind mode, all game information is conveyed without relying on colour alone  
**Prerequisites:** iPhone 15 simulator; Settings → enable Colour-Blind Mode  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Open Settings and enable Colour-Blind Mode.
2. Start a Standard Teams / Easy game.
3. Inspect each card in the human's hand. Confirm each card conveys its colour via a text label, pattern, or symbol in addition to (or instead of) the colour fill.
4. Inspect the discard pile top card. Confirm the active colour is conveyed via text or symbol, not colour alone.
5. Inspect the active colour indicator. Confirm it shows the colour name or a symbol alongside the colour swatch.
6. Play a Wild card. Open the colour picker. Confirm each colour option shows the colour name as text (not just a coloured circle).
7. Play 5 turns. Confirm at no point is the player required to distinguish colours visually without a text/symbol supplement.
8. Simulate squinting (or view the screen from a distance) to confirm the name-based labels make the game fully playable without perceiving colour differences.

### Expected results

- Steps 3–6: All colour information is conveyed by text or shape in addition to colour fill.
- Step 7: No colour-only information required.

### Pass criteria

All 8 steps produce expected results. Any game information conveyed exclusively by colour (no text/symbol supplement) is a FAIL.

---

## MTS-029: Reduced Motion — Verify All State Changes Legible

**ID:** MTS-029  
**Title:** With Reduced Motion enabled, all game state changes are legible without animation  
**Prerequisites:** iPhone 15 simulator; Settings → Accessibility → Motion → Reduce Motion ON  
**Device/Environment:** iPhone 15 simulator with Reduce Motion ON (system setting)  
**Estimated duration:** 10 minutes  

### Steps

1. Enable Reduce Motion at the system level: Settings → Accessibility → Motion → Reduce Motion (toggle ON).
2. Launch Wild Pairs.
3. Confirm the launch does not rely on a motion-dependent animation for the user to progress.
4. Start a Standard Teams / Easy game.
5. Play a card. Confirm the card moves to the discard pile without a long animation, but the state change is still clear (the card is now on the discard pile).
6. Draw a card. Confirm the draw is clear without requiring animation to understand what happened.
7. Observe an AI turn. Confirm the AI's card play is legible (the new discard pile top is visible immediately or with a minimal cross-fade).
8. Play through 5 turns. Confirm at every state change the new state is immediately visible without depending on animation to communicate it.
9. Check: does the shake animation for illegal card plays still appear in some reduced form? (Note result — it may be replaced by a static highlight.)

### Expected results

- Steps 3–8: All state changes are legible without flowing animations.
- Step 9: Illegal move feedback is still present (even if simplified).

### Pass criteria

All 9 steps produce expected results. Any state change that is ambiguous without animation is a FAIL.

---

## MTS-030: Fast AI Mode — Verify Speed

**ID:** MTS-030  
**Title:** Verify AI plays at an acceptable pace on all speed settings  
**Prerequisites:** iPhone 15 simulator; Settings accessible  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Open Settings. Locate the Animation Speed setting (or AI speed setting). Set to "Slow".
2. Start a Standard Teams / Expert game (all AI players).
3. Time 5 consecutive AI turns. Each AI turn should complete within 5 seconds in Slow mode.
4. Note whether the pace feels appropriately slow and watchable.
5. Open Settings mid-game (via pause or from a menu). Set Animation Speed to "Fast".
6. Resume the game. Time 5 consecutive AI turns. Each AI turn should complete within 1.5 seconds in Fast mode.
7. Confirm the game is still readable at fast speed (state changes visible, not just flickering).
8. Return to Normal speed. Confirm AI turns complete within 2–3 seconds.

### Expected results

- Step 3: Slow AI turns ≤ 5 seconds each.
- Step 6: Fast AI turns ≤ 1.5 seconds each.
- Step 7: Game readable at fast speed.
- Step 8: Normal speed ≤ 3 seconds per turn.

### Pass criteria

All 8 steps produce expected results.

---

## MTS-031: Rules/Help Comprehension

**ID:** MTS-031  
**Title:** A new player can understand the rules from the in-app rules screen  
**Prerequisites:** Fresh tester who has not played Wild Pairs before; iPhone 15 simulator  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 15 minutes  

### Steps

1. Hand the device/simulator to someone who has not played Wild Pairs. Ask them to open the Rules screen from the home screen.
2. Ask them to read the rules at their own pace.
3. Ask: "What colours are in the game?" — Expected answer: Crimson, Cobalt, Jade, Amber.
4. Ask: "What do you call out when you have one card left?" — Expected answer: "Solo!"
5. Ask: "What does the Skip card do?" — Expected answer: skips the next player's turn.
6. Ask: "What does the Draw Two card do?" — Expected answer: the next player draws 2 cards and loses their turn.
7. Ask: "When does a team win?" — Expected answer: when both team members have played all their cards.
8. Ask: "What is the Wild card for?" — Expected answer: can be played on any colour; the player chooses the new colour.
9. If the tester answers any question incorrectly, note which rule was unclear and record it as a finding.

### Expected results

- Steps 3–8: Tester correctly answers all questions from reading the rules screen alone.

### Pass criteria

Tester answers at least 5 of 6 game-mechanic questions correctly. Any wrong answer must be recorded as a rules-clarity finding.

---

## MTS-032: No Permission Prompts During Any Gameplay

**ID:** MTS-032  
**Title:** Verify zero permission prompts during a complete gameplay session  
**Prerequisites:** iPhone 15 simulator; fresh install or reset data; all system permissions for Wild Pairs reset to default (Settings → Wild Pairs → reset any previously granted permissions if any)  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 20 minutes  

### Steps

1. Launch Wild Pairs.
2. Navigate every screen accessible from the home screen (Settings, Stats, Rules) without starting a game.
3. Confirm no permission dialog appeared.
4. Start a Standard Teams / Medium game.
5. Play 10 turns. Confirm no permission dialog appeared at any point.
6. Play a Wild card. Open colour picker. Confirm no permission dialog.
7. Background the app. Wait 5 seconds. Foreground. Confirm no permission dialog.
8. Open Settings. Toggle Haptics on and off. Confirm no permission dialog (haptics do not require a permission prompt on iOS).
9. Open Settings. Toggle Colour-Blind Mode. Confirm no permission dialog.
10. Use Reset All Data. Confirm no permission dialog before, during, or after.
11. After reset, confirm no permission dialog when relaunching.

### Expected results

- All steps: Zero permission dialogs (camera, microphone, location, contacts, notifications, health, tracking, or any other system permission) appear at any point.

### Pass criteria

Zero permission prompts across all 11 steps. Any permission prompt is an automatic FAIL requiring immediate investigation.

---

## MTS-033: Reset Local Data

**ID:** MTS-033  
**Title:** Reset All Data flow — deletes data, resets to defaults, returns to home  
**Prerequisites:** iPhone 15 simulator; at least one completed game (stats > 0), a saved game in progress, and non-default settings applied  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 10 minutes  

### Steps

1. Complete at least one game so statistics are non-zero.
2. Start a game and play 5 turns, then background (to create a saveable mid-game state).
3. Open Settings. Apply a non-default setting (e.g. enable Colour-Blind Mode).
4. Navigate to the "Reset All Data" button in Settings.
5. Confirm a confirmation dialog appears before deletion begins.
6. Read the confirmation dialog. Confirm it warns the user that the saved game, all statistics, and settings will be deleted.
7. Tap "Cancel". Confirm no data was deleted (navigate back and confirm stats still non-zero, saved game still present, Colour-Blind Mode still on).
8. Return to "Reset All Data" and this time tap "Reset".
9. Confirm the app returns to the home screen.
10. Confirm "Resume Game" is absent from the home screen (no saved game).
11. Open Settings. Confirm Colour-Blind Mode is off (settings reset to defaults).
12. Open Stats. Confirm all statistics show zero or "—".
13. Confirm no error or crash occurred during the reset.

### Expected results

- Step 5: Confirmation dialog required before deletion.
- Step 7: Cancel prevents deletion.
- Steps 10–12: All three data files deleted; settings at defaults; statistics zeroed.
- Step 13: No errors.

### Pass criteria

All 13 steps produce expected results. Deletion without confirmation dialog is a FAIL. Partial deletion (some data remains) is a FAIL.

---

## MTS-034: Statistics Tracking Accuracy

**ID:** MTS-034  
**Title:** Statistics are tracked accurately across multiple games  
**Prerequisites:** iPhone 15 simulator; reset all data first (MTS-033) to start from zero  
**Device/Environment:** iPhone 15 simulator  
**Estimated duration:** 30 minutes  

### Steps

1. After a full data reset, confirm Stats shows: Total Games Played = 0, Total Games Won = 0, Current Win Streak = 0.
2. Play Game 1 (Standard Teams / Easy). Intentionally lose (let the AI team win).
3. Open Stats. Confirm: Total Games Played = 1, Total Games Won = 0, Current Win Streak = 0.
4. Play Game 2 (Standard Teams / Easy). Win (human team wins).
5. Open Stats. Confirm: Total Games Played = 2, Total Games Won = 1, Current Win Streak = 1.
6. Play Game 3 (Standard Teams / Easy). Win again.
7. Open Stats. Confirm: Total Games Played = 3, Total Games Won = 2, Current Win Streak = 2.
8. Play Game 4 (Standard Teams / Easy). Lose.
9. Open Stats. Confirm: Total Games Played = 4, Total Games Won = 2, Current Win Streak = 0, Longest Win Streak = 2.
10. Confirm per-mode stats for Standard Teams show Games Played = 4.
11. Play 1 game in All-Wild Teams mode.
12. Open Stats. Confirm Standard Teams still shows 4 games; All-Wild Teams shows 1 game (modes tracked separately).
13. Abandon (do not complete) a game mid-way. Return to home. Open Stats. Confirm the abandoned game did NOT count as a played game.

### Expected results

- Steps 3, 5, 7, 9: Exact stat values match as specified.
- Step 9: Longest Win Streak correctly records the prior streak of 2.
- Steps 10–12: Per-mode stats tracked independently.
- Step 13: Incomplete games not counted.

### Pass criteria

All 13 steps produce exact expected stat values. Any miscounted game, incorrect streak, or cross-contamination between mode stats is a FAIL.

---

## Test Log Template

Use this table to record results for each test session.

| Script ID | Title | Date | Tester | Device / Simulator | OS Version | Result | Notes |
|---|---|---|---|---|---|---|---|
| MTS-001 | First launch experience | | | | | Pass / Fail | |
| MTS-002 | First game onboarding | | | | | Pass / Fail | |
| MTS-003 | 10-turn playthrough | | | | | Pass / Fail | |
| MTS-004 | Full round completion | | | | | Pass / Fail | |
| MTS-005 | All-Wild Teams full round | | | | | Pass / Fail | |
| MTS-006 | Side-to-Side Teams + Team Pass | | | | | Pass / Fail | |
| MTS-007 | All difficulty levels | | | | | Pass / Fail | |
| MTS-008 | Colour picker | | | | | Pass / Fail | |
| MTS-009 | Target picker | | | | | Pass / Fail | |
| MTS-010 | Forced Swap card | | | | | Pass / Fail | |
| MTS-011 | Skip Two card | | | | | Pass / Fail | |
| MTS-012 | Team Play card | | | | | Pass / Fail | |
| MTS-013 | Solo! call by human | | | | | Pass / Fail | |
| MTS-014 | Solo! penalty | | | | | Pass / Fail | |
| MTS-015 | Save and resume | | | | | Pass / Fail | |
| MTS-016 | Airplane mode full game | | | | | Pass / Fail | |
| MTS-017 | iPhone SE layout | | | | | Pass / Fail | |
| MTS-018 | Large iPhone layout | | | | | Pass / Fail | |
| MTS-019 | iPad mini layout | | | | | Pass / Fail | |
| MTS-020 | iPad portrait layout | | | | | Pass / Fail | |
| MTS-021 | iPad landscape layout | | | | | Pass / Fail | |
| MTS-022 | iPad Split View narrow | | | | | Pass / Fail | |
| MTS-023 | Rotation during game | | | | | Pass / Fail | |
| MTS-024 | VoiceOver full game | | | | | Pass / Fail | |
| MTS-025 | VoiceOver game status | | | | | Pass / Fail | |
| MTS-026 | Dynamic Type AX3 | | | | | Pass / Fail | |
| MTS-027 | Large card mode | | | | | Pass / Fail | |
| MTS-028 | Colour-blind mode | | | | | Pass / Fail | |
| MTS-029 | Reduced motion | | | | | Pass / Fail | |
| MTS-030 | Fast AI mode | | | | | Pass / Fail | |
| MTS-031 | Rules comprehension | | | | | Pass / Fail | |
| MTS-032 | No permission prompts | | | | | Pass / Fail | |
| MTS-033 | Reset local data | | | | | Pass / Fail | |
| MTS-034 | Statistics accuracy | | | | | Pass / Fail | |
