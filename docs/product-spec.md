# Wild Pairs — Product Specification

> *Canonical sources: for data models, `technical-architecture.md` §Model Reference is canonical. For game rules and house-rule defaults, `game-rules.md` is canonical. For visual tokens, `design-system.md`. Where this document disagrees with its canonical source, the canonical source wins.*

## TL;DR

Wild Pairs is an offline Universal iOS/iPadOS card game for one human player and three AI opponents, structured as a 2v2 team match. It is an original colour-and-number shedding card game — legally and visually distinct from any existing game — featuring three game modes, four AI difficulty levels, three card sets, configurable house rules, and automatic save/resume. It requires no internet connection, no account, no special device permissions, and no third-party SDKs. The goal of the MVP is a polished, fully playable game that runs on iPhone and iPad from Xcode simulators, ready for eventual App Store submission.

---

## Problem

### What the User Wants to Do

The user wants to play a casual but strategic team card game on their iPhone or iPad, solo (against AI), offline, without any friction. They want:

- A game that starts immediately — no sign-in, no loading screens that fetch remote data.
- AI opponents that are interesting and configurable in difficulty.
- A team dynamic that creates genuine strategy (what does my partner need?).
- A game they can put down and pick back up exactly where they left it.
- A game that works on their big iPad screen as well as their iPhone — not a stretched phone layout.

### Why Existing Apps Fail Them

- **Online-first card game apps** require accounts, internet connections, and often matchmaking. The game stops the moment connectivity drops.
- **Most card game apps are for one player vs. AI** — no team structure, no partner strategy.
- **Commercial UNO apps** carry advertisements, in-app purchases, or mandatory account registration. Some require online play even for AI modes.
- **Open-source alternatives** are rarely Universal (iPad is an afterthought) and have poor VoiceOver support.
- **None of the above** offer a clean, offline 2v2 team experience with configurable rules and no monetisation hooks.

---

## Solution

Wild Pairs delivers:

- **Fully offline.** The game works with Airplane Mode on. No network calls, ever.
- **No accounts.** The app opens to the game. No email, no Game Center sign-in required.
- **Original design.** Custom card colours (Crimson, Cobalt, Jade, Amber), original symbols, original mechanic names. No licensed IP anywhere in the codebase or assets.
- **Team strategy.** 2v2 structure with both teammates needing to empty their hands. The AI partner creates genuine cooperative tension.
- **Universal first-class iPad support.** Separate layout designed for the large screen; not an iPhone layout scaled up.
- **Accessibility by default.** VoiceOver, Dynamic Type, colour-blind mode, Reduce Motion are mandatory requirements, not afterthoughts.
- **Configurable depth.** Three card sets let beginners start gently; house rules let experienced players tune the game to their preference.

---

## Target User

### Primary Persona

**Personal use — one human player, no network.**

- Plays on their own iPhone or iPad.
- Wants an engaging solo experience with AI opponents.
- May play in short sessions (commute, waiting room) or longer sessions at home.
- Values the ability to pause and resume without losing progress.
- Does not want to create an account or manage any persistent identity.
- May have accessibility needs (VoiceOver, larger text, colour-blind mode).

### Secondary Target

**App Store quality.** The app should be polished enough for eventual public distribution. Design decisions should not foreclose App Store submission (no private APIs, no special entitlements, standard sandbox permissions only).

---

## MVP Scope (Phase 5 Deliverable)

The MVP is a fully playable Wild Pairs game. Specifically:

### Included

