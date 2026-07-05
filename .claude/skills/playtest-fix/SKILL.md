---
name: playtest-fix
description: Turn a play-session bug report ("when I played, X happened") into an atomic change — engine fix + game-rules.md + CLAUDE.md + regression test together. Invoke when the user reports wrong game behaviour observed while playing Wild Pairs.
---

# Skill: Playtest Fix

## Purpose
Convert a user-observed gameplay problem into a single coherent change where the engine fix, the rules documentation, and a regression test land together, so the rules docs never drift from the engine. Phase 13 and 14 were this loop; drifted docs nearly resurrected a dead rule once already.

## When to Invoke
- When the user reports behaviour from an actual play session ("when I played…", "the AI did X", "the round ended wrong")
- When a rules question reveals the engine and docs/game-rules.md disagree
- When a house-rule or rule-design change is requested (not just a bug)

## Inputs Required
- The observed behaviour and, if possible, the game situation (cards, mode, who was out)
- Whether this is a suspected bug (engine violates the written rule) or a rule-design change (the written rule should change)

## Steps

1. **Classify before touching code.** Read the relevant section of docs/game-rules.md and check memory `wild-pairs-corrections-log` — the behaviour may be a deliberate past decision (e.g. Solo! declares at two cards, not one). Three outcomes: engine bug, rule-design change, or working-as-designed (explain and stop).

2. **Reproduce deterministically.** Use SeededRNG injection to construct the failing state in a Swift Testing test before fixing. If the report involves AI choices, pin the seed and difficulty. This failing test becomes the regression test.

3. **Diagnose in the reducer.** The engine is a pure function `(GameState, GameAction) -> (GameState, [GameEffect])` — trace the reduction for the reproduced state. Precedent to remember: order-of-resolution bugs are a known class (a Draw Two/Four played as the winning final card once ended the round before its penalty applied).

4. **Fix the engine.** Respect the module boundary: WildPairsCore only, no UI knowledge. Keep Codable compatibility — new fields on snapshot types must decode from old saves (optional with sensible defaults), matching the `Player.soloGraceAtOne` precedent.

5. **Update the docs in the same change.** docs/game-rules.md for the rule text; CLAUDE.md if canonical vocabulary or a headline mechanic changed; docs/state-machine.md if transitions changed. Remove superseded rule text entirely — do not leave both versions.

6. **Lock in tests.** The reproduction test from step 2 now passes; add negative cases. For a rule-design change (not just a bug), run /rules-engine-test-design on the updated rules section to generate full positive/negative coverage.

7. **Run the gates.** `./scripts/quality_light.sh` (known false positives: `.tracking(1)`, stats copy — disposition rows, not code changes). `swift test --package-path . --filter WildPairsTests.EngineTests` and RulesTests at minimum.

8. **Verify visually if the fix is visible.** If the change alters anything rendered (badges, prompts, card tinting), invoke /simulator-verify.

9. **Record the decision.** If the rule *design* changed, append it to memory `wild-pairs-corrections-log` (why + how to apply) so no future session reintroduces the old rule from stale context.

## Outputs
- One coherent change: engine fix + doc updates + regression test
- A one-paragraph explanation of root cause and the rule as it now stands
- Updated memory when the rule design (not just the implementation) changed

## Acceptance Criteria
- The regression test fails on the old code and passes on the new
- docs/game-rules.md, CLAUDE.md, and the engine agree — no stale rule text survives
- Old save files still decode (test with a legacy fixture; note `[TeamID: Int]` encodes as a flat key/value array in JSON)

## Common Pitfalls
- Fixing to match a stale doc instead of the current rule decision — check the corrections log first
- Shipping the engine fix and deferring the doc edit "for later" — that is how drift starts
- Writing the regression test after the fix and never seeing it fail
- Breaking old-save decoding with a non-optional new field
- Treating an AI heuristic quirk as an engine bug — AI behaviour issues route to /ai-balance-review and the AI Gameplay Engineer instead
