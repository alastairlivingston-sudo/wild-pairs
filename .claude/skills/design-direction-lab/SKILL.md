---
name: design-direction-lab
description: Explore a visual redesign as N self-contained HTML direction prototypes, let the user pick a winner, then implement it in SwiftUI with verified parity. Invoke when the user says "redesign", "explore looks/directions for", "make it feel more premium", or any open-ended visual brief.
---

# Skill: Design Direction Lab

## Purpose
De-risk open-ended visual work by cheaply exploring divergent directions in HTML before committing SwiftUI effort, exactly as Phases 10–12 did (10 prototypes → "Elemental Live" picked → implemented with parity checks). The user chooses the direction; the skill guarantees the shipped SwiftUI matches it.

## When to Invoke
- Open-ended visual briefs: "redesign the table", "explore card looks", "more premium"
- Before any phase whose core deliverable is visual identity rather than behaviour
- NOT for single-screen tweaks with an obvious answer — just make those and /simulator-verify

## Inputs Required
- The brief: which surface(s), what feeling, any hard references
- Constraints that bound the space: docs/design-system.md tokens, memory `wild-pairs-corrections-log` (gloss-print not ivory; no caption text on faces), accessibility floors (colour-blind patterns, Dynamic Type, reduced-motion story)

## Steps

1. **Write a one-page brief first.** Restate the goal, constraints, and what "wins" — get the user's nod if the brief involved any interpretation.

2. **Build 6–10 genuinely divergent HTML prototypes** in `docs/phase-N-design/` (numbered, e.g. `04-elemental-live.html`). Each must be self-contained (inline CSS, no network), use real game content (actual card ranks, colour names, player names — not lorem), and render the same reference state so directions compare fairly. Divergent means different design theses, not one theme at ten intensities.

3. **Present the set with a one-line thesis per direction** and a stated recommendation. STOP for the user's pick. Hybrid picks are normal (Phase 12 = prototype 04's scene + prototype 01's chrome) — capture exactly which elements come from which.

4. **Write the design plan** (`docs/phase-N-design/design-plan.md` pattern): the chosen direction decomposed into implementable pieces — named tokens, recipes/modifiers (the `.wpGlass` pattern), per-view changes, reduced-effects fallbacks, and what is explicitly out of scope. Commit the prototypes with the plan; they are the parity reference.

5. **Implement in SwiftUI**, building shared recipes (theme tokens, view modifiers) before per-view adoption so the direction stays coherent.

6. **Parity-check against the chosen prototype.** Screenshot the app (via /simulator-verify, which owns the per-form-factor checkpoints) and compare side-by-side with the HTML. Deviations are findings: fix or get them explicitly waived.

7. **Run the standard done-bar for touched screens**: /swiftui-quality-review, /accessibility-audit for anything with new visual affordances (patterns, contrast, motion).

## Outputs
- Numbered HTML prototypes + brief committed under `docs/phase-N-design/`
- A design plan naming the chosen direction and its decomposition
- SwiftUI implementation with side-by-side parity evidence per form factor

## Acceptance Criteria
- The user picked the direction from rendered prototypes, not from prose descriptions
- Every prototype respects the standing constraints (no ivory-deck resurrection, no face captions, colour-blind patterns present)
- Shipped screens match the chosen prototype or carry an explicit waiver per deviation

## Common Pitfalls
- Ten variations of one idea instead of divergent theses — the user learns nothing from the spread
- Prototyping with fake content, which hides real problems (long names, 14-card hands, "+4" badges)
- Skipping the design plan and implementing from the HTML by eye — hybrids especially need the element-by-element decomposition written down
- Forgetting the reduced-effects/reduced-motion fallback until review, when it should be a prototype-level decision
- Letting parity drift per form factor — iPad is not iPhone stretched; the plan must say what adapts
