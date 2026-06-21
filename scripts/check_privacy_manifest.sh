#!/usr/bin/env bash
# Run on Mac with Xcode installed.
# Usage: bash scripts/check_privacy_manifest.sh
# Check for PrivacyInfo.xcprivacy if required-reason APIs are used.
# Wild Pairs must have NSPrivacyTracking: false and NSPrivacyTrackingDomains: [].
# Exit 0 = PASS (manifest valid or not required). Exit 1 = FAIL (manifest required but missing/invalid).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- Privacy Manifest Check"
echo "$(date)"
echo "========================================"

# Source directories to scan for required-reason API usage
SCAN_DIRS=()
for dir in "WildPairsCore" "WildPairsApp" "Sources" "App"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        SCAN_DIRS+=("$PROJECT_ROOT/$dir")
    fi
done
# Also scan Swift files in root if no subdirs
if [ ${#SCAN_DIRS[@]} -eq 0 ]; then
    SCAN_DIRS=("$PROJECT_ROOT")
fi

echo "Scanning for required-reason API usage in: ${SCAN_DIRS[*]}"
echo ""

# Check for required-reason APIs that mandate a PrivacyInfo.xcprivacy
# Ref: https://developer.apple.com/documentation/bundleresources/privacy_manifest_files/describing_use_of_required_reason_api
REQUIRED_REASON_APIS_FOUND=()

check_api() {
    local pattern="$1"
    local api_name="$2"
    local result
    result=$(grep -rn --include="*.swift" "$pattern" "${SCAN_DIRS[@]}" 2>/dev/null || true)
    if [ -n "$result" ]; then
        REQUIRED_REASON_APIS_FOUND+=("$api_name")
        echo "  Found required-reason API: $api_name"
        echo "$result" | head -5 | sed 's/^/    /'
    fi
}

echo "Checking for required-reason APIs:"
check_api "UserDefaults"                    "UserDefaults"
check_api "FileManager"                     "FileManager"
check_api "NSFileManager"                   "NSFileManager"
check_api "NSUserDefaults"                  "NSUserDefaults"
check_api "\.systemUptime"                  "ProcessInfo.systemUptime"
check_api "mach_absolute_time"              "mach_absolute_time"
check_api "NSTimeZone"                      "NSTimeZone"
check_api "\.timeZone"                      "TimeZone"
check_api "corelocation\|CLLocation"        "CoreLocation (if used)"
check_api "AVCaptureDevice\|AVFoundation"   "AVFoundation (if used)"

echo ""

# Find PrivacyInfo.xcprivacy
PRIVACY_MANIFEST=$(find "$PROJECT_ROOT" \
    -name "PrivacyInfo.xcprivacy" \
    -not -path "*/DerivedData/*" \
    -not -path "*/.build/*" \
    2>/dev/null | head -1 || true)

# Determine if manifest is required
if [ ${#REQUIRED_REASON_APIS_FOUND[@]} -gt 0 ]; then
    echo "Required-reason APIs found (${#REQUIRED_REASON_APIS_FOUND[@]} categories)."
    echo "PrivacyInfo.xcprivacy is REQUIRED for App Store submission."
    echo ""

    if [ -z "$PRIVACY_MANIFEST" ]; then
        echo "FAIL: PrivacyInfo.xcprivacy not found but is required."
        echo ""
        echo "Create PrivacyInfo.xcprivacy in the WildPairsApp target with at minimum:"
        echo "  NSPrivacyTracking: false"
        echo "  NSPrivacyTrackingDomains: []"
        echo "  NSPrivacyCollectedDataTypes: []"
        echo "  NSPrivacyAccessedAPITypes: [list each required-reason API with category code]"
        echo ""
        echo "RESULT: FAIL"
        exit 1
    fi

    echo "Found: $PRIVACY_MANIFEST"
    echo ""
    echo "Validating manifest contents..."

    # Check NSPrivacyTracking is false
    if grep -q "NSPrivacyTracking" "$PRIVACY_MANIFEST"; then
        if grep -A1 "NSPrivacyTracking" "$PRIVACY_MANIFEST" | grep -q "<false/>"; then
            echo "  PASS: NSPrivacyTracking is false"
        else
            echo "  FAIL: NSPrivacyTracking is not set to false"
            echo "RESULT: FAIL"
            exit 1
        fi
    else
        echo "  FAIL: NSPrivacyTracking key not found in manifest"
        echo "RESULT: FAIL"
        exit 1
    fi

    # Check NSPrivacyTrackingDomains is empty
    if grep -q "NSPrivacyTrackingDomains" "$PRIVACY_MANIFEST"; then
        # Check that array after NSPrivacyTrackingDomains key is empty
        if grep -A2 "NSPrivacyTrackingDomains" "$PRIVACY_MANIFEST" | grep -q "<array/>"; then
            echo "  PASS: NSPrivacyTrackingDomains is empty"
        else
            # Check for empty array with tags on separate lines
            DOMAIN_CONTENT=$(awk '/NSPrivacyTrackingDomains/{found=1} found && /<\/array>/{print; found=0} found{print}' "$PRIVACY_MANIFEST" 2>/dev/null || true)
            if echo "$DOMAIN_CONTENT" | grep -qE "<string>"; then
                echo "  FAIL: NSPrivacyTrackingDomains contains entries (must be empty)"
                echo "RESULT: FAIL"
                exit 1
            else
                echo "  PASS: NSPrivacyTrackingDomains appears empty"
            fi
        fi
    else
        echo "  FAIL: NSPrivacyTrackingDomains key not found in manifest"
        echo "RESULT: FAIL"
        exit 1
    fi

    echo ""
    echo "RESULT: PASS -- PrivacyInfo.xcprivacy is present and valid."
    exit 0

else
    echo "No required-reason APIs found."
    echo ""

    if [ -z "$PRIVACY_MANIFEST" ]; then
        echo "INFO: PrivacyInfo.xcprivacy not present."
        echo "      No required-reason APIs detected -- manifest may not be required."
        echo "      Add PrivacyInfo.xcprivacy before App Store submission to be safe."
        echo "      Minimum content: NSPrivacyTracking false, NSPrivacyTrackingDomains []"
    else
        echo "Found: $PRIVACY_MANIFEST"
        echo "INFO: Manifest present even though no required-reason APIs detected."
        echo "      Verifying minimum required fields..."

        MANIFEST_FAIL=0
        if grep -q "NSPrivacyTracking" "$PRIVACY_MANIFEST"; then
            if grep -A1 "NSPrivacyTracking" "$PRIVACY_MANIFEST" | grep -q "<false/>"; then
                echo "  PASS: NSPrivacyTracking is false"
            else
                echo "  FAIL: NSPrivacyTracking must be false"
                MANIFEST_FAIL=1
            fi
        fi

        if [ $MANIFEST_FAIL -ne 0 ]; then
            echo ""
            echo "RESULT: FAIL"
            exit 1
        fi
    fi

    echo ""
    echo "RESULT: PASS"
    exit 0
fi