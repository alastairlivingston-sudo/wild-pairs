#!/usr/bin/env bash
# Run on Mac with Xcode installed.
# Usage: bash scripts/check_no_network_usage.sh
# Scans WildPairsCore/ and WildPairsApp/ source files for network API usage.
# All findings must be reviewed -- false positives are possible and must be documented.
# Exit 0 = PASS (no findings). Exit 1 = FAIL (findings require review).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "========================================"
echo "Wild Pairs -- No Network Usage Scan"
echo "$(date)"
echo "========================================"

FINDINGS=0
FINDING_DETAILS=()

# Source directories to scan
SCAN_DIRS=()
for dir in "WildPairsCore" "WildPairsApp" "Sources" "App"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        SCAN_DIRS+=("$PROJECT_ROOT/$dir")
    fi
done

if [ ${#SCAN_DIRS[@]} -eq 0 ]; then
    echo "INFO: No source directories found (WildPairsCore/, WildPairsApp/, Sources/, App/)."
    echo "Scan will run on project root Swift files only."
    SCAN_DIRS=("$PROJECT_ROOT")
fi

echo "Scanning: ${SCAN_DIRS[*]}"
echo ""

scan_pattern() {
    local pattern="$1"
    local description="$2"
    local results
    results=$(grep -rn --include="*.swift" -i "$pattern" "${SCAN_DIRS[@]}" 2>/dev/null || true)
    if [ -n "$results" ]; then
        echo "FINDING [$description]:"
        echo "$results" | sed 's/^/  /'
        echo ""
        FINDINGS=$((FINDINGS + $(echo "$results" | wc -l | tr -d ' ')))
        FINDING_DETAILS+=("$description")
    fi
}

# URLSession and URL requests
scan_pattern "URLSession"               "URLSession usage"
scan_pattern "URLRequest"               "URLRequest usage"
scan_pattern "\.dataTask"              "dataTask (URLSession)"
scan_pattern "\.downloadTask"          "downloadTask (URLSession)"
scan_pattern "\.uploadTask"            "uploadTask (URLSession)"

# Network framework
scan_pattern "Network\.framework"      "Network.framework import"
scan_pattern "NWConnection"            "NWConnection (Network.framework)"
scan_pattern "NWListener"              "NWListener (Network.framework)"
scan_pattern "NWPathMonitor"           "NWPathMonitor (Network.framework)"

# Web views
scan_pattern "WKWebView"               "WKWebView usage"
scan_pattern "SFSafariViewController"  "SFSafariViewController usage"

# Hardcoded URLs
scan_pattern "http://"                 "Hardcoded http:// URL"
scan_pattern "https://"                "Hardcoded https:// URL"

# Analytics and telemetry
scan_pattern "analytics"               "analytics keyword"
scan_pattern "telemetry"               "telemetry keyword"
scan_pattern "tracking"                "tracking keyword"
scan_pattern "crashlytics"             "Crashlytics reference"
scan_pattern "firebase"                "Firebase reference"
scan_pattern "amplitude"               "Amplitude reference"
scan_pattern "segment\b"              "Segment analytics reference"
scan_pattern "mixpanel"               "Mixpanel reference"
scan_pattern "sentry\b"               "Sentry reference"

# Cloud services
scan_pattern "CloudKit"                "CloudKit usage"
scan_pattern "CKContainer"             "CKContainer (CloudKit)"
scan_pattern "CKRecord"                "CKRecord (CloudKit)"

# Game services
scan_pattern "GameKit"                 "GameKit usage"
scan_pattern "GKLocalPlayer"           "GKLocalPlayer (GameKit)"
scan_pattern "GKLeaderboard"           "GKLeaderboard (GameKit)"

# StoreKit (flag for review -- may be intentional)
scan_pattern "StoreKit"                "StoreKit usage (REVIEW: requires Product Director approval)"

# URL opening (may be intentional -- flag for review)
scan_pattern "UIApplication.*open"     "UIApplication.open (REVIEW: opening external URLs)"
scan_pattern "openURL"                 "openURL call (REVIEW: opening external URLs)"

echo "========================================"
echo "Network Scan Summary"
echo "========================================"
echo "Total findings: $FINDINGS"

if [ $FINDINGS -gt 0 ]; then
    echo ""
    echo "Pattern categories with findings:"
    for detail in "${FINDING_DETAILS[@]}"; do
        echo "  - $detail"
    done
    echo ""
    echo "ACTION REQUIRED: Review each finding above."
    echo "If a finding is a false positive (e.g., in a comment, test-only, or justified usage),"
    echo "document the disposition in docs/permission-audit.md."
    echo "Genuine network API usage must be removed before shipping."
    echo ""
    echo "RESULT: FAIL (findings require review)"
    exit 1
else
    echo ""
    echo "RESULT: PASS -- No network API usage found."
    exit 0
fi