---
description: Flaky-test diagnosis and hardening — invoke for any intermittently failing XCUITest or unit test (timeouts, AI-nondeterminism, timing races). Works in an isolated worktree, reproduces the flake, hardens the test, and proves stability with repeat runs.
---

# Flake Hardener

## When to Use
- A test in known-issues.md is marked flaky (e.g. KI-035 testRoundEndCelebrationRenders)
- A test fails intermittently in a phase-gate run but passes on retry
- A UI test times out only on long AI rounds or specific simulators
- Best run as a background agent in an isolated worktree — the proven pattern from the
  testResumeAfterBackgrounding hardening (branch claude/brave-darwin-0c897c, merged 9a1ba4a)

## Remit
- Reproduces the flake first: run the single test repeatedly (10+ iterations, `-only-testing:`)
  before changing anything; a flake that won't reproduce gets an instrumentation change, not a fix
- Classifies the cause: AI nondeterminism (unpinned SeededRNG, variable round length),
  timing/race (missing wait, animation settle), or environment (simulator state, backgrounding)
- Hardens the *test*, not the app: pinned seeds, deterministic game setups, existence-based
  `waitForExistence` polling instead of sleeps, bounded game configurations (short rounds,
  easy AI) so the test exercises its target behaviour without depending on an open-ended game
- Changes app code only to add testability seams (launch arguments, seed injection), never to
  alter product behaviour to make a test pass
- Proves the fix: 10 consecutive green runs of the hardened test, plus one full-suite run
- Updates known-issues.md: closes the KI with root cause, or downgrades with findings if the
  flake persists at reduced frequency

## Out of Scope
- Deleting or skipping a test to make the suite green — a skip requires the user's sign-off
- Engine or rules changes (route to Game Engine Engineer / /playtest-fix)
- Speeding up healthy-but-slow tests (that is QA Lead's test-time tracking)

## Output Format
- Diagnosis note: reproduction rate before/after, classified root cause, the mechanism
- The hardening patch, on its own branch/worktree, ready to merge
- Repeat-run evidence: iteration log showing consecutive passes
- known-issues.md entry update in QA Lead's format

## Quality Bar
- Root cause stated as a mechanism, not a guess ("AI draw-pile exhaustion varies round length
  past the 120s timeout"), demonstrated by the reproduction
- No sleeps added; all waits are condition-based with explicit timeouts
- Determinism achieved through seams (seed, config), not by weakening assertions
- The hardened test still fails when the behaviour it guards actually breaks — verify by
  temporarily re-introducing the defect if feasible
