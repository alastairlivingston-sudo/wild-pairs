# Skill: Premortem

## Purpose
For each specialist persona, answer the question: "Six months from now, this project failed because…". Surfaces failure modes before coding begins, turning risks into specific preventive actions — spec additions, test gates, and design constraints. Run before any significant implementation phase and after any major design change.

## When to Invoke
- Before beginning Phase 1 implementation (mandatory)
- After any major design change that affects more than one agent's area
- When the user says "run premortem", "what could go wrong", or "failure analysis"
- When Product Director requests a premortem as part of a phase review

## Inputs Required
- All current project documents (read all docs/ files before beginning)
- Current phase or implementation target (what is about to be built)

## Steps

1. **Read all project documentation.** Read every file in the docs/ directory before beginning. If docs/ does not exist yet, read all .md files at the project root and in .claude/. Form a complete picture of what is planned, what assumptions are made, and what is undefined.

2. **For each persona below, write 1–3 failure modes.** Each failure mode must include:
   - **Failure description:** "The project failed because [specific event]."
   - **Severity:** Critical (project cannot ship) / High (major experience damage) / Medium (notable quality issue)
   - **Likelihood:** High / Medium / Low (given current plans)
   - **Prevention:** Specific action to prevent this failure (not generic advice)
   - **Spec change required:** Which document needs updating to prevent this (or "none")
   - **Test gate required:** What test or check would catch this early (or "none")

   **Personas to cover:**

   a. **Product Director** — scope, focus, priority drift
   b. **UX Lead** — interaction design, learnability, HIG violations, iPad neglect
   c. **iOS Architect** — module boundary violations, state management complexity, persistence corruption
   d. **Game Engine Engineer** — rules bugs, edge cases, non-determinism, save/restore failures
   e. **AI Gameplay Engineer** — hidden-information leaks, illegal AI moves, unfun difficulty, stuck games
   f. **QA Lead** — untested edge cases, flaky tests, bugs found only at release, test debt accumulation
   g. **Accessibility Lead** — VoiceOver unusable, Dynamic Type breaks layout, colour-blind unplayable
   h. **Performance & Reliability Lead** — main thread blocking, save corruption on background, dropped frames
   i. **Privacy & Brand Safety Lead** — accidental network call, UNO trademark reference, telemetry SDK added
   j. **Enterprise Build Lead** — entitlement creep, permission requests, third-party dependency added, build breaks on clean Mac
   k. **Release Manager** — docs out of date at gate, phase advanced without full sign-off, known bugs not recorded

3. **Synthesise the top 5 cross-cutting risks.** After all persona analyses, identify the 5 failure modes that appear across multiple personas or have Critical severity + High likelihood. These are the highest-priority risks.

4. **Apply preventive changes.** For each spec change identified in step 2, make the actual change to the relevant document. Do not leave "spec change: update game-rules.md" as an action item — make the change now.

5. **Create test gates.** For each test gate identified in step 2, either write the test stub immediately (if the codebase exists) or add a TODO to the relevant agent's doc noting the test to be written.

6. **Produce the premortem summary.** Write the full structured output (see Output Format) and save it to docs/premortem.md. Append to the file if it already exists (preserve prior premortem records).

## Outputs
- Full persona-by-persona failure mode analysis (11 personas, 1–3 failures each)
- Top 5 cross-cutting risks (cross-referenced to personas)
- List of spec changes made (with before/after summary)
- List of test gates created or added to agent docs
- Updated docs/premortem.md

## Acceptance Criteria
- All 11 personas covered — no persona skipped
- Every failure mode has a Prevention, Spec change, and Test gate entry (even if "none")
- All spec changes identified are actually made in this session — not deferred
- docs/premortem.md is updated and readable as a standalone record
- The top 5 risks are specific (name the exact mechanism of failure) not generic ("poor quality")

## Common Pitfalls
- Writing vague failures like "the game has bugs" — each failure must name the specific mechanism (e.g., "the engine returns different results for the same seed after a GameState round-trip because Codable conformance omits the RNG state field")
- Skipping the "Apply preventive changes" step and leaving all fixes as future action items
- Covering only technical failure modes — product and UX failures (wrong game, unlearnable, iPhone-only) are equally important
- Running the premortem after coding is already underway and not updating specs retroactively
- Producing a premortem report without updating docs/premortem.md — the record must be written to disk
