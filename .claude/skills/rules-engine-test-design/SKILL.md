# Skill: Rules Engine Test Design

## Purpose
Generate comprehensive test scenarios from docs/game-rules.md. Every rule in the spec gets at least one positive test (rule satisfied) and one negative test (rule violated — engine should reject or handle gracefully). Outputs ready-to-compile Swift XCTest stubs grouped by rule area.

## When to Invoke
- After game-rules.md is written or updated with new rules
- When QA Lead is asked to review test coverage for the engine
- When the user says "generate engine tests", "rules tests", or "test stubs from rules"
- Before any phase gate that includes engine work, to verify test completeness

## Inputs Required
- docs/game-rules.md (must exist and be complete for the current phase)
- WildPairsCore module structure (to know where test files live and what types exist)
- Current test file locations (typically WildPairsCore/Tests/WildPairsTests/)

## Steps

1. **Read docs/game-rules.md.** Read the complete rules document. Extract every numbered rule, sub-rule, card effect, win condition, and edge case. Create a flat list of all rules to be tested (numbered to match the spec).

2. **Group rules by test area.** Organise rules into the following areas (add areas if the rules require them):
   - **Deck:** initial deck composition, card counts, suit/rank distribution
   - **Deal:** initial hand sizes, who goes first, initial discard pile setup
   - **Valid moves:** what constitutes a legal play, matching rules (suit, rank, wild)
   - **Invalid moves:** what must be rejected (engine must not execute an illegal move)
   - **Draw:** when a player must draw, draw count rules, draw pile exhaustion/reshuffle
   - **Card effects:** each action card's effect (skip, reverse, draw two, wild, etc.)
   - **Turn progression:** turn order, direction changes, multi-step turns
   - **Win conditions:** detecting a winner, hand empty, last card rules if any
   - **Persistence:** GameState encode/decode round-trip for each game phase

3. **For each rule, write a test function stub.** Each stub must have:
   - A descriptive function name in the format: `test_[area]_[description]_[positive|negative]`
     - Example: `test_validMove_suitMatch_positive`
     - Example: `test_validMove_noMatchNoWild_negative`
   - A comment block with: Given (precondition), When (action), Then (expected result)
   - `XCTFail("Not yet implemented")` as the body
   - Correct `func` signature in an `XCTestCase` subclass

4. **Group stubs into test classes.** One `XCTestCase` subclass per area. Each class in its own file.

5. **Check for missing coverage.** After generating stubs, read the existing test files (if any) in WildPairsCore/Tests/. Identify any rules that already have tests. Mark those stubs as "already covered" rather than writing duplicates. Identify any existing tests that do not correspond to a rule in game-rules.md — flag these as orphaned tests.

6. **Write the test files.** Write each test file to WildPairsCore/Tests/WildPairsTests/Engine/[AreaName]Tests.swift. If files already exist, add only the missing stubs — do not overwrite existing passing tests.

7. **Produce the coverage summary.** List every rule from game-rules.md and its test status: covered (existing test), stub added (new stub written), or missing (not yet addressed with reason).

## Outputs
- Swift XCTest stub files, one per test area, in WildPairsCore/Tests/WildPairsTests/Engine/
- Coverage summary table: rule reference, description, positive test name, negative test name, status
- List of orphaned tests (existing tests with no corresponding rule)
- List of rules with no test coverage (requires follow-up)

## Acceptance Criteria
- Every numbered rule in game-rules.md has at least one test stub (positive or existing passing test)
- Every action card effect has both a positive and a negative test stub
- Every win condition has a test stub
- The persistence round-trip test covers at least: initial state, mid-game state, completed game state
- All generated stubs compile (correct Swift syntax, correct type references where types are known)
- No existing passing tests are overwritten or deleted

## Common Pitfalls
- Writing only positive tests and forgetting negative tests (illegal move rejection is as important as legal move acceptance)
- Using placeholder type names that do not match the actual WildPairsCore types — read the source before writing stubs
- Writing stubs for rules that are already well-tested — check existing tests first (step 5) to avoid duplication
- Grouping all stubs into a single massive test file — one file per area is required for maintainability
- Writing test function names that are too generic (e.g., `test_cardEffect`) rather than specific (`test_cardEffect_skipCard_advancesTwoTurns_positive`)
