# Skill: Enterprise Permission Audit

## Purpose
Verify the Wild Pairs project has no unnecessary permissions, entitlements, or network usage. Produces a structured PASS/FAIL report for each check. Run at every phase gate and whenever a new capability or permission is proposed. Ensures the app remains frictionless to build and distribute in enterprise environments.

## When to Invoke
- At every phase gate
- When a new Xcode capability is proposed or added
- When a new Info.plist key is added
- When Enterprise Build Lead is asked to audit the project
- When the user says "permission audit", "entitlements check", or "capability audit"

## Inputs Required
- macOS with Xcode installed (scripts require macOS and the swift CLI)
- Project root directory (all scripts run from project root)
- docs/permission-audit.md (to record results; create if missing)

## Steps

1. **Run check_permissions_minimal.sh.** Execute `bash scripts/check_permissions_minimal.sh` from the project root. Capture full output.
   - Exit 0: PASS — record "No protected-resource permission keys found in Info.plist"
   - Exit 1: FAIL — record each key found
   - SKIP output: record "Info.plist not yet present (pre-Phase 5) — recheck after Xcode project created"

2. **Run check_project_capabilities.sh.** Execute `bash scripts/check_project_capabilities.sh` from the project root. Capture full output.
   - Exit 0: PASS — record "No unnecessary entitlements found"
   - Exit 1: FAIL — record each capability found
   Note: basic code-signing entitlements (application-identifier, team-identifier, get-task-allow) are expected and acceptable — these should not appear in the FAIL output.

3. **Run check_no_network_usage.sh.** Execute `bash scripts/check_no_network_usage.sh` from the project root. Capture full output.
   - Exit 0: PASS — record "No network API usage found in source files"
   - Exit 1: FAIL — record each finding with file path and pattern matched
   For each FAIL finding: determine if it is a false positive (e.g., a comment, a string constant with "analytics" in a non-SDK context) and document the disposition. A genuine finding is a blocking issue.

4. **Run check_privacy_manifest.sh.** Execute `bash scripts/check_privacy_manifest.sh` from the project root. Capture full output.
   - PASS: record result
   - INFO: record the informational message
   - FAIL: record the specific failure (manifest missing or invalid)
   A FAIL here is a blocking issue for App Store submission phases.

5. **Manual check: Package.swift dependencies.** Read the WildPairsCore/Package.swift file. Verify the `dependencies` array is empty (or contains only Apple-provided packages with no third-party URLs). Record PASS if no third-party dependencies. Record FAIL with package name if any third-party dependency is found.

6. **Manual check: import statements.** Search source files for any import statement that is not one of the approved Apple framework imports. Approved imports include: Foundation, SwiftUI, UIKit, XCTest, Combine, GameplayKit (if used for RNG only — flag for review), CoreData (should not be present — flag). Any non-Apple import is a FAIL.
   Run: search for `^import ` in all .swift files in WildPairsCore/ and WildPairsApp/. List unique imports. Flag any that are not Apple system frameworks.

7. **Manual check: App Transport Security.** If Info.plist exists: check for `NSAppTransportSecurity` key. If present:
   - `NSAllowsArbitraryLoads: true` → FAIL (blocking)
   - `NSExceptionDomains` with any entry → FAIL (blocking)
   - Key present but with default (restrictive) settings → PASS with note
   If Info.plist does not exist yet: record SKIP with note.

8. **Produce the audit report.** Structured format:
   - Audit date and project phase
   - Per-check table: check name, script or method, result (PASS/FAIL/SKIP/INFO), details
   - Blocking issues: any FAIL that prevents shipping
   - False positive log: any FAIL finding determined to be a false positive with justification
   - Overall verdict: PASS (all checks pass or are documented false positives) / FAIL (any genuine FAIL) / PARTIAL (some checks skipped due to phase)

9. **Update docs/permission-audit.md.** Append this audit run (date, phase, all results, verdict). Do not overwrite prior audit records — maintain a complete history.

## Outputs
- Console output of all four script runs
- Manual check results for Package.swift dependencies, import statements, and ATS
- Structured audit report (per-check table, blocking issues, false positive log, verdict)
- Updated docs/permission-audit.md

## Acceptance Criteria
- check_permissions_minimal.sh exits 0
- check_project_capabilities.sh exits 0
- check_no_network_usage.sh exits 0 (or all findings documented as false positives)
- check_privacy_manifest.sh exits 0 (PASS or acceptable INFO)
- Package.swift has zero third-party dependencies
- All import statements are Apple system frameworks
- No NSAllowsArbitraryLoads or NSExceptionDomains in Info.plist
- docs/permission-audit.md updated with this run

## Common Pitfalls
- Running scripts on Windows instead of macOS — all scripts require a macOS environment with swift CLI
- Treating a SKIP result as a PASS — SKIP means "cannot check yet"; re-check when the project phase allows
- Accepting false positives without documenting them — every FAIL finding must have a disposition in the false positive log, even if the disposition is "confirmed false positive: string constant in comment"
- Forgetting the manual Package.swift check — the scripts only check source code, not the dependency manifest
- Not updating docs/permission-audit.md — the audit history is required for the release manager's phase gate review
