# Skill: Phase Gate

## Purpose
Verify all acceptance criteria for the current development phase before advancing to the next phase. Produces a structured go/no-go decision with full audit trail. This is the mandatory checkpoint between phases — no phase advances without this skill completing with a GO result.

## When to Invoke
- At the declared completion of any development phase
- When the user says "run phase gate", "check if we can advance", or "phase N is done"
- Before any phase-scoped documentation handover
- When Release Manager agent is preparing a sign-off

## Inputs Required
- Current phase number and name (e.g., "Phase 2: Core Engine")
- Path to release-checklist.md (or instruction to create it if it does not exist)
- Confirmation that this is being run on macOS with Xcode installed (scripts require macOS)

## Steps

1. **Read phase acceptance criteria.** Read docs/release-checklist.md and locate the section for the current phase. If the file does not exist, create a stub and flag that criteria must be defined before proceeding. List every criterion explicitly — do not summarise.

2. **Run quality_full.sh.** Execute `bash scripts/quality_full.sh` from the project root. Capture the full output. Record PASS or FAIL for each sub-check. If any check fails, record the specific failure output.

3. **Review known-issues.md.** Read docs/known-issues.md. List all open issues. Flag any with severity P1 (crash or data loss) — these are blocking. Flag P2 issues and check each has a documented plan. P3 issues are noted but do not block.

4. **Check all agent documents exist and are current.** Verify the following files exist and were updated this phase:
   - docs/technical-architecture.md
   - docs/game-rules.md
   - docs/state-machine.md
   - docs/ux-spec.md
   - docs/ai-strategy.md (if AI work done this phase)
   - docs/ai-balance-report.md (if simulations run this phase)
   - docs/accessibility-plan.md
   - docs/privacy-offline-plan.md
   - docs/enterprise-build-notes.md
   - docs/permission-audit.md
   - docs/known-issues.md

5. **Verify test completeness.** Run `bash scripts/run_unit_tests.sh` and record test count and pass/fail. If test count has not grown since the last phase, flag as a concern. Check that all new features added this phase have corresponding tests.

6. **Run all security/privacy scripts individually.** Run each of the following and record PASS/FAIL:
   - `bash scripts/check_no_network_usage.sh`
   - `bash scripts/check_permissions_minimal.sh`
   - `bash scripts/check_project_capabilities.sh`
   - `bash scripts/check_privacy_manifest.sh`

7. **Collect agent confirmations.** For each specialist agent area, state whether their criteria are met based on the evidence gathered. Do not ask agents directly — assess from the document state and script results.

8. **Produce sign-off summary.** Write the structured report (see Output Format) and update release-checklist.md with the result. Record date and phase in the release history section.

## Outputs
- Console output of each script run
- Structured phase gate report (see Output Format in release-manager.md)
- Updated release-checklist.md with this phase's result appended
- List of any blocking items that must be resolved before GO

## Acceptance Criteria
- All quality_full.sh sub-checks pass (exit 0)
- Zero open P1 bugs in known-issues.md
- All required documents exist and have been updated this phase
- All security/privacy scripts pass
- Unit test count is non-zero and has grown since the previous phase (or is justified if flat)

## Common Pitfalls
- Running on Windows instead of macOS — scripts require macOS with Xcode and swift CLI installed
- Not reading known-issues.md and missing a P1 bug that blocks the gate
- Treating a "file exists" check as sufficient — documents must be updated this phase, not just present
- Skipping the individual privacy/security script runs because quality_full.sh already calls them — run them individually to get separate PASS/FAIL signals for the report
- Advancing with a "conditional GO" without documenting exactly what conditions must be met and by when
