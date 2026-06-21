# Skill: Accessibility Audit

## Purpose
Systematic accessibility audit of a single screen or feature. Produces a pass/fail checklist for every accessibility requirement. A screen must pass this audit before it is considered accessibility-complete. More thorough than the accessibility spot-check in /swiftui-quality-review.

## When to Invoke
- When a screen implementation is ready for full accessibility review
- When Accessibility Lead is asked to audit a screen
- When the user says "accessibility audit", "VoiceOver review", or "a11y check"
- As part of a phase gate, for each new screen added in the phase

## Inputs Required
- Screen name and path to SwiftUI source file(s)
- Path to docs/accessibility-plan.md (to record results)
- Optionally: VoiceOver test results from manual testing (if available)

## Steps

1. **Read the source file(s) and accessibility plan.** Read all SwiftUI files for the screen. Read docs/accessibility-plan.md to understand the planned accessibility approach for this screen. Note any planned labels or announcements that must be verified.

2. **Check: every interactive element has accessibilityLabel.** List every Button, `.onTapGesture`, `.onLongPressGesture`, custom control, and NavigationLink. For each:
   - Is `.accessibilityLabel()` explicitly set? PASS / FAIL
   - Is the label descriptive and action-oriented (e.g., "Play card: Ace of Spades" not "Card")? PASS / FAIL
   Flag any element with a missing or vague label as a blocking issue.

3. **Check: game events are announced via VoiceOver.** Identify all state changes a sighted player would perceive visually:
   - Card played by any player
   - Turn changed (whose turn it is)
   - Card drawn
   - Special card effect triggered (skip, reverse, draw two, wild)
   - Win condition met
   For each event: is there an `.accessibilityAnnouncement()` call or equivalent mechanism? PASS / FAIL

4. **Check: colour-blind mode works.** Identify every piece of information conveyed by colour on this screen. For each:
   - Is there a secondary indicator (shape, label, pattern, icon) for deuteranopia/protanopia? PASS / FAIL
   - Is there a secondary indicator for tritanopia? PASS / FAIL
   Note any information encoded solely by colour as a blocking issue.

5. **Check: Dynamic Type does not clip.** For each text element on the screen:
   - Does the layout accommodate AX5 (largest accessibility text size) without clipping or overlap? PASS / FAIL
   - Are all font sizes using semantic styles (not fixed point sizes)? PASS / FAIL
   Note any fixed font sizes or clipping containers.

6. **Check: reduced motion.** For each animation in the screen:
   - Is there a `@Environment(\.accessibilityReduceMotion)` code path? PASS / FAIL
   - Does the fallback use `.animation(.none)` or a simple cross-fade? PASS / FAIL
   Note any animation without a reduced-motion alternative.

7. **Check: tap target sizes.** For each interactive element:
   - Is the tappable area at least 44×44pt? PASS / FAIL (estimate from layout constraints or frame modifiers)
   Note any tap target smaller than 44×44pt.

8. **Check: VoiceOver focus order.** Review the view hierarchy to determine VoiceOver reading order:
   - Does the reading order match the logical flow of the screen? PASS / FAIL
   - Are there any orphaned elements (not reachable by VoiceOver swipe)? PASS / FAIL
   - Are there any focus traps (VoiceOver cannot leave an area)? PASS / FAIL
   - Are card groups presented as a single accessible element with a combined label, not as individual sub-elements that fragment the reading experience? PASS / FAIL

9. **Check: accessibilityElement grouping.** For compound views (card view showing rank + suit + state):
   - Is `.accessibilityElement(children: .combine)` or explicit grouping used? PASS / FAIL
   - Does the combined label read naturally? PASS / FAIL

10. **Check: accessibilityHint for non-obvious interactions.** For each interactive element:
    - If the action is not obvious from the label, is `.accessibilityHint()` provided? PASS / FAIL

11. **Produce pass/fail checklist.** Format: one row per check, PASS or FAIL, with specific element or line reference for failures.

12. **Update docs/accessibility-plan.md.** Record this audit's results in the screen's section of the plan. Update the implementation status for each item.

## Outputs
- Pass/fail checklist (one row per check item above)
- Blocking issues list (any FAIL that prevents shipping)
- Recommended fixes for all FAIL items
- Updated docs/accessibility-plan.md

## Acceptance Criteria
- All interactive elements have explicit accessibilityLabel: all PASS
- All game events have VoiceOver announcements: all PASS
- No information encoded solely by colour: all PASS
- All animations have reduced-motion fallbacks: all PASS
- All tap targets ≥44×44pt: all PASS
- VoiceOver focus order is logical with no orphaned elements or traps: all PASS
- docs/accessibility-plan.md updated with audit date and results

## Common Pitfalls
- Auditing only from code without considering runtime VoiceOver behaviour — some issues only appear when VoiceOver groups elements differently at runtime than the source suggests
- Forgetting to check card grouping — individual rank and suit labels read separately by VoiceOver create a terrible experience; grouping is essential
- Treating Dynamic Type as "just font size" — large text sizes cause layout reflow that can overlap or hide non-text elements (icons, decorative elements)
- Missing the game event announcement check — static label audits pass but VoiceOver users still cannot follow the game if events are silent
- Not updating docs/accessibility-plan.md — the plan must reflect the current implementation state, not the original intent
