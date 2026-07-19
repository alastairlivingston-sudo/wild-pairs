# Component and state contracts

This document tells Claude Code what each redesigned element means, where its data comes from, what it may own, and what it must never own.

## Table background

**Owner:** `TableBackground`

**Inputs:** current `CardColour?`, system Reduce Motion, project Reduced Visual Effects environment.

**Meaning:** establishes a physical dark table and reinforces the active element without competing with the cards.

**May own:** purely local animation phase generated from `TimelineView`.

**Must not own:** current colour, turn, timer, score, or game phase.

**Acceptance:** cards and text remain the highest-contrast objects; pattern is visible only on inspection; no continual animation under Reduce Motion; no transparency/blur reliance under Reduced Visual Effects.

## Unified state rail

**Owner:** private presentation view inside `GameTableView`.

**Inputs:** `vs.currentColour`, active seat projected from `vs.seats`, `vm.thinkingPlayerID`, `vm.roundTimeRemaining`, `vm.roundTimeLimit`, scene accent.

**Meaning:** answers three questions at a glance: what element is active, whose turn it is, and how much round time remains.

**May own:** no state.

**Must not own:** its own timer, active-player index, colour selection, or turn direction.

**Non-colour encoding:** suit glyph, element name, explicit turn label, owner icon, timer digits and progress ring.

**Accessibility:** one combined summary plus the preserved `game-round-timer` identifier on the timer.

**Responsive behaviour:** horizontal layout first; `ViewThatFits` falls back to a compact stacked arrangement.

## Draw deck

**Owner:** `TableCenterView`, visual body provided by the shared `CardBackView`.

**Inputs:** draw-pile count, pending draw count, `canDraw`, `mustDraw`, forced pickup, existing `onDraw` closure.

**Meaning:** a physical face-down deck, visually and spatially separate from already-played cards.

**May own:** temporary visual pulse/pop state only.

**Must not own:** draw legality, actual deck count, or penalty application.

**Interaction:** retains `game-draw-card-button`; disabled when the supplied state says drawing is illegal.

**Spacing:** default 24 points from the discard, never below 16. Count badge sits on the deck's outside edge.

## Played-card pile

**Owner:** `TableCenterView`.

**Inputs:** top discard, recent discard memory, current resolved wild colour, colour-choice pending.

**Meaning:** the physical history of cards already played.

**May own:** a short colour-resolution scale pulse.

**Must not own:** discard mutation or colour-choice rules.

**Animation contract:** `.reportTableAnchor(.discard...)` remains on the visible pile so played-card travel lands correctly.

## Direction orbit

**Owner:** `TableCenterView`.

**Inputs:** authoritative `TurnDirection`.

**Meaning:** permanent spatial orientation of play around the table.

**May own:** local rotation and one-shot `REVERSED` confirmation state.

**Must not own:** a second direction variable.

**Reduced Motion:** immediately mirrors to the final direction; no spring or spinning sequence is required. Text still says CLOCKWISE or COUNTER-CLOCKWISE.

## Opponent seat

**Owner:** `PlayerZoneView`.

**Inputs:** existing `PlayerSeatViewState`, thinking state, cue, optional caught count, optional catch action.

**Meaning:** an actual hidden hand owned by a specific seat, not a generic dark panel.

**May own:** subtle pulse/arrival animation state.

**Must not own:** opponent count, identity, turn ownership, Solo/catch eligibility, or AI state.

**Presentation:** no more than five physical backs are drawn, but the exact count remains in a badge. The abstract crest is stable by absolute seat position.

**Interaction:** the whole seat remains the existing catch target when catch is legal. `seat-<seatPosition>` remains unchanged.

## Partner open-hand shelf

**Owner:** `PlayerZoneView` when `visiblePartnerHand != nil`.

**Inputs:** the already-exposed partner cards in `PlayerSeatViewState`.

**Meaning:** makes ownership explicit while preserving the intentional open-hand team rule.

**May own:** no game state.

**Must not own:** a copied hand or card selection.

**Presentation:** shallow shelf, `PARTNER · OPEN HAND`, crest, name, count, then the unchanged face-up `CardView` fan.

## Active-turn treatment

**Owners:** state rail for global truth; `PlayerZoneView` for spatial seat emphasis; existing hand/prompt for local actionability.

**Inputs:** `seat.isCurrentPlayer`, `vs.isLocalPlayerTurn`.

**Meaning:** obvious at a glance even in greyscale.

**Non-colour encoding:** white corner brackets, explicit `UP NOW` or `YOUR TURN`, elevation, owner icon.

**Must not:** use glow alone or create a second active-player property.

## Solo call control

**Owner:** `GameTableView`; action remains `vm.callSolo()`.

**Inputs:** `vs.soloButtonVisible`, project reduced motion, system Reduce Motion.

**Meaning:** a table-shout moment with a stable trailing-thumb location.

**May own:** pulse phase and pressed-state animation only.

**Must not own:** Solo eligibility, card count, grace window, or penalty rules.

**Reduced Motion:** static urgent burst; the text, megaphone, outline, and accessibility value carry the state.

**Identifier:** `game-solo-button`.

## Catch affordance

**Owner:** `PlayerZoneView`; legality comes from `vs.catchableSoloPlayerID` and the existing closure.

**Meaning:** a specific opponent can be caught for failing to call Solo.

**Presentation:** `CATCH +2` chip with warning icon, plus the existing whole-seat tap target.

**Must not:** infer eligibility from card count alone.

## Caught penalty feedback

**Owners:** `GameViewModel` emits a one-shot presentation event; `GameTableView` routes it to the matching seat or local control zone; SwiftUI stamp renders the result.

**Source:** existing `.soloCallMissed` effect after the engine has applied the penalty.

**Meaning:** confirms who was caught and how many cards were applied.

**May own:** token and short presentation lifetime.

**Must not:** mutate a hand, draw cards, or award points.

## Shared card back

**Owner:** existing `CardBackView`.

**Asset:** `solo_table_card_back`.

**Meaning:** one original, unbranded physical back for the draw stack, hidden hands, and flight animations.

**Rule:** every face-down card in the app should flow through this view unless a future feature explicitly requires a different deck skin.

## Elemental crests

**Owner:** `PlayerZoneView` presentation.

**Assets:** `solo_table_crest_lava`, `solo_table_crest_sky`, `solo_table_crest_grass`, `solo_table_crest_sun`.

**Meaning:** abstract seat identity, not a human avatar and not a gameplay colour assignment.

**Current mapping:** absolute seat positions 0–3 map to Lava, Sky, Grass, Sun. This is cosmetic and stable through pass-and-play perspective rotation.

**Future migration:** if player profiles later supply an authoritative crest, use that field and remove the local position mapping.

## Move timer and prompt

**Owners:** existing `MoveTimerBar` and `PromptBanner`.

**Decision:** retained. They communicate local action urgency and rules guidance that the state rail does not replace.

**Do not:** merge them into the state rail if doing so makes multi-line prompts unreadable at large Dynamic Type.

## Quick chat

**Status:** intentionally deferred.

**Reason:** there is no game action, state field, or AI decision preference in the supplied project. See `QUICK_CHAT_DECISION.md`.
