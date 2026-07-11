# D1 — Pass-and-play partner-view redesign (brief)

## Goal
Let two teammates share **one device laid flat between them** and both play without the
"pass the device" handoff overlay. The person seated opposite (Partner) should read their own
content upright when the phone points at them — i.e. the top half is rotated 180°.

## Today
- One bottom-anchored perspective for whoever "has" the device.
- A blocking `HandoffOverlay` ("Pass to Beth") flips the whole table between human turns
  (`DecisionViews.swift`), so only one player ever sees a live table at a time.
- Turn changes are a popup, not a felt-level cue.

## Target
- **Two-ended table:** your hand at the bottom (upright); the partner's hand large and
  **rotated 180°** at the top so the opposite teammate reads it the right way up.
- **No handoff popup:** whose turn it is comes from the Phase-17 Stage-3 legibility system —
  active-seat spotlight, direction chip, seat callouts — not a modal.
- Opponents (Team B) on the sides.

## Hard constraints
- Offline-only SwiftUI; dark felt table; the Solo image-based card deck (patterns baked in).
- iPhone **portrait** is the primary shared-device orientation (device flat, players at the
  short ends); iPad both orientations must adapt.
- VoiceOver + Dynamic Type must survive; reduced-motion fallback for any sweep.
- British English copy.
- **Scope: pass-and-play only** (`partnerRole == .human`). AI-partner games keep today's
  single-perspective layout untouched.

## Reference state (identical in every prototype, so they compare fairly)
Current colour **Rain**; discard top **Rain 7**; draw pile 41. Direction clockwise. **Your**
turn (bottom, active). You hold Fire 5 · Rain 7 · Earth 3 · Wind 9 · Rain Skip. Partner (top)
holds 4. Left opponent 6 cards, Right opponent 4.

## What "wins"
The clearest, calmest two-ended layout where **both players always know whose turn it is and can
read their own hand** — with the least wasted felt on a phone and a sane iPad adaptation.
