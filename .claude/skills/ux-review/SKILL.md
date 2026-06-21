# Skill: UX Review

## Purpose
Heuristic UX audit of a screen or feature against Apple HIG guidelines and the Wild Pairs experience principles in docs/ux-spec.md. Produces a scored review with ranked findings and specific improvement recommendations. Use this before any screen implementation is considered done.

## When to Invoke
- When a screen spec is written and ready for review before implementation begins
- When a SwiftUI view implementation is ready for UX review before merge
- When UX Lead is asked to review a screen or flow
- When the user says "UX review", "HIG check", or "review this screen"

## Inputs Required
- Screen name or feature name to review
- Path to the screen's spec (in docs/ux-spec.md or a linked spec file) OR a description of the screen if no spec exists yet
- Whether the review is of a spec (design review) or an implementation (code review)
- If code review: the SwiftUI source file path(s)

## Steps

1. **Read the context.** Read docs/ux-spec.md to understand the overall experience principles, design language, and persona priorities. Read the specific screen spec or SwiftUI file being reviewed.

2. **Identify the primary action.** State explicitly: what is the one thing a user should be able to do on this screen? If there are two or more equally weighted actions, flag this as a finding — every screen needs a single primary action.

3. **Check one-handed iPhone reachability.** For the primary action: is it reachable with a right-handed thumb in the lower two-thirds of the screen? For secondary actions: are they placed in reasonable reach zones? Flag anything that requires a stretch to a top corner as a finding.

4. **Check iPad layout.** Is there an explicit regular-width layout? Does it use the extra space meaningfully (not just stretched iPhone layout)? Is split view or slide-over considered? Flag any iPad-specific issues.

5. **Check colour-blind safety.** Is any critical information conveyed only by colour? (e.g., card suits distinguished only by red/green?) Each piece of information must have a secondary indicator: shape, label, pattern, or icon. Flag any colour-only encoding.

6. **Check Dynamic Type.** Does the layout accommodate text at xSmall and AX5 sizes without clipping or overlap? Are font sizes using `.font(.body)` style semantics rather than fixed point sizes? Flag fixed font sizes.

7. **Check VoiceOver readiness.** Does every interactive element have an explicit accessibilityLabel specified (in spec) or implemented (in code)? Are game events announced? Flag missing labels or silent state changes. (Full accessibility audit is a separate skill — this is a spot check.)

8. **Check reduced motion.** Does every animation have a reduced-motion fallback described (in spec) or implemented (in code)? Flag any animation without a fallback.

9. **Check tap target sizes.** Are all interactive elements at least 44×44pt? Flag any that appear smaller.

10. **Score each dimension.** Score 0–3 for each dimension:
    - 0 = Failing (blocking issue)
    - 1 = Needs improvement (significant finding)
    - 2 = Acceptable (minor finding)
    - 3 = Good (no findings)
    Dimensions: Primary action clarity, iPhone reachability, iPad layout, Colour-blind safety, Dynamic Type, VoiceOver readiness, Reduced motion, Tap targets, HIG compliance (general), Delight/polish

11. **Produce ranked finding list.** List all findings ranked by severity: Critical (score 0) → Major (score 1) → Minor (score 2). For each finding: dimension, description, specific element or location, recommended fix.

12. **Write improvement recommendations.** For each Critical and Major finding, write a specific actionable recommendation. For Minor findings, list as improvements for consideration.

## Outputs
- Dimension score table (10 dimensions, 0–3 each, with brief justification)
- Ranked finding list (Critical / Major / Minor)
- Specific improvement recommendations for Critical and Major findings
- Overall assessment: READY (all dimensions ≥2), NEEDS WORK (any dimension = 1), BLOCKED (any dimension = 0)

## Acceptance Criteria
- All dimensions score 2 or higher for a screen to be considered UX-approved
- No Critical findings (score 0) remain open
- iPad layout is explicitly reviewed — not assumed to be acceptable without inspection
- Colour-blind check explicitly performed — not assumed safe

## Common Pitfalls
- Reviewing only the iPhone layout and assuming iPad is fine
- Skipping the colour-blind check because the palette "looks fine" — test each piece of critical information for non-colour encoding
- Treating accessibilityLabel presence as a full accessibility review — this skill does a spot check only; run /accessibility-audit for a complete audit
- Accepting "we'll add reduced motion later" — reduced motion fallback must be designed at spec time, not retrofitted
- Overlooking empty states and error states — review these as separate "screens" within the same review