- **Game engine** — pure reducer implementing all card types, all modes, all house rules
- **Three game modes** — Standard Teams, All-Wild Teams, Side-to-Side Teams
- **Four AI difficulty levels** — Easy, Medium, Hard, Expert
- **Three card sets** — Beginner, Standard, Advanced (including all eleven card types)
- **Save and resume** — autosave every turn, resume after app termination
- **Universal iPhone + iPad** — adaptive layouts; both are first-class targets
- **VoiceOver** — full support; every interactive element has an accessibility label and action
- **Dynamic Type** — all text scales with system font size setting
- **Colour-blind mode** — card symbols (Flame, Wave, Leaf, Sun) convey colour identity without relying solely on colour
- **Reduce Motion** — all animations have instant-transition fallbacks
- **Large Card mode** — optional setting to enlarge card display for readability
- **Configurable house rules** — all seven house rule toggles functional
- **Solo! mechanic** — human timer, AI auto-call, penalty enforcement
- **Round scoring** — optional scoring mode with correct point values
- **Pause / save / quit / abandon** — full pause menu with save and abandon options
- **Draw pile reshuffle** — correct handling of exhausted draw pile
- **All turn-order logic** — clockwise/counter-clockwise, Skip, Skip Two, Reverse with 4 players

### Explicitly Excluded from MVP

See Non-Goals below.

---

## Non-Goals (MVP)

| Feature | Reason Excluded |
|---|---|
| Online multiplayer | Requires server infrastructure, accounts, matchmaking — out of scope for offline-first product |
| Physical device Game Center | Requires Apple ID and network; explicitly out of scope |
| iCloud sync | Requires entitlements and network; local save is sufficient |
| Analytics or telemetry | No data leaves the device; privacy guarantee |
| Advertisements | Not a monetisation model for this product |
| In-app purchases | Not a monetisation model for this product |
| User accounts of any kind | No identity management, ever |
| Real-money features | Not applicable |
| Custom card artwork uploads | Post-MVP capability |
| Physical Bluetooth/local Wi-Fi multiplayer | Post-MVP; requires complex session management |
| macOS native app | Post-MVP; architecture supports it, but UIKit/SwiftUI adaptation needed |
| Localization | English only for MVP |

---

## Three Game Modes

### Standard Teams (`standardTeams`)

**Purpose:** The default, rules-complete experience. Matching by colour, number, or action type creates interesting decisions every turn. Players must assess whether to save wilds, when to play action cards, and how to support their partner.

**Differentiator:** Closest to the classic shedding-card-game genre. Best entry point for new players. Team strategy is strongest here because resource management (which card to play vs. save) matters.

### All-Wild Teams (`allWild`)

**Purpose:** A chaotic, fast-paced variant where every card is playable every turn. The game becomes a race to dump cards using action effects.

**Differentiator:** Eliminates the "stuck with no valid card" experience. Pure action-card strategy. Sessions are shorter and more frantic. Great for experienced players who want a different challenge or for introducing action cards to new players without the constraint of colour matching.

### Side-to-Side Teams (`sideToSide`)

**Purpose:** Adds a cooperative team mechanic — the optional pre-round card pass — on top of the Standard Teams rules. Creates a deeper partnership dynamic.

**Differentiator:** The team pass introduces genuine asymmetric information and coordination. Players must guess what their partner needs without communicating. Unlocks the most strategic play of the three modes. Best suited for experienced players who want the deepest game.

---

## Four Difficulty Levels

### Easy

**Algorithm:** Random valid move selection.

**Player experience:** AI opponents play unpredictably and suboptimally. They will frequently miss opportunities to use action cards effectively and will not coordinate with partners strategically. Suitable for new players learning the rules, or players who want a very low-pressure session.

### Medium

**Algorithm:** Basic heuristic. Prefer playing action cards over number cards. Hold wild cards until needed. Prefer cards that extend the current colour to support the partner.

**Player experience:** AI opponents feel like cautious but inexperienced players. They make sensible individual moves but do not think ahead. A reasonable match for a casual player.

### Hard

**Algorithm:** Scored heuristic. Evaluates moves by: hand-size reduction value, partner vulnerability (does this leave partner unable to play?), opponent disruption potential, Solo! risk management.

**Player experience:** AI opponents play noticeably better — they target opponents strategically, support partners when possible, and manage their own hand toward a win condition. A competent challenge for most players.

### Expert

**Algorithm:** Lookahead simulation. Evaluates a tree of possible future states (bounded depth) to select the move with the highest expected value. Uses the masked observation model — AI cannot see hidden hands.

