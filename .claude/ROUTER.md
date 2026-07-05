# Skill and Agent Router

How to route work in this repo to the project's skills (`.claude/skills/`), agents
(`.claude/agents/`), and workflows. Read this before improvising a process that already exists.

## Routing Principles

- Prefer an existing skill over an ad-hoc process; prefer the narrowest matching skill.
- Gates outrank reviews: a phase-gate request runs `/phase-gate`, which invokes the subordinate
  reviews itself — don't run them separately first.
- Reviews report; they do not fix. Apply fixes only when asked, then re-run the review that
  found the issue.
- Rule changes travel as a unit: engine code + `docs/game-rules.md` + CLAUDE.md + regression
  tests in one change.
- Visual changes are verified per form factor with a user checkpoint between form factors
  (iPhone → iPad → other size classes). Never declare UI work done from code reading alone.
- Agents own areas (see CLAUDE.md §Agent Ownership); skills own checkpoints. When a request
  names an area, adopt that agent's charter; when it names a milestone, run the skill.

## Routing Table

| Request pattern | Use | Why | Output |
|---|---|---|---|
| "Phase N is done" / "can we advance" | `/phase-gate` | Mandatory checkpoint; no phase advances without GO | Go/no-go with audit trail |
| SwiftUI view written or changed | `/swiftui-quality-review` | Implementation-complete bar | Severity-rated findings |
| Screen spec or flow needs judging | `/ux-review` | HIG + ux-spec.md heuristic audit | Scored, ranked findings |
| Judge captured app screenshots vs spec | `/design-critique` | Deep visual critique of real screenshots | Design findings |
| Screen ready for a11y sign-off / "VoiceOver check" | `/accessibility-audit` | Deeper than the quality-review spot-check | Pass/fail checklist |
| Ran `run_simulations.sh` / "check balance" | `/ai-balance-review` | Targets in ai-strategy.md | Weight-adjustment findings |
| `game-rules.md` added/changed rules | `/rules-engine-test-design` | Every rule gets positive+negative tests | Swift test stubs by rule area |
| New capability, Info.plist key, permission | `/enterprise-permission-audit` | Offline/enterprise guarantee | PASS/FAIL per check |
| Before a major phase or design change | `/premortem` then `/promoter-score-review` | Risks first, then persona value | Preventive actions; NPS per persona |
| "When I played, X happened" (bug from a play session) | `/playtest-fix` | Engine fix + docs + regression test as one atomic change | Fix with no doc drift |
| UI change needs visual proof | `/simulator-verify` | Proven unattended screenshot loop, per-form-factor checkpoints | Screenshots + verdict per form factor |
| Open-ended visual brief ("redesign", "explore looks") | `/design-direction-lab` | Divergent HTML prototypes before SwiftUI commitment | User-picked direction, parity-checked implementation |
| Phase complete (after gate GO) or major stretch ends | `/phase-handoff` | Next session must continue without recap questions | Brief + reconciled KIs + memory update |
| Flaky XCUITest (see docs/known-issues.md) | flake-hardener agent, background, isolated worktree | Pattern proven on testResumeAfterBackgrounding (merge 9a1ba4a) | Hardened test + repeat-run proof |
| Memory files stale, duplicated, or bloated | `/consolidate-memory` (harness) | Purpose-built reflective pass; don't hand-roll | Merged/pruned memory + index |
| Scope, personas, MVP questions | product-director charter | Owns scope | Decision memo |
| Release prep, checklist, handover | release-manager charter + `docs/release-checklist.md` | Owns the gate docs | Checklist updates |
| Working diff needs a bug hunt | `/code-review` (harness) | Project skills review screens, not diffs | Ranked findings |

## Conflict Rules

When multiple entries match:

1. `/phase-gate` subsumes the per-screen reviews — run it alone at phase boundaries.
2. For a single finished screen, the order is: `/swiftui-quality-review` → `/ux-review` →
   `/accessibility-audit` → simulator verification. Done means all four.
3. A play-session bug that changes a rule triggers `/rules-engine-test-design` after the fix,
   and `/enterprise-permission-audit` only if surface area changed.
4. If a request would violate CLAUDE.md's enterprise constraints (any networking, new
   permissions), the constraint wins — decline and offer the compliant alternative
   (precedent: multiplayer → same-device pass-and-play).

## Default Behavior

If nothing matches: handle inline under CLAUDE.md's constraints and coding style; do not invent
a new skill or agent mid-task. If the work is outside this repo (Budget & Tax Companion, VIVO),
read the target folder first — those projects have no canon yet.
