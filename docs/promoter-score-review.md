# Promoter Score Review

> Owner: ux-lead | Run: Phase 1 | Applied to specs: yes

## Purpose
For each of the 10 user personas, answer: "Would this person recommend the app or keep playing it?"
Score 0–10. Explain what delights, frustrates, would make them stop, and what must improve before implementation.

Scale: 0 = would never recommend / stop immediately; 10 = strong promoter / plays constantly.

---

## Persona 1 — Casual Player

**Score: 9 / 10**

**What delights them:**
- Quick Play gets into a game in one tap
- Cards are immediately readable — big symbols, clear colours
- AI partner "feels like help" even on Easy difficulty — they never feel alone
- Winning animation (confetti burst) is satisfying
- No account, no ads, no popups — pure game

**What frustrates them:**
- If AI turns take too long (Easy default 0.3s + animation), they feel impatient
- If they forget the team win condition and think they won when partner still has cards, the confusion breaks the fun moment
- Statistics screen feels unnecessary to them — they just want to play again

**What would make them stop:**
- Confusing UI on the game table (prompt is unclear)
- Any permission prompt appearing unexpectedly
- App feels slow or laggy on their phone
- Losing multiple times without understanding why

**Must improve before implementation:**
- Easy AI thinking delay should feel snappy (combined card play under 0.8s including animation)
- When human goes out first, the prompt "Your partner is still playing!" must be immediate and celebratory-adjacent, not a disappointment
- Round end screen must have a prominent "Play Again" button, not just "Home"

**Score rationale:** Quick Play + no friction + satisfying AI partner = strong promoter. Small frustrations around timing and round-end flow are solvable. Kept at 9 because the tutorial is optional — if they skip it and are confused by team win condition, they might not return.

---

## Persona 2 — Strategic Player

**Score: 9.5 / 10**

**What delights them:**
- Expert AI makes genuine team-aware decisions — feels like a worthy opponent
- Multi-factor move scoring means AI doesn't blindly play the first legal card
- Three modes offer distinct strategic challenges — All-Wild mode especially different from Standard
- House rules allow custom configurations for higher replayability
- Side-to-Side team pass mechanic adds genuine pre-round strategy

**What frustrates them:**
- No event log or history to review past moves (not in MVP)
- No way to see exactly what the AI was "thinking" (debug mode would satisfy this)
- Simulation win rates are not shown to the user — they have to just trust that Expert > Hard

**What would make them stop:**
- AI makes an obviously dumb move (plays wild card when it has 10 of the matching colour)
- Expert AI beats them 95%+ of the time — feels unfair, not satisfying
- Game gets stuck or hits an infinite state

**Must improve before implementation:**
- Hard/Expert AI must demonstrate visibly clever play (save Draw Four for urgent moments, help partner when they have 1 card)
- Round end screen should show what card the winning player went out on, and partner's card count at end
- Post-round: simple "why did we win/lose" summary — which card clinched it

**Score rationale:** The AI design is thorough — four difficulty levels, move scoring framework, team awareness. The lack of a game log is a deliberate MVP deferral. Expert players can see AI decisions through the result announcement text. Would be a strong promoter because it's one of the only offline team card games with genuine AI strategy.

---

## Persona 3 — First-Time Card Game Player

**Score: 8 / 10**

**What delights them:**
- Tutorial explains everything step by step — no manual needed
- Illegal card tap gives a friendly explanation, not a harsh error
- On Easy difficulty, the AI partner is clearly helping them
- The "Solo!" call feels like a fun mechanic, not a penalty

**What frustrates them:**
- First game is often confusing — too many things to track (whose turn, what colour, partner vs opponent)
- "Both teammates must empty hands" is not intuitive — standard card games end when ONE player goes out
- Without hints, they might not know they can tap an illegal card to understand why

**What would make them stop:**
- Losing their first 3 games without understanding what they could have done better
- AI partner does something they don't understand (swaps hands with opponent without explanation)
- Tutorial disappears and they can't re-access it

**Must improve before implementation:**
- Hints must be on by default for new players (first 5 games)
- When AI partner takes any action card (Forced Swap, Targeted Draw), the result text must be explained, not just announced: "Partner used Forced Swap — they took the opponent's hand! The opponent now has more cards."
- "Help" button on game table must be obvious (not hidden in a menu)
- Tutorial must be re-accessible from Settings

**Score rationale:** The onboarding is better than most card games. The team win condition is the key risk — if not communicated clearly, the first few games feel arbitrary. Improvements to hint default and AI action explanations should bring this to 9+.

---

## Persona 4 — Older or Low-Vision Player

**Score: 9 / 10**

**What delights them:**
- Large card mode increases card size significantly
- Card names are text, not just colour/symbol — always readable
- Dynamic Type support means their system font settings apply automatically
- No need to create an account or navigate complex menus
- Game is forgiving — no time pressure, no timer

