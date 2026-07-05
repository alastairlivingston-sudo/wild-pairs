---
name: simulator-verify
description: Visually verify Wild Pairs UI changes on the simulator, one form factor at a time with a user checkpoint between each. Invoke after any change that alters what the app renders — layout, cards, theming, animation, text — or when the user asks "does it look right", "verify on iPad", or "show me screenshots".
---

# Skill: Simulator Verify

## Purpose
Prove a UI change works by capturing real simulator screenshots per form factor and judging them against the spec, stopping for the user's confirmation before moving to the next form factor. UI work is never "done" from code reading alone.

## When to Invoke
- After any edit that changes what the app renders (views, theming, card art, animation, copy)
- When the user says "verify", "does it look right", "check on iPad", or "screenshots"
- As the final step of /swiftui-quality-review, /ux-review, or /playtest-fix when the change is visible
- Before any phase gate that includes UI work

## Inputs Required
- Which screens/flows the change affects (infer from the diff if not stated)
- Form factors in scope — default order: iPhone first, then iPad, then other size classes
- The spec to judge against (docs/ux-spec.md, docs/design-system.md, or the phase design plan)

## Steps

1. **Build first.** `xcodebuild build -scheme WildPairs -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'`. A broken build fails the skill immediately.

2. **Run the unattended capture (preferred).** The `WildPairsScreenshotCapture` XCUITest class (end of WildPairsUITests.swift) walks onboarding → home → new-game → table → pause:
   ```
   env TEST_RUNNER_WP_SCREENSHOT_DIR=<dir> xcodebuild test -scheme WildPairs \
     -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' \
     -only-testing:WildPairsUITests/WildPairsScreenshotCapture
   ```
   The `env` prefix must set a real environment variable, not a build-setting argument, or the class self-skips (zero screenshots = suspect this first). Use `testCaptureTwoRowHand` when the change affects large hands. Write PNGs to a `docs/phase-*/screenshots/` directory when they will be committed as verification evidence, otherwise the session scratchpad.

3. **Fall back to interactive driving only if the capture class can't reach the state.** `xcrun simctl install/launch <udid> --uitest-reset-state`, drive with computer-use (Simulator is full tier; if its window hides behind other apps, re-`open_application` and use the Window menu to pick the device), then `xcrun simctl io <udid> screenshot`. Nav path: skip onboarding → `home-new-game` → pick card set → `newgame-start`.

4. **Read every screenshot.** Judge against the spec: layout (no clipping, no dead zones), card anatomy discipline (no caption text on faces — see memory `wild-pairs-corrections-log`), Dynamic Type/legibility, and whatever the change specifically claims. For a deep judgement pass, invoke /design-critique on the captured set.

5. **If a defect is found, fix the source and return to step 1.** Check memory `swiftui-ios-traps` before debugging layout (clipShape bounds, offset-vs-layout, transform bleed are all previously paid-for lessons).

6. **Report with the screenshots and STOP for user confirmation.** Present what was verified and any judgement calls. Do not proceed to the next form factor until the user confirms — this checkpoint is the user's explicit standing preference.

7. **Repeat steps 1–6 for the next form factor** (`name=iPad Pro 13-inch` for iPad) only after confirmation.

## Outputs
- Screenshot set per form factor, at the states the change affects
- A short verdict per form factor: what was checked, what passed, any deviations from spec
- An explicit stop for confirmation between form factors

## Acceptance Criteria
- Every affected screen state photographed on every in-scope form factor
- Any spec deviation either fixed and re-verified, or surfaced as an explicit finding
- The user confirmed each form factor before the next began

## Common Pitfalls
- Declaring success because the code compiles — the whole point is the pixels
- Batch-verifying iPhone and iPad and presenting both at once, skipping the checkpoint
- Zero screenshots produced and not noticing (env-var trap in step 2)
- "Fixing" quality_light.sh network-scan failures on `.tracking(1)` or the stats copy — those are documented false positives; add a disposition row to docs/permission-audit.md §8 instead
- Verifying only the default hand size when the change affects fanning or the two-row hand
