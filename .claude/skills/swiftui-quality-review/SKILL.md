# Skill: SwiftUI Quality Review

## Purpose
Review SwiftUI view code for architectural correctness, accessibility completeness, adaptive layout, and performance safety. A screen must pass this review before it is considered implementation-complete. Produces a structured finding list with severity ratings and specific fixes.

## When to Invoke
- When a SwiftUI view implementation is ready for review before merge
- When iOS Architect is asked to review UI code
- When the user says "SwiftUI review", "code review this view", or "review screen implementation"
- As part of a phase gate review of all new screens added in the phase

## Inputs Required
- Path(s) to the SwiftUI source file(s) to review
- Path to the corresponding UX spec (in docs/ux-spec.md or a linked spec)
- Whether the review should include accessibility (default: yes) — full audit uses /accessibility-audit skill instead

## Steps

1. **Read the source file(s).** Read every SwiftUI file in scope. Also read docs/ux-spec.md to understand the intent of the screen being reviewed.

2. **Check view does not mutate engine state directly.** Verify the view does not call engine reducer functions, does not mutate @State properties that shadow engine state, and does not contain business logic beyond display transformation. Any engine call belongs in a ViewModel or intent handler. Flag any violation as Critical.

3. **Check import statements.** The view file must not import WildPairsCore directly for game logic types that should flow through the ViewModel. Check that the view layer only depends on display-facing types. Flag any direct engine type usage as a Major violation.

4. **Check @State, @StateObject, @ObservedObject usage.** Verify that:
   - @State is only used for transient UI state (animation flags, sheet presentation, text input)
   - @StateObject is used for ViewModels that the view owns
   - @ObservedObject is used for ViewModels passed in (not owned)
   - @EnvironmentObject is not overused — only for genuinely app-wide state
   Flag any business state stored in @State as Critical.

5. **Check view body complexity.** Flag any view body that:
   - Contains conditional logic beyond simple `if isLoading { ... }` style switches on display state
   - Contains computed properties with side effects
   - Contains loops over large unbounded collections without LazyVStack/LazyHStack
   - Contains synchronous file I/O, network calls, or expensive computations
   Rate complexity findings as Critical (side effects) or Major (performance risk).

6. **Check accessibility labels.** For every interactive element (Button, Tap gesture, custom control):
   - Is `.accessibilityLabel()` explicitly set? (Flag missing as Major)
   - Is `.accessibilityHint()` set for non-obvious interactions? (Flag missing as Minor)
   - Is `.accessibilityValue()` set for dynamic elements with changing state? (Flag missing as Major)
   For card views: are the card's suit, rank, and playability communicated via accessibility attributes?

7. **Check adaptive layout.** Verify that:
   - The view explicitly handles both compact and regular horizontal size class (using `@Environment(\.horizontalSizeClass)` or `ViewThatFits` or layout modifiers)
   - No hardcoded frame widths assume iPhone-only dimensions
   - Grid or stack layouts adapt meaningfully on iPad (not just stretched)
   Flag any iPhone-only layout as Major.

8. **Check reduced motion.** Every animation block must have a `@Environment(\.accessibilityReduceMotion)` check or use `.animation(.none, value:)` in the reduce-motion path. Flag any animation without this as Major.

9. **Check Dynamic Type.** Verify that:
   - All text uses semantic font styles (`.font(.body)`, `.font(.headline)`) not fixed sizes
   - No fixed-height containers clip text at large sizes
   - Custom font modifiers include `.dynamicTypeSize` range if capping is intentional
   Flag fixed font sizes as Major. Flag clipping containers as Major.

10. **Check tap target sizes.** Every tappable element should have at least `.frame(minWidth: 44, minHeight: 44)` or be large enough by design. Flag tap targets appearing smaller than 44×44pt as Minor (or Major if the primary action is affected).

11. **Check for expensive operations in view body.** Flag any of the following in a view body or computed var called from body:
    - `JSONDecoder().decode()` or `JSONEncoder().encode()`
    - `FileManager.default` calls
    - `DateFormatter()` instantiation (use cached formatters)
    - `NumberFormatter()` instantiation
    - Large collection sorting or filtering without caching
    Rate these as Major (they cause frame drops and jank).

12. **Produce ranked finding list.** List all findings: Critical → Major → Minor. For each: check name, file, line reference (if identifiable), description, recommended fix.

13. **Produce overall verdict.** APPROVED (no Critical/Major), NEEDS WORK (any Major), BLOCKED (any Critical).

## Outputs
- Ranked finding list (Critical / Major / Minor) with file and description
- Overall verdict: APPROVED / NEEDS WORK / BLOCKED
- Specific recommended fixes for all Critical and Major findings

## Acceptance Criteria
- No Critical findings remain open for a screen to be APPROVED
- All Major findings are either fixed or have a documented exception with rationale
- Adaptive layout for both compact and regular size class is confirmed present

## Common Pitfalls
- Reviewing only the primary view file and missing subviews extracted to separate files — read all files in the screen's feature folder
- Treating @EnvironmentObject as equivalent to @StateObject — ownership and lifetime matter
- Missing accessibility on custom gesture recognizers — a view with `.onTapGesture` needs accessibility as much as a Button
- Approving a screen because it "looks right" without checking reduced motion and Dynamic Type code paths
- Ignoring the UX spec when doing the review — the spec defines what the screen should do; deviation is a finding even if the code is clean
