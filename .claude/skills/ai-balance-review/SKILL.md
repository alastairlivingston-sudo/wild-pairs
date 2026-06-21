# Skill: AI Balance Review

## Purpose
Read simulation output from docs/ai-balance-report.md and flag any balance issues against the acceptance targets defined in docs/ai-strategy.md. Produces a structured findings report with specific weight-adjustment recommendations for any out-of-range metric.

## When to Invoke
- After running scripts/run_simulations.sh and updating ai-balance-report.md with results
- When AI Gameplay Engineer requests a balance review
- When the user says "AI balance review", "check balance report", or "review simulation results"
- At every phase gate that includes AI work

## Inputs Required
- docs/ai-balance-report.md (must contain simulation run results)
- docs/ai-strategy.md (defines acceptance targets for each metric)
- Optionally: the AI source files (for recommending specific code changes)

## Steps

1. **Read docs/ai-strategy.md.** Extract the defined acceptance targets for each metric:
   - Win rate target ranges per difficulty matchup (e.g., Easy vs Random: target 40–60% for Easy)
   - Maximum allowed game length (turns or rounds)
   - Maximum allowed stuck game count (target: 0)
   - Maximum allowed illegal move count (target: 0 across all simulations)
   - Minimum simulation count required for statistical validity (e.g., N≥1000 per matchup)
   If any target is undefined in ai-strategy.md, flag this as a missing spec item and halt — do not proceed without defined targets.

2. **Read docs/ai-balance-report.md.** Extract the most recent simulation run results. Record:
   - Run date and simulation count
   - Win rates per difficulty matchup
   - Distribution of game lengths (min, mean, max, p95)
   - Illegal move count (total across all simulations)
   - Stuck game count (games that exceeded maximum length or had no legal moves)
   - Any notes from the simulation runner

3. **Check simulation validity.** Before evaluating balance:
   - Was the simulation count sufficient (meets minimum N from ai-strategy.md)? If not: flag as INVALID and do not evaluate balance metrics — more simulations are needed first.
   - Was the simulation run with the current codebase? Check run date against recent code changes. If stale: flag as STALE and request a new run.

4. **Check illegal move count.** Compare to target (must be 0).
   - 0: PASS
   - >0: FAIL — BLOCKING. Any illegal move is a critical bug. Record count, and if the report includes which difficulty or game position produced the illegal move, record that detail. Recommend: add a unit test that reproduces the illegal move, fix the AI move selector to never request a move not in the valid-moves list.

5. **Check stuck game count.** Compare to target (must be 0).
   - 0: PASS
   - >0: FAIL — BLOCKING. A stuck game indicates the engine or AI has a dead-end state. Record count and any game IDs or seeds if available. Recommend: add a debug simulation that replays stuck games to identify the state.

6. **Check win rates per matchup.** For each difficulty matchup, compare the win rate to the target range from ai-strategy.md:
   - Within range: PASS
   - Above upper bound: FAIL — AI is too strong for this difficulty level (recommendation: reduce weight of look-ahead, increase random move probability, or lower evaluation score for aggressive plays)
   - Below lower bound: FAIL — AI is too weak for this difficulty level (recommendation: opposite adjustments)
   Record the specific matchup, actual rate, and target range for each FAIL.

7. **Check game length distribution.** Compare p95 game length to maximum allowed:
   - p95 ≤ maximum: PASS
   - p95 > maximum: FAIL — games are running too long, suggesting the AI is not making progress toward a win. Recommend: increase weight of hand-reduction heuristic, reduce defensive play.
   Also check if minimum game length is suspiciously low (< deal size + minimum turns to win) — this may indicate the AI is winning unfairly fast on Easy.

8. **Check Easy difficulty win rate against Hard.** Easy should not beat Hard more than the target allows (e.g., Easy win rate vs Hard should be <30%). This ensures difficulty levels are meaningfully differentiated.

9. **Produce findings report.** Structure:
   - Overall status: PASS (all checks pass) / FAIL (any check fails)
   - Per-metric table: metric, target, actual, status, severity
   - Blocking issues: illegal moves and stuck games (must be resolved before phase gate)
   - Tuning recommendations: specific weight changes or heuristic adjustments for out-of-range win rates
   - Next steps: re-run simulations after fixes and repeat this review

10. **Update docs/ai-balance-report.md.** Append the review findings to the report (do not overwrite simulation data). Record date, reviewer (AI Balance Review skill), and verdict.

## Outputs
- Structured findings report (overall PASS/FAIL, per-metric table, blocking issues, recommendations)
- Updated docs/ai-balance-report.md with review section appended
- Specific tuning recommendations for any out-of-range metric

## Acceptance Criteria
- All metrics within target ranges: overall PASS
- Illegal move count = 0: PASS (any non-zero is blocking)
- Stuck game count = 0: PASS (any non-zero is blocking)
- All win rates within target bands from ai-strategy.md
- Game length p95 ≤ maximum allowed
- Simulation count ≥ minimum N for statistical validity

## Common Pitfalls
- Reviewing stale simulation data — always check the run date against recent code changes before evaluating
- Accepting a zero illegal-move count from an insufficient simulation count (N=10 doesn't prove correctness)
- Giving weight-adjustment recommendations without reading the actual AI source code — recommendations that don't match the actual heuristic structure are not actionable
- Treating a PASS on all current metrics as proof the AI is fun — balance metrics are necessary but not sufficient; fun requires human play testing
- Not flagging an undefined target in ai-strategy.md — if the target is not written down, the check is not meaningful
