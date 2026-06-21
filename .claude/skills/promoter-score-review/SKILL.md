# Skill: Promoter Score Review

## Purpose
NPS-style review of the Wild Pairs experience for each of the 10 defined user personas. Each persona scores the current design 0–10 (would they recommend it?), explains what delights them, what frustrates them, what would make them stop playing, and what must improve before they would give a 9 or 10. Apply the improvements before coding begins or after a design change.

## When to Invoke
- Before Phase 1 implementation (after premortem, before coding)
- After any major UX or rules redesign
- When the user says "promoter score review", "NPS review", or "persona review"
- When Product Director requests a persona review as part of scope evaluation

## Inputs Required
- All current project documents (read docs/ux-spec.md, docs/game-rules.md, docs/technical-architecture.md, and any other docs/ files)
- The current design or spec for the area under review (if reviewing a specific feature, provide the spec)

## Steps

1. **Read all relevant documentation.** Read docs/ux-spec.md, docs/game-rules.md, and any other documents relevant to the user experience. Form a clear picture of the intended design.

2. **For each persona, produce a structured review.** Each persona must have:
   - **Score (0–10):** Would this persona recommend Wild Pairs to a friend?
     - 0–6 = Detractor (experience has serious problems for this persona)
     - 7–8 = Passive (acceptable but not exciting)
     - 9–10 = Promoter (would actively recommend)
   - **What delights:** 1–3 specific things this persona loves about the current design
   - **What frustrates:** 1–3 specific friction points or problems for this persona
   - **Deal-breaker:** What would make this persona stop playing and uninstall?
   - **Must improve:** What specific change would move their score to 9 or 10?

   **Personas to cover:**

   a. **Casual Player** — plays occasionally, wants quick fun, low rules overhead, no commitment
   b. **Strategic Player** — wants depth, meaningful decisions, challenge at Hard difficulty
   c. **First-Time Card Game Player** — has never played a hand-management card game, needs excellent onboarding
   d. **Older / Low-Vision Player** — may have presbyopia, prefers larger text and high contrast, less comfortable with dense UI
   e. **Colour-Blind Player** — deuteranopia or protanopia; cannot distinguish red from green
   f. **VoiceOver User** — plays entirely with VoiceOver, uses swipe navigation, hears all state via audio
   g. **Impatient Commuter / Offline User** — on a train with no signal, wants to pick up and play in under 10 seconds, frequently interrupted
   h. **Personal Power User** — the developer/owner; wants full control, stats, the ability to restart, clear game history
   i. **iPad Player** — plays on iPad at a table, wants a desktop-like experience, may use with family
   j. **Enterprise Developer** — the person building this; wants clean builds, no entitlement friction, no MDM policy conflicts

3. **Calculate summary statistics.** Count Detractors (0–6), Passives (7–8), and Promoters (9–10). Calculate NPS: (% Promoters - % Detractors). State the overall NPS and flag any persona scoring 6 or below as a blocking concern.

4. **Identify the top 5 improvements.** Across all personas, identify the 5 changes that would have the greatest positive impact on NPS scores (i.e., would convert the most Detractors to Passives, or Passives to Promoters).

5. **Apply the improvements.** For each of the top 5 improvements: make the actual spec change, add a note to the relevant agent's document, or create a tracked item in known-issues.md if it is a known gap. Do not leave improvements as unacted-on recommendations.

6. **Update docs/persona-review-log.md.** Append this review to the log with date, which phase or design was reviewed, all 10 persona scores and brief notes, NPS, and what was changed. If the file does not exist, create it.

## Outputs
- 10 persona review blocks (score, delights, frustrations, deal-breaker, must-improve)
- NPS summary (Detractors, Passives, Promoters, NPS score)
- Top 5 improvements with disposition (spec changed, agent doc updated, or issue logged)
- Updated docs/persona-review-log.md

## Acceptance Criteria
- All 10 personas covered — no persona skipped
- Every persona has a numeric score with written justification
- All personas scoring 6 or below are treated as blocking concerns with mandatory improvement actions
- Top 5 improvements are acted on in this session — not deferred
- docs/persona-review-log.md is updated

## Common Pitfalls
- Writing the same review for multiple personas — each persona has distinct needs; the Casual Player and Strategic Player will have very different scores and frustrations
- Giving artificially high scores to avoid improvement work — be honest; a Detractor score (0–6) is valuable signal
- Identifying improvements without acting on them — spec changes must be made in this session
- Forgetting the Enterprise Developer persona — this is both a user persona and the builder; their experience with the build process matters
- Treating the VoiceOver User review as identical to the Accessibility Lead's review — this persona is about the user experience, not the implementation checklist
