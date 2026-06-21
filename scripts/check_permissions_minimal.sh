#!/usr/bin/env bash
# Run on Mac with Xcode installed.
# Usage: bash scripts/check_permissions_minimal.sh
# Check Info.plist for protected-resource usage description keys.
# Wild Pairs requires NO protected resources (no camera, mic, location, etc.).
# Exit 0 = PASS (no prohibited keys). Exit 1 = FAIL (prohibited keys found).
# Prints SKIP if no Info.plist found (pre-Phase 5).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- Minimal Permissions Check"
echo "$(date)"
echo "========================================"

# Find Info.plist files
PLIST_FILES=$(find "$PROJECT_ROOT" \
    -name "Info.plist" \
    -not -path "*/DerivedData/*" \
    -not -path "*/.build/*" \
    2>/dev/null || true)

if [ -z "$PLIST_FILES" ]; then
    echo ""
    echo "SKIP: No Info.plist found."
    echo "Info.plist is created as part of the Xcode project (Phase 5+)."
    echo "Re-run this check after creating the Xcode project."
    echo ""
    echo "RESULT: SKIP"
    exit 0
fi

echo "Found Info.plist files:"
echo "$PLIST_FILES" | sed 's/^/  /'
echo ""

# Protected-resource usage description keys that must NOT be present
PROHIBITED_KEYS=(
    "NSCameraUsageDescription"
    "NSMicrophoneUsageDescription"
    "NSPhotoLibraryUsageDescription"
    "NSPhotoLibraryAddUsageDescription"
    "NSLocationWhenInUseUsageDescription"
    "NSLocationAlwaysUsageDescription"
    "NSLocationAlwaysAndWhenInUseUsageDescription"
    "NSBluetoothAlwaysUsageDescription"
    "NSBluetoothPeripheralUsageDescription"
    "NSContactsUsageDescription"
    "NSCalendarsUsageDescription"
    "NSRemindersUsageDescription"
    "NSLocalNetworkUsageDescription"
    "NSFaceIDUsageDescription"
    "NSSpeechRecognitionUsageDescription"
    "NSHealthShareUsageDescription"
    "NSHealthUpdateUsageDescription"
    "NSMotionUsageDescription"
    "NSUserTrackingUsageDescription"
    "NSAppleMusicUsageDescription"
    "NSSiriUsageDescription"
)

FINDINGS=0
FOUND_KEYS=()

for plist in $PLIST_FILES; do
    echo "Checking: $plist"
    for key in "${PROHIBITED_KEYS[@]}"; do
        if grep -q "$key" "$plist" 2>/dev/null; then
            echo "  FAIL: Found prohibited key: $key"
            FINDINGS=$((FINDINGS + 1))
            FOUND_KEYS+=("$key (in: $(basename "$plist"))")
        fi
    done
done

echo ""
echo "========================================"
echo "Permissions Check Summary"
echo "========================================"
echo "Prohibited keys found: $FINDINGS"

if [ $FINDINGS -gt 0 ]; then
    echo ""
    echo "FAILED keys:"
    for key in "${FOUND_KEYS[@]}"; do
        echo "  - $key"
    done
    echo ""
    echo "Wild Pairs must NOT request any protected resources."
    echo "Remove these keys from Info.plist and the corresponding capability"
    echo "from the Xcode project before shipping."
    echo ""
    echo "RESULT: FAIL"
    exit 1
else
    echo ""
    echo "RESULT: PASS -- No prohibited permission keys found."
    exit 0
fi