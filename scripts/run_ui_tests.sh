#!/usr/bin/env bash
# Runs on macOS with Xcode installed.
# Usage: bash scripts/run_ui_tests.sh
# Run UI tests on iPhone and iPad simulators using xcodebuild.
# Requires: Xcode project at project root (available after Phase 5).
# Exit 0 = PASS. Exit 1 = FAIL. Prints SKIP if xcodeproj not found.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- UI Tests"
echo "$(date)"
echo "========================================"

# Find xcodeproj
XCODEPROJ=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.xcodeproj" 2>/dev/null | head -1)

if [ -z "$XCODEPROJ" ]; then
    echo ""
    echo "SKIP: No .xcodeproj found in project root."
    echo "UI tests are available after Phase 5 (Xcode project creation)."
    echo "To create the Xcode project: open Xcode, File > New > Project,"
    echo "or run: xcodebuild -project WildPairsApp.xcodeproj ..."
    echo ""
    echo "RESULT: SKIP"
    exit 0
fi

echo "Using project: $XCODEPROJ"
echo ""

# Scheme name comes from project.yml; its default test action already targets
# WildPairsUITests, so no -testPlan argument is needed (there is no .xctestplan in this repo).
SCHEME="WildPairs"
PASS=0
FAIL=0
FAILURES=()

# Device names age out as new simulator runtimes ship — override via env vars if these are no
# longer installed, e.g.: IPHONE_SIM="iPhone 16" bash scripts/run_ui_tests.sh
IPHONE_SIM="${IPHONE_SIM:-iPhone 17}"
IPAD_SIM="${IPAD_SIM:-iPad Air 13-inch (M4)}"

run_ui_tests_on_destination() {
    local dest_name="$1"
    local destination="$2"
    echo ""
    echo "--- UI Tests: $dest_name ---"
    if xcodebuild test \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -configuration Debug \
        2>&1 | tail -30; then
        echo "PASS: UI Tests on $dest_name"
        PASS=$((PASS + 1))
    else
        echo "FAIL: UI Tests on $dest_name"
        FAIL=$((FAIL + 1))
        FAILURES+=("$dest_name")
    fi
}

# iPhone (compact width)
run_ui_tests_on_destination \
    "$IPHONE_SIM (compact)" \
    "platform=iOS Simulator,name=$IPHONE_SIM,OS=latest"

# iPad (regular width)
run_ui_tests_on_destination \
    "$IPAD_SIM (regular)" \
    "platform=iOS Simulator,name=$IPAD_SIM,OS=latest"

echo ""
echo "========================================"
echo "UI Test Summary"
echo "========================================"
echo "Passed destinations: $PASS"
echo "Failed destinations: $FAIL"

if [ ${#FAILURES[@]} -gt 0 ]; then
    echo ""
    echo "FAILED destinations:"
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