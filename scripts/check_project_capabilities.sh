#!/usr/bin/env bash
# Run on Mac with Xcode installed.
# Usage: bash scripts/check_project_capabilities.sh
# Check .entitlements files for unnecessary capabilities.
# Wild Pairs requires NO special capabilities beyond basic code-signing entitlements.
# Basic code-signing entitlements (application-identifier, team-identifier, get-task-allow)
# are expected and explicitly excluded from the fail conditions.
# Exit 0 = PASS (no unnecessary capabilities). Exit 1 = FAIL (unnecessary capabilities found).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- Project Capabilities Check"
echo "$(date)"
echo "========================================"

# Find .entitlements files
ENTITLEMENTS_FILES=$(find "$PROJECT_ROOT" \
    -name "*.entitlements" \
    -not -path "*/DerivedData/*" \
    -not -path "*/.build/*" \
    2>/dev/null || true)

if [ -z "$ENTITLEMENTS_FILES" ]; then
    echo ""
    echo "PASS: No .entitlements files found."
    echo "This is expected for a clean project without special capabilities."
    echo "(Basic code-signing is handled without a custom entitlements file in many configurations.)"
    echo ""
    echo "RESULT: PASS"
    exit 0
fi

echo "Found .entitlements files:"
echo "$ENTITLEMENTS_FILES" | sed 's/^/  /'
echo ""

# Unnecessary capabilities that must NOT be present
# Note: application-identifier, team-identifier, get-task-allow are EXPECTED and excluded here
PROHIBITED_CAPABILITIES=(
    "aps-environment"
    "com.apple.developer.push-notification"
    "com.apple.developer.icloud-container-identifiers"
    "com.apple.developer.ubiquity-container-identifiers"
    "com.apple.developer.ubiquity-kvstore-identifier"
    "com.apple.developer.cloudkit"
    "com.apple.developer.icloud-services"
    "com.apple.security.application-groups"
    "com.apple.developer.associated-domains"
    "com.apple.developer.healthkit"
    "com.apple.developer.homekit"
    "com.apple.developer.game-center"
    "com.apple.developer.pass-type-identifiers"
    "com.apple.developer.networking.networkextension"
    "com.apple.developer.bluetooth"
    "com.apple.developer.networking.wifi-info"
    "com.apple.developer.siri"
    "com.apple.developer.usernotifications.time-sensitive"
    "com.apple.developer.usernotifications.critical-alerts"
    "com.apple.developer.nfc.readersession.formats"
    "com.apple.developer.default-data-protection"
    "push-notifications"
)

FINDINGS=0
FOUND_CAPS=()

for ent_file in $ENTITLEMENTS_FILES; do
    echo "Checking: $ent_file"
    for cap in "${PROHIBITED_CAPABILITIES[@]}"; do
        if grep -q "$cap" "$ent_file" 2>/dev/null; then
            echo "  FAIL: Found unnecessary capability: $cap"
            FINDINGS=$((FINDINGS + 1))
            FOUND_CAPS+=("$cap (in: $(basename "$ent_file"))")
        fi
    done
    # Report what IS present (for transparency), excluding the expected basic entitlements
    PRESENT=$(grep -E "<key>" "$ent_file" 2>/dev/null \
        | grep -v "application-identifier\|team-identifier\|get-task-allow\|keychain-access-groups" \
        | grep -oE ">.*<" | tr -d '><' | head -20 || true)
    if [ -n "$PRESENT" ]; then
        echo "  Non-standard entitlement keys present (review each):"
        echo "$PRESENT" | sed 's/^/    /'
    fi
done

echo ""
echo "========================================"
echo "Capabilities Check Summary"
echo "========================================"
echo "Unnecessary capabilities found: $FINDINGS"

if [ $FINDINGS -gt 0 ]; then
    echo ""
    echo "FAILED capabilities:"
    for cap in "${FOUND_CAPS[@]}"; do
        echo "  - $cap"
    done
    echo ""
    echo "Remove these capabilities from the .entitlements file and from the"
    echo "Xcode project Signing & Capabilities tab before shipping."
    echo "Each capability requires a provisioning profile update and may"
    echo "increase enterprise review friction."
    echo ""
    echo "RESULT: FAIL"
    exit 1
else
    echo ""
    echo "RESULT: PASS -- No unnecessary capabilities found."
    exit 0
fi