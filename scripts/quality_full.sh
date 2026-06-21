#!/usr/bin/env bash
# Run on Mac with Xcode installed.
# Usage: bash scripts/quality_full.sh
# Complete quality gate at phase completion. May take several minutes.
# Runs: Swift Package build, all unit tests, simulation tests,
#       network/permission/capability/privacy checks, and (after Phase 5) Xcode app build.
# Exit 0 = PASS. Exit 1 = FAIL.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
FAIL=0
FAILURES=()
SKIPS=()

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

run_check_optional() {
    local name="$1"
    local cmd="$2"
    local skip_msg="$3"
    echo ""
    echo "--- $name ---"
    if eval "$cmd" 2>/dev/null; then
        echo "PASS: $name"
        PASS=$((PASS + 1))
    else
        local exit_code=$?
        # Check if skip condition applies
        if eval "$skip_msg" 2>/dev/null; then
            echo "SKIP: $name (see message above)"
            SKIPS+=("$name")
        else
            echo "FAIL: $name"
            FAIL=$((FAIL + 1))
            FAILURES+=("$name")
        fi
    fi
}

echo "========================================"
echo "Wild Pairs -- Quality Gate (Full)"
echo "$(date)"
echo "========================================"

# 1. Swift Package build
run_check "Swift Package Build" \
    "swift build --package-path \"$PROJECT_ROOT\" 2>&1"

# 2. All unit tests
run_check "All Unit Tests" \
    "bash \"$SCRIPT_DIR/run_unit_tests.sh\""

# 3. Simulation tests
run_check "AI Simulation Tests" \
    "bash \"$SCRIPT_DIR/run_simulations.sh\""

# 4. Network usage scan
run_check "No Network Usage" \
    "bash \"$SCRIPT_DIR/check_no_network_usage.sh\""

# 5. Permission check
run_check "Minimal Permissions (Info.plist)" \
    "bash \"$SCRIPT_DIR/check_permissions_minimal.sh\""

# 6. Capability check
run_check "Minimal Capabilities (Entitlements)" \
    "bash \"$SCRIPT_DIR/check_project_capabilities.sh\""

# 7. Privacy manifest check
run_check "Privacy Manifest" \
    "bash \"$SCRIPT_DIR/check_privacy_manifest.sh\""

# 8. UI tests (available after Phase 5 -- xcodeproj must exist)
echo ""
echo "--- UI Tests ---"
XCODEPROJ=$(find "$PROJECT_ROOT" -maxdepth 2 -name "*.xcodeproj" 2>/dev/null | head -1)
if [ -z "$XCODEPROJ" ]; then
    echo "SKIP: UI Tests -- no .xcodeproj found (available after Phase 5)"
    SKIPS+=("UI Tests")
else
    if bash "$SCRIPT_DIR/run_ui_tests.sh"; then
        echo "PASS: UI Tests"
        PASS=$((PASS + 1))
    else
        echo "FAIL: UI Tests"
        FAIL=$((FAIL + 1))
        FAILURES+=("UI Tests")
    fi
fi

# 9. Xcode app build (available after Phase 5)
echo ""
echo "--- Xcode App Build ---"
if [ -z "$XCODEPROJ" ]; then
    echo "SKIP: Xcode App Build -- no .xcodeproj found (available after Phase 5)"
    SKIPS+=("Xcode App Build")
else
    SCHEME="WildPairsApp"
    echo "Building scheme '$SCHEME' from: $XCODEPROJ"
    if xcodebuild \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -destination "platform=iOS Simulator,name=iPhone 15" \
        -configuration Debug \
        build 2>&1 | tail -20; then
        echo "PASS: Xcode App Build"
        PASS=$((PASS + 1))
    else
        echo "FAIL: Xcode App Build"
        FAIL=$((FAIL + 1))
        FAILURES+=("Xcode App Build")
    fi
fi

echo ""
echo "========================================"
echo "Quality Gate (Full) Summary"
echo "========================================"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "Skipped: ${#SKIPS[@]}"

if [ ${#SKIPS[@]} -gt 0 ]; then
    echo ""
    echo "Skipped checks (not applicable at current phase):"
    for s in "${SKIPS[@]}"; do
        echo "  - $s"
    done
fi

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