**Player experience:** AI opponents are strong and sometimes surprising in their choices. They will set up multi-turn plays and respond to the human's patterns. Appropriate for experienced players who want a genuine challenge.

---

## Three Card Sets

### Beginner

**Contents:** Number cards (0–9), Skip, Reverse, Change Colour.

**Suitable for:** First-time players, younger players, or anyone who wants a clean experience without complex special cards.

**Experience:** Games focus on colour and number matching. The only special decisions are when to use Change Colour and managing Skip/Reverse timing. Sessions are relatively calm and predictable.

### Standard

**Contents:** All Beginner cards plus Draw Two and Draw Four.

**Suitable for:** Players familiar with the shedding-card genre. The recommended default.

**Experience:** Draw cards add a significant disruption element. The Draw Four's restriction (only playable when you have no other legal play — unless house rule overrides) creates interesting decisions. Games have more swing moments.

### Advanced

**Contents:** All Standard cards plus Discard All, Targeted Draw, Forced Swap, Skip Two, and Team Play.

**Suitable for:** Experienced players who want the maximum strategic complexity and unpredictability.

**Experience:** Advanced cards make every turn potentially explosive. Forced Swap can completely alter the game state. Discard All can clear a large hand instantly. Team Play creates moments of coordinated advantage. Sessions are most variable in length and outcome.

---

## House Rules

House rules let players tune the game to their preferences. All are off by default (except Team Pass in Side-to-Side mode, which is on by default when that mode is selected).

| House Rule | What It Adds |
|---|---|
| Draw Four Anytime | Removes the restriction on Draw Four — can be played even when you have a legal play. Makes the game more aggressive and unpredictable. |
| Single-Out Win | Lowers the bar for winning — one teammate going out wins the round. Speeds up sessions and reduces late-game drag when one player has many cards left. |
| Draw Stacking | Allows chaining of Draw Two and Draw Four penalties. Creates dramatic escalation moments. Rewards saving draw cards defensively. |
| Solo! Penalty Disabled | Removes the Solo! mechanic entirely. Simplifies play for sessions where the timing pressure feels frustrating. |
| Team Pass (Side-to-Side) | Enables the pre-round card exchange in Side-to-Side mode. Off = Side-to-Side plays identically to Standard Teams. |
| Partner Plays Immediately (Team Play variant) | Changes the Team Play card so the partner immediately plays a card instead of drawing one. More aggressive variant that can accelerate a partner's path to going out. |
| Scoring Enabled | Adds round-by-round scoring and cumulative score tracking. Turns the game into a multi-round session with an overall winner. |

---

## Save and Resume

### Requirements

- **Autosave on every stable turn.** The game state is persisted to disk at every point where a player is waiting for input (human turn, AI turn, colour choice, target choice, team pass, round end).
- **Resume after app termination.** If the app is force-quit or the device restarts, the game resumes at the exact turn where it was, with no loss of cards, scores, or turn state.
- **No data loss for mid-decision states.** If the app is backgrounded while the human is choosing a colour or target, the pending decision is preserved. On resume, the decision picker re-appears.
- **No network required.** All persistence uses `FileManager` + `Codable`. No iCloud, no server.
- **Corrupted save gracefully handled.** If the save file is unreadable (wrong schema version, corrupted bytes), it is deleted and the player starts from the home screen. No crash.
- **Explicit save/abandon.** From the pause menu, players can "Save & Quit" (persists state) or "Abandon Game" (deletes save and returns to home).

### Format

`Codable` JSON written to the app's `Documents` directory. Schema versioned with an integer; unrecognised versions are treated as corrupted.

---

## Universal iPhone + iPad

Both form factors are first-class targets, not one adapted from the other.

### iPhone Layout

- Card hand displayed horizontally at the bottom of the screen, scrollable if many cards.
- Discard pile and draw pile centred.
- Opponent hands shown as compact card-back stacks at top and sides.
- Action overlays (colour picker, target picker) appear as modal sheets.

### iPad Layout

