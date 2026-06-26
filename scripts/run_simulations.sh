#!/usr/bin/env bash
# Runs on macOS with Xcode installed.
# Usage: bash scripts/run_simulations.sh
# Run AI balance simulation tests.
# Filters: SimulationTests target in WildPairsCore.
# Shows simulation counts, win rates, illegal move count, stuck game count.
# Exit 0 = PASS. Exit 1 = FAIL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- AI Balance Simulations"
echo "$(date)"
echo "========================================"
echo "Project root: $PROJECT_ROOT"
echo "Note: Simulations may take several minutes depending on N."
echo ""

OUTPUT=$(swift test \
    --package-path "$PROJECT_ROOT" \
    --filter "SimulationTests" \
    2>&1)

EXIT_CODE=$?
echo "$OUTPUT"

echo ""
echo "========================================"
echo "Simulation Summary"
echo "========================================"

# Extract key metrics from test output (assumes SimulationTests print structured output)
# These grep patterns match expected print statements in SimulationTests
echo ""
echo "Key metrics (extracted from test output):"
echo "$OUTPUT" | grep -iE "simulations? run|win rate|illegal move|stuck game|game length" | head -30 || \
    echo "  (No structured metric output found -- check SimulationTests for print statements)"

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "RESULT: PASS -- All simulation tests passed."
    echo "Review docs/ai-balance-report.md for balance analysis."
    exit 0
else
    echo ""
    echo "Failed test output:"
    echo "$OUTPUT" | grep -E "FAILED|error:|failed" | head -20 || true
    echo ""
    echo "RESULT: FAIL"
    exit 1
fi