**What frustrates them:**
- On iPhone SE with many cards in hand, cards may still feel small even with large card mode if the hand doesn't scroll smoothly
- High contrast mode is system-level (they've enabled it in iOS Settings) — app must respect `isDarkerSystemColorsEnabled`
- If reduced motion is on (common for this persona), the game must still be clear — some apps hide information in animation

**What would make them stop:**
- Any control that's under 44×44pt tap target
- Card text that clips or truncates at their Dynamic Type size
- Confusion about which AI player is which (need clear player labels, not just seating position)

**Must improve before implementation:**
- Player labels must be always visible (not just on hover/tap): "You", "Partner", "Left Opponent", "Right Opponent"
- All player zone labels must remain visible at AX5 Dynamic Type
- Haptics should accompany all major game events for users who might miss visual changes

**Score rationale:** The accessibility design is comprehensive for this persona. Large cards, Dynamic Type, high contrast, reduced motion — all specified. Player labelling improvement is important for orientation. Would be a loyal user who appreciates the care taken.

---

## Persona 5 — Colour-Blind Player

**Score: 10 / 10**

**What delights them:**
- The game is already colour-blind safe by default — symbols (Flame, Wave, Leaf, Sun) are always visible
- Colour names are always shown in text (action prompts say "Cobalt" not just show a blue chip)
- Colour-blind mode adds pattern fills as an additional layer — belt and braces
- The four chosen colours (Crimson, Cobalt, Jade, Amber) have been chosen with deuteranopia contrast in mind

**What frustrates them:**
- Nothing significant, given the default design

**What would make them stop:**
- If the colour indicator ever showed only a coloured circle without the colour name
- If a new card type was added in future without a colour-safe design

**Must improve before implementation:**
- Colour indicator (current colour chip) must always show both the coloured chip AND the colour name text
- All AI action announcements must use colour names in text: "Partner changed colour to Cobalt" not just a Cobalt animation

**Score rationale:** This is the best-served persona in the design. Colour-blindness was treated as a default design constraint, not an accessibility afterthought. Pattern fills in colour-blind mode provide a third layer of distinction beyond colour and symbol.

---

## Persona 6 — VoiceOver User

**Score: 9 / 10**

**What delights them:**
- Every card has a complete, actionable VoiceOver label including playability status
- Live region announcements keep them informed of all game events
- Custom actions ("Play card", "Card details", "Draw card", "Call Solo!") allow efficient play
- Focus order is logical and consistent
- Game status can be read on demand ("Game status" custom action)

**What frustrates them:**
- During AI turns, there's a waiting period — VoiceOver may not announce anything for 0.3–1.2 seconds
- If focus moves unexpectedly after an AI action, they have to re-orient
- If the tutorial overlay disrupts the VoiceOver focus order, first use is confusing

**What would make them stop:**
- Having to navigate past decorative elements to reach game controls
- Any AI action that changes game state without a VoiceOver announcement
- Focus trap (app state changes but VoiceOver focus stays on an old element)

**Must improve before implementation:**
- During AI thinking delay, VoiceOver reads: "[Opponent name] is thinking…" immediately
- After each AI action, VoiceOver focus moves to the action prompt live region
- Tutorial overlay announces step number and total: "Step 1 of 5: Here's your hand"
- All decorative elements (table background, card back designs) must be marked `accessibilityHidden: true`

**Score rationale:** VoiceOver support is fully designed with labels, custom actions, and live regions. The focus management during AI turns is the key risk — if VoiceOver goes silent for 1.2s during Expert AI thinking with no announcement, users will assume something broke. The "is thinking" announcement during the delay is a critical fix applied before Phase 5.

---

## Persona 7 — Impatient Commuter / Offline User

**Score: 10 / 10**

**What delights them:**
- Quick Play: one tap from home to game in < 3 seconds
- No network call ever — works underground, on planes, in dead zones
- No permission prompt ever — opens and plays immediately
- Autosave every turn — can exit at any moment and resume exactly where left off
- Continue Game on home screen — right back into the game in one tap

**What frustrates them:**
- If Quick Play uses last settings (which is the design), and last settings were "Expert AI", a commuter might be surprised
- If animation is on normal speed (not fast), a round might take longer than their commute

**What would make them stop:**
- Any delay on launch (network timeout, permission prompt, loading screen)
- Losing their game state when the app is evicted from memory by iOS

**Must improve before implementation:**
- Quick Play uses: last difficulty OR Easy if no prior game; Standard Teams; fast animation
- Explicit note in enterprise-build-notes.md: "The app launches with zero network calls. First launch should take under 1 second."

**Score rationale:** This persona is maximally served. The app is built entirely around their needs. Offline-first, instant launch, save/resume, no accounts. The Quick Play flow is a single tap.

---

## Persona 8 — Personal Power User

**Score: 9.5 / 10**

**What delights them:**
- Three modes with distinct mechanical differences — high replayability
- House rules with 6+ configurable options
- Four AI difficulty levels with visibly different behaviour
- Local statistics track their performance over time
- Save/resume means they can abandon a game and return later

**What frustrates them:**
- No event log to review game history (deferred to post-MVP)
- No way to create and save custom house rule presets
- Statistics are limited to aggregate counts — no per-game detail

**What would make them stop:**
- Expert AI feeling random rather than strategic
- Statistics resetting without warning (or being hard to reset when desired)
- No difficulty progression — same game every time

**Must improve before implementation:**
- Statistics screen: show "last game" details (mode, difficulty, turns, outcome) even if full history is not stored
- Settings: confirm before resetting statistics (separate from resetting game data)
- Future roadmap documents custom house rule presets as the first post-MVP feature

**Score rationale:** Power users are the most likely to explore all modes, difficulties, and house rules. The replayability is built in. The statistics gap (no per-game log) is a known MVP limitation, documented honestly in the product spec.

---

## Persona 9 — iPad Player

**Score: 10 / 10**

**What delights them:**
- Genuinely spacious iPad game table — not a stretched iPhone layout
- Portrait and landscape both designed deliberately
- Larger cards make the game feel more physical and readable
- Colour picker appears as a popover (not a full-screen modal jarring on a big screen)
- Split View and Stage Manager work — can keep a notes app alongside

**What frustrates them:**
- Nothing significant — the iPad-first design was treated seriously from the start

**What would make them stop:**
- If the iPad layout was ever reverted to stretched iPhone (monitor with ios-architect agent)
- If rotation during a game caused visible glitching or state loss

**Must improve before implementation:**
- The iPad landscape layout should show a subtle "event log" area (even if read-only and showing last 5 actions) — adds to the premium feel
- iPad Stage Manager: minimum useful width documented (400pt — below this, use compact layout)

**Score rationale:** The design system and UX spec treat iPad as a first-class platform. Nine iPad wireframes. Adaptive layout per size class. The result is a premium iPad experience rare in this category.

---

## Persona 10 — Enterprise-Environment Developer

**Score: 10 / 10**

**What delights them:**
- Zero prompts during Claude Code operation (read files, write files — all within repo)
- Zero third-party dependencies — `swift build` makes no network calls
- No Apple Developer account required for simulator builds
- Quality scripts are pre-written and require only one permission approval
- CLAUDE.md documents everything — no tribal knowledge

**What frustrates them:**
- Nothing material — the project is designed around enterprise constraints

**What would make them stop:**
- If a dependency was silently added that required network resolution
- If the Xcode project required a special provisioning profile to build

**Must improve before implementation:**
- Nothing additional needed — enterprise constraints are thorough

**Score rationale:** This persona's requirements shaped the entire project architecture. Zero permissions, zero network, simulator-first, no external packages. The Claude Code permission posture is explicitly enterprise-safe.

---

## Weighted Average

| Persona | Score |
|---|---|
| Casual Player | 9.0 |
| Strategic Player | 9.5 |
| First-Time Player | 8.0 |
| Older/Low-Vision | 9.0 |
| Colour-Blind | 10.0 |
| VoiceOver User | 9.0 |
| Impatient Commuter | 10.0 |
| Power User | 9.5 |
| iPad Player | 10.0 |
| Enterprise Developer | 10.0 |
| **Average** | **9.4 / 10** |

## Summary of Improvements Applied

| # | Improvement | Persona | Document |
|---|---|---|---|
| 1 | Easy AI animation speed ≤ 0.8s total | Casual | ux-spec.md |
| 2 | Round end: prominent "Play Again" button | Casual | ux-spec.md |
| 3 | Round end shows winning card + partner card count | Strategic | ux-spec.md |
| 4 | AI partner action card explanations | First-time | ux-spec.md |
| 5 | Hints on by default for first 5 games | First-time | ux-spec.md, product-spec.md |
| 6 | Tutorial re-accessible from Settings | First-time | ux-spec.md |
| 7 | Player labels always visible ("You", "Partner", "Left Opponent", "Right Opponent") | Older | ux-spec.md |
| 8 | Player labels visible at AX5 Dynamic Type | Older | accessibility-plan.md |
| 9 | Colour indicator always shows name text + chip | Colour-blind, VoiceOver | ux-spec.md |
| 10 | "is thinking…" VoiceOver announcement during AI delay | VoiceOver | accessibility-plan.md |
| 11 | VoiceOver focus moves to prompt after AI action | VoiceOver | accessibility-plan.md |
| 12 | Tutorial overlay announces step n of 5 | VoiceOver | accessibility-plan.md |
| 13 | Decorative elements marked accessibilityHidden | VoiceOver | accessibility-plan.md |
| 14 | Quick Play defaults: Easy + fast + Standard | Commuter | ux-spec.md, product-spec.md |
| 15 | Statistics: "last game" details shown | Power User | ux-spec.md |
| 16 | Confirm before reset statistics (separate from game data) | Power User | ux-spec.md |
| 17 | Event log last 5 actions on iPad landscape | iPad Player | ux-spec.md |
| 18 | Stage Manager minimum width: 400pt | iPad Player | ux-spec.md, design-system.md |