- Table view: card hands visible at all four edges of the screen (bottom = human, top = partner, left/right = opponents).
- More cards visible simultaneously; less scrolling required.
- Larger tap targets throughout.
- Action overlays appear as popovers or centred modals, not full-screen sheets.
- Split-view and slide-over compatible (game pauses on secondary window interaction).

### Why Both Matter

Card games on iPad are significantly more enjoyable with a true table layout — seeing all players' card counts simultaneously is part of the experience. Shipping a scaled-up iPhone layout on iPad would feel amateurish and undermine the product quality goal.

---

## Accessibility Requirements

All accessibility features are mandatory, not optional or "nice to have."

### VoiceOver

- Every card in hand has an accessibility label: "[Colour] [Type/Number]" (e.g., "Crimson Five", "Jade Skip", "Change Colour").
- Playable cards have an additional accessibility trait of "button" and an action label ("Play Crimson Five").
- Non-playable cards are labelled but not interactive.
- Draw pile: "Draw pile — [count] cards remaining." Tap to draw.
- Discard pile: "Discard pile — top card: [Colour] [Type]."
- Player card counts: "[Player name] has [N] cards."
- State announcements: "[Player name]'s turn", "[Player name] played [Card]", "[Player name] called Solo!", "[Player name] skipped."
- Colour picker: each colour button labelled with name and symbol: "Crimson, Flame symbol."
- Target picker: each player labelled with name and card count.

### Dynamic Type

- All text uses system font styles (`UIFont.preferredFont(forTextStyle:)` or SwiftUI equivalents).
- Card labels scale with the player's preferred text size.
- Layouts reflow at larger sizes (cards may wrap; no text truncation).

### Colour-Blind Mode

- Card identity is never communicated by colour alone.
- Each colour has a unique symbol: Crimson = Flame, Cobalt = Wave, Jade = Leaf, Amber = Sun.
- Symbols are displayed on every card face, always visible regardless of colour-blind mode setting.
- In colour-blind mode, symbols are larger and card backgrounds use high-contrast patterns in addition to colour.

### Large Cards Mode

- Optional setting that increases the card size throughout the game.
- All card faces remain fully legible at large size.
- Hand overflow handled by horizontal scroll or fan display.

### Reduce Motion

- All card slide animations, pile shuffle animations, and direction-change animations are replaced by instant transitions when "Reduce Motion" is enabled in iOS Settings.
- No flip animations, no bouncing, no parallax.
- Sound effects (if any) are unaffected by Reduce Motion.

---

## Privacy and Offline Guarantee

### What Stays Local

- All game state
- All save files
- All settings and house rule preferences
- All game history and scores

### What Never Leaves the Device

- No game data is ever transmitted over a network.
- No analytics events are logged.
- No crash reports are sent (developer uses Xcode device logs directly during development).
- No advertising identifiers are accessed.

### No Accounts — Ever

The app does not ask for, store, or transmit any identity. There is no login screen, no guest mode, no optional sign-in. The App Store privacy label for Wild Pairs will declare: "No data collected."

### App Permissions

The app requests zero system permissions at runtime. It does not access:
- Camera
- Microphone
- Contacts
- Location
- Photo Library
- Network (beyond what the OS uses internally — no `NSAllowsArbitraryLoads` or network entitlements)
- Push Notifications
- Bluetooth

---

## Enterprise Build Requirements

Wild Pairs is developed on a Windows host using Claude Code, targeting macOS/Xcode for compilation and iOS simulators for testing.

### Simulator-First Development

- All feature development and testing happens in the iOS Simulator (Xcode 15+, iOS 17+).
- No physical device required for development. Physical device testing is optional for pre-release validation.
- All simulator targets are supported: iPhone (various sizes), iPad (various sizes).

### No Special Entitlements

The app uses no App Store entitlements that require provisioning during development:
- No Game Center
- No iCloud
- No Push Notifications
- No In-App Purchase
- No Associated Domains

A development team signing profile is sufficient to build and run on simulator and device.

### No Third-Party SDKs

