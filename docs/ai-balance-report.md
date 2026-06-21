# AI Balance Report

> Owner: ai-gameplay-engineer | Status: **Placeholder — populated after Phase 4 simulations**

## Purpose
This document records the results of automated AI simulations used to verify difficulty balance, detect stuck games, and confirm AI move validity before each release.

## Simulation Configuration
| Parameter | Value |
|---|---|
| Modes tested | Standard Teams, All-Wild Teams, Side-to-Side Teams |
| Difficulty pairings | Easy vs Easy, Medium vs Easy, Hard vs Medium, Expert vs Hard |
| Games per pairing | 1,000 (smoke: 100, balance: 1,000, optional deep: 10,000) |
| Seed | Deterministic seed per run for reproducibility |
| Runner | `swift test --filter SimulationTests` |

## Metrics Tracked
- Win rates by difficulty pairing and mode
- Average turns per round
- Average round duration (simulated)
- Action card usage frequencies
- Draw pile reshuffles per game
- Each win condition frequency
- AI illegal move count (must be zero)
- Stuck game count (must be zero)
- Outlier game lengths (>200 turns flagged)

## Acceptance Criteria
- Zero illegal AI moves in all simulations
- Zero stuck games
- Expert win rate vs Easy ≥ 60% (over 1,000 games, all modes averaged)
- Hard win rate vs Easy ≥ 55%
- No mode produces games lasting >150 turns in median
- No mode has >1% of games lasting >300 turns

## Results — Phase 4

> _To be completed after Phase 4 AI implementation._

### Run date: TBD
### Seed: TBD

| Pairing | Mode | Games | Win Rate | Avg Turns | Illegal Moves | Stuck Games |
|---|---|---|---|---|---|---|
| Easy vs Easy | Standard | - | - | - | - | - |
| Medium vs Easy | Standard | - | - | - | - | - |
| Hard vs Medium | Standard | - | - | - | - | - |
| Expert vs Hard | Standard | - | - | - | - | - |
| Easy vs Easy | All-Wild | - | - | - | - | - |
| Expert vs Hard | All-Wild | - | - | - | - | - |
| Easy vs Easy | Side-to-Side | - | - | - | - | - |
| Expert vs Hard | Side-to-Side | - | - | - | - | - |

## Analysis — Phase 4

> _To be completed._

## Changes Applied from This Report

> _To be completed._
