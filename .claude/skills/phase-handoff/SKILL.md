---
name: phase-handoff
description: Close out a completed phase — record the gate verdict, write the next-session brief, update known issues and memory, and prepare the commit. Invoke after /phase-gate returns GO, or when the user says "wrap up the phase", "handoff", or ends a major work stretch.
---

# Skill: Phase Handoff

## Purpose
Make the next session (or a fresh model) able to continue without re-deriving context: gate verdict recorded, a brief written in the docs/phase-6-8-brief.md tradition, known issues current, and durable lessons moved into memory.

## When to Invoke
- Immediately after /phase-gate returns GO for the phase
- When the user says "wrap up", "hand off", or "we're done with this phase"
- At the end of any major multi-session work stretch, even mid-phase, when context would otherwise be lost

## Inputs Required
- The phase (or work stretch) being closed and its gate verdict
- Anything the user wants explicitly carried forward or dropped

## Steps

1. **Confirm the gate.** If /phase-gate has not run for a phase-boundary handoff, run it now. A NO-GO still gets a handoff — recording *why* it failed and what remains is the more valuable brief.

2. **Write or update the next-phase brief** in `docs/` (e.g. `phase-N-brief.md` or the roadmap doc): what was delivered (link commits, don't re-narrate), decisions made and their why, open items ranked, and the exact commands/recipes a fresh session needs. Assume the reader has CLAUDE.md and nothing else.

3. **Reconcile known-issues.md.** Close fixed issues, add newly observed ones with severity and repro steps (QA Lead format), and flag any flaky tests for the flake-hardener agent.

4. **Update memory.** Refresh the initiative status memory (current state + open items); move any newly paid-for lessons into the right file — traps to `swiftui-ios-traps`, rule/design decisions to `wild-pairs-corrections-log`, workflow changes to `wild-pairs-verification-recipe`. History that git already records does not go into memory.

5. **Sweep the working tree.** `git status` — everything should be committed or deliberately discarded. Propose the commit (phase-titled, matching the existing `Phase N: …` convention) but only commit when the user has asked for commits or does now.

6. **State the restart line.** End with the single sentence a next session should start from ("Phase 15 starts at X; first task is Y; verify with Z").

## Outputs
- Gate verdict recorded (GO, or NO-GO with the gap list)
- Next-session brief in docs/
- Reconciled known-issues.md, updated memory files
- Clean or explicitly-dispositioned working tree and a proposed commit

## Acceptance Criteria
- A fresh session given only CLAUDE.md + the brief + memory could continue without asking recap questions
- No lesson learned this phase lives only in the transcript
- known-issues.md agrees with reality (no fixed-but-open, no observed-but-missing)

## Common Pitfalls
- Writing the brief as a diary of what happened instead of instructions for what's next
- Duplicating git history into memory — memory is for what git can't show (why, preferences, traps)
- Leaving flaky-test observations in the transcript instead of known-issues.md (KI-035 was nearly lost this way)
- Skipping the handoff on a NO-GO, which is exactly when the next session needs it most