The project has zero external dependencies. All code is first-party Swift:
- `WildPairsCore` Swift Package — game engine, models, AI
- `WildPairsApp` Xcode target — SwiftUI UI, navigation, persistence coordinator

No CocoaPods, no Swift Package Manager third-party dependencies, no vendored frameworks.

### Build Host Compatibility

The `WildPairsCore` package can be developed on any platform that supports Swift. The Xcode project and UI layer require macOS + Xcode. Claude Code on Windows is used for codebase exploration, document generation, and file editing; actual compilation runs on a macOS machine.

---

## Success Criteria

The MVP is complete when all of the following are true:

### Gameplay

- [ ] A full game (deal → turns → round end) completes without error in all three modes
- [ ] All eleven card types function correctly with accurate effects
- [ ] All four AI difficulty levels produce measurably different play quality
- [ ] All three card sets are correctly filtered (Advanced cards absent in Beginner/Standard sets)
- [ ] All seven house rules toggle on/off and produce correct rule changes
- [ ] Solo! mechanic fires, penalises, and can be disabled via house rule
- [ ] Both-teammates-out win condition works; single-out house rule variant works
- [ ] Draw pile reshuffle works correctly when draw pile empties

### Save and Resume

- [ ] Force-quitting the app and relaunching resumes the game at the correct turn
- [ ] Backgrounding mid-colour-choice and resuming re-presents the colour picker
- [ ] Backgrounding mid-target-choice and resuming re-presents the target picker
- [ ] Corrupted save file causes graceful fallback to home (no crash)

### Universal Layout

- [ ] iPhone layout renders correctly at smallest (SE) and largest (Max) sizes
- [ ] iPad layout renders correctly at 9.7", 11", and 12.9" sizes
- [ ] No text overflow, no clipped card graphics, no broken constraints in any tested size

### Accessibility

- [ ] Full game is playable using VoiceOver only (no visual input required)
- [ ] All text scales correctly to largest Dynamic Type size without truncation
- [ ] Colour-blind mode: all cards identifiable by symbol alone, verified by a person with colour-vision deficiency or with a colour-blindness simulation filter
- [ ] Reduce Motion: no animations play when setting is enabled; all state transitions are instant

### Privacy

- [ ] App passes network analysis (Charles Proxy / Instruments) with zero outbound requests during a full game session
- [ ] App Store privacy nutrition label accurately declares "No data collected"
- [ ] App launches and runs fully in Airplane Mode

### Code Quality

- [ ] `WildPairsCore` has unit test coverage for all state transitions in the state machine
- [ ] All card type effects have unit tests
- [ ] AI difficulty tests confirm Easy < Medium < Hard < Expert win rates against a fixed AI opponent over a statistically significant number of simulated games
- [ ] No `TODO` or `FIXME` comments remain in production code paths

---

## Future Roadmap

These capabilities are explicitly post-MVP but should not be foreclosed by MVP architectural decisions.

| Feature | Architectural requirement |
|---|---|
| Additional game modes (e.g., Free-for-All, 3-player) | Engine supports variable player counts; `GameMode` enum is extensible |
| Custom card sets (user-defined card types) | `CardType` is a protocol; new conforming types can be added without changing the engine |
| macOS native app (Catalyst or native SwiftUI) | UI layer must avoid UIKit-only APIs; use SwiftUI throughout for cross-platform portability |
| App Store release | No private APIs, no special entitlements, clean privacy label — already required by MVP |
| Physical-device Game Center leaderboards (optional, post-privacy review) | `WildPairsCore` never couples to GameKit; leaderboard hooks would be added in the App layer only |
| Additional language localisations | All UI strings in `Localizable.strings` from day one; no hardcoded English strings in UI layer |
| Themed card designs | Card rendering is isolated in a `CardView` component; theme swapping is a view-layer concern only |
| Haptic feedback | `UIFeedbackGenerator` calls are additive; Reduce Motion preference already tracked |
| Statistics and play history | `GameResult` model already exists; a statistics store can be added without touching the engine |
