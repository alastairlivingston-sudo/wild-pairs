#!/usr/bin/env bash
# Runs on macOS with Xcode installed.
# Usage: bash scripts/quality_light.sh
# Fast quality check after Swift edits. Should complete in under 60 seconds.
# Runs: Swift Package build, fast unit tests, network scan.
# Exit 0 = PASS. Exit 1 = FAIL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
FAILURES=()

run_check() {
    local name="$1"
    local cmd="$2"
    echo ""
    echo "--- $name ---"
    if eval "$cmd"; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $name"
        FAIL=$((FAIL + 1))
        FAILURES+=("$name")
    fi
}

echo "========================================"
echo "Wild Pairs -- Quality Gate (Light)"
echo "$(date)"
echo "========================================"

# 1. Swift Package build
run_check "Swift Package Build" \
    "swift build --package-path \"$PROJECT_ROOT\" 2>&1"

# 2. Fast unit tests (engine tests only)
run_check "Fast Unit Tests (EngineTests)" \
    "swift test --package-path \"$PROJECT_ROOT\" --filter WildPairsTests.EngineTests 2>&1"

# 3. Network usage scan
run_check "No Network Usage Scan" \
    "bash \"$SCRIPT_DIR/check_no_network_usage.sh\""

echo ""
echo "========================================"
echo "Quality Gate (Light) Summary"
echo "========================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ ${#FAILURES[@]} -gt 0 ]; then
    echo ""
    echo "FAILED checks:"
    for f in "${FAILURES[@]}"; do
        echo "  - $f"
    done
    echo ""
    echo "RESULT: FAIL"
    exit 1
else
    echo ""
    echo "RESULT: PASS"
    exit 0
fi