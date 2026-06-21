#!/usr/bin/env bash
# Run on Mac with Xcode installed.
# Usage: bash scripts/run_unit_tests.sh
# Run all unit tests for the WildPairsCore Swift Package.
# Filters: EngineTests, RulesTests, AITests, PersistenceTests.
# Exit 0 = PASS (all tests pass). Exit 1 = FAIL (any test fails or build error).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- Unit Tests"
echo "$(date)"
echo "========================================"
echo "Project root: $PROJECT_ROOT"
echo ""

# Run tests with verbose output to show counts
OUTPUT=$(swift test \
    --package-path "$PROJECT_ROOT" \
    --filter "EngineTests|RulesTests|AITests|PersistenceTests" \
    2>&1)

EXIT_CODE=$?
echo "$OUTPUT"

echo ""
echo "========================================"

# Extract test counts from output
TOTAL=$(echo "$OUTPUT" | grep -E "^Test Suite.*executed" | grep -oE "[0-9]+ test" | head -1 | grep -oE "[0-9]+" || echo "0")
FAILED=$(echo "$OUTPUT" | grep -E "^Test Suite.*executed" | grep -oE "[0-9]+ failure" | head -1 | grep -oE "[0-9]+" || echo "0")

echo "Tests run: ${TOTAL:-unknown}"
echo "Failures:  ${FAILED:-unknown}"

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "RESULT: PASS"
    exit 0
else
    echo ""
    # Show just the failure lines for quick diagnosis
    echo "Failed tests:"
    echo "$OUTPUT" | grep -E "FAILED|error:|failed" | head -20 || true
    echo ""
    echo "RESULT: FAIL"
    exit 1
fi