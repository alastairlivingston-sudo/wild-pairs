# Phase 19 Wave A + backgrounds — Mac verification report

Date: 2026-07-19 · Xcode 26.5 (17F42) · Swift 6.3.2 · macOS arm64

**Verdict: two real defects found and fixed; gates green except one pre-existing flaky
test and one long-standing documented scanner false positive. No blocker remains.**

## Integration

- Branch worked on: `claude/phase-19-ux-verification-0cefcd`
- Verification commit: `0a95b13`
- Product commit under test: `6c1e607`; provenance `9ec0631`
- Pushed remote branch: **no** — not pushed, no PR opened (see "Branch destination")
- Patch applied cleanly upstream; no semantic-merge deviations found on inspection

### Branch destination — needs a decision

`claude/phase-19-wave-a-backgrounds-nn0c5q` is checked out in the main worktree at
`/Users/alastair/dev/wild-pairs`, so it could not be checked out here. At session start it
was at the **identical commit** as this worktree's branch (`90a1ff8`, empty diff), so the
code verified is exactly the intended code. The fix commit currently sits on
`claude/phase-19-ux-verification-0cefcd` and is one fast-forward from the wave-a branch.
Nothing was pushed and no branch pointer was moved.

## Environment deviations (affect what could be proven)

| Intended | Actual | Consequence |
|---|---|---|
| Clean **iOS 17** build/run | Only **iOS 26.5** runtime installed | `IPHONEOS_DEPLOYMENT_TARGET` = 17.0 confirmed statically in `project.yml`; **no iOS 17 runtime execution was performed** |
| iPhone 15 / iPad Air (5th gen) per CLAUDE.md | Not installed | Used iPhone 17, iPhone 17 Pro, iPad Pro 11" (M5), iPad Pro 13" (M5), iPad Air 13" (M4) |
| 375 pt iPhone portrait | No 375 pt device available | **Not captured.** Smallest available is ~393 pt |

`xcodegen` was required — the repo ships `project.yml` with **no** `.xcodeproj`, and the
generated project is gitignored, so regeneration causes no repo churn. `GameEdgeHUD.swift`
confirmed in the `WildPairs` target after generation.

## Defects found and fixed

### 1. Ambient arc deadlocked XCUITest (deterministic, Phase 19-caused) — FIXED

`TimelineView(.animation(...))` drives its timeline from the display link, so the app never
reported quiescence. Every UI test that reached the game table was killed mid-run.

- Phase 19 as delivered: **10 of 24 UI tests failed**, all "Test crashed with signal kill"
- Pre-Phase-19 baseline `55e0d06`, same machine/simulator/Xcode: **24/24 passed**
- Confirmed by experiment: forcing the static path made the failing test pass

Fix: `.periodic(from:by:)` instead of `.animation(minimumInterval:)`. Same 14 s orbit, same
15 fps cap, same static fallback, no test-only branch — shipping and test paths stay identical.

Measured after the fix, mid-table band, consecutive frames:
- motion enabled: ~2,100–3,400 px change per frame → **still animating**
- Reduce Motion: **0 px** change across consecutive frames → **static trace, frozen**

### 2. Round clock invisible to XCUITest, and its label unstable — FIXED

`.accessibilityElement(children: .ignore)` collapsed the clock into a group, so
`app.staticTexts` matched nothing. This did not fail loudly — it made
`testResumeAfterBackgrounding` capture `nil` and **silently skip** its round-number
assertion. Restoring the static-text trait re-enabled that assertion, which then exposed
that the label embedded a live countdown and differed across a one-second tick
(`"Round 1, time remaining 2:58"` vs `"...2:59"`).

Fix: stable identity in `accessibilityLabel` ("Round 1"), ticking quantity in
`accessibilityValue` ("time remaining 2:58"). This is also the more correct VoiceOver
reading. No test was modified.

## Automated verification

| Check | Command / environment | Result |
|---|---|---|
| Project generation + target membership | `xcodegen generate` | **PASS** — `GameEdgeHUD.swift` in `WildPairs` target |
| iOS 17 build | n/a — no iOS 17 runtime | **NOT RUN**; target 17.0 confirmed statically only |
| Clean build, iPhone | `xcodebuild clean build` · iPhone 17 | **PASS** — BUILD SUCCEEDED, **0 warnings** |
| Clean build, iPad | `xcodebuild clean build` · iPad Pro 11" (M5) | **PASS** — BUILD SUCCEEDED, **0 warnings** |
| SwiftPM tests (macOS) | `swift test --package-path .` | **PASS** — 303 tests / 35 suites |
| Core suite against **iOS SDK** | `xcodebuild test -scheme WildPairsTests` · iPad Air 13" | **PASS** — 303 tests / 35 suites |
| `WildPairsUITests` · iPhone 17 | `xcodebuild test -scheme WildPairs` | **PASS** — 24/24 (twice); one later run hit the pre-existing flake below |
| `WildPairsUITests` · iPad Pro 11" (M5) | same | **PASS** — 24/24 |
| `WildPairsUITests` · iPad Air 13" (M4) | same | **1 pre-existing flake** (see below) |
| `check_permissions_minimal.sh` | | **PASS** — 0 prohibited keys |
| `check_project_capabilities.sh` | | **PASS** — no entitlements files |
| `check_privacy_manifest.sh` | | **PASS** — `NSPrivacyTracking` false, domains empty |
| `check_no_network_usage.sh` | | **FAIL by design** — documented false positive, see below |
| `quality_light.sh` | | FAIL solely on the network scan above |
| `quality_full.sh` | | 7 pass / 2 fail — the network scan, and the UI-test step (flake) |

### Network scan — documented false positive, not a regression

The scanner FAILs whenever any finding exists, pending a written disposition; this has been
its behaviour since Phase 5. Findings are 23 vs **22 at baseline** — a net **+1**:
`GameEdgeHUD.swift` adds three `.tracking(...)` letter-spacing calls while `GameTableView.swift`
drops two with the removed `MoveTimerBar`. The one "telemetry" hit is a comment that itself
reads *"no telemetry, no network"*. No new pattern category; no network API. Disposition row
added to `docs/permission-audit.md` per the established process.

### Remaining UI-test failure is pre-existing, not Phase 19

`testMultiRoundSessionContinuesPastFirstRound` (line 465, "Round 2 should be responsive to
play, not frozen") polls up to 20 s for the human's turn — inherently AI-timing dependent.

Measured **on the pre-Phase-19 baseline**, test run in isolation:
- baseline iPhone 17, 3 runs: **FAIL, PASS, PASS**
- baseline iPad Air 13" (M4), 3 runs: **PASS, PASS, FAIL**

≈1-in-3 failure rate on unmodified baseline code, both devices. Flagged for the
`flake-hardener` agent; deliberately **not** modified here.

## Visual verification

Screenshots under `/tmp/shots/` (simulator captures, not committed).

| State | Status |
|---|---|
| iPhone 393 pt portrait, standard table | **captured** — `arc1.png`, `bg-aurora.png`, `bg-contours.png` |
| iPhone 375 pt portrait | **not captured** — no such simulator available |
| iPad 13" (M5) portrait + decision overlay | **captured** — `ipad13-portrait.png` |
| iPad 11" / 13" **landscape**, rotation pass | **not captured** — UI suite passed on both iPads, but no landscape stills taken |
| Felt / Aurora / Contours | **all three captured**, visually distinct |
| Sky / Grass / Lava active-element field | **captured** (Sky, Grass, Lava-tinted iPad) |
| Sun active element | **not captured in isolation** |
| Clockwise + counter-clockwise | **both captured**; Reverse flip not captured live |
| Move timer: absent / normal / urgent (≤3 s) | **all three captured** |
| Colour-blind mode + pattern fills + large cards | **captured** via `legacy-launch.png` |
| AX5 Dynamic Type | **captured** — `ax5.png` |
| AX3 boundary, default type | exercised via existing `testDynamicTypeAX3LayoutSurvives` (passing) |
| Face-to-face seat variants, Solo states, round-end/game-over overlays | **not captured individually** |

### Move-timer slot never shifts the table — measured

30 consecutive frames over 30 s. The HUD's bottom edge was at **row 339 in all 30 frames**
(one distinct value), while the move-slot luminance swung 8.9 → 29.9 as the timer appeared
and disappeared. The timer changes only the slot's contents, never HUD geometry, so the
table centre, hand, and pause cannot move. Urgency (amber, larger digit) renders inside the
same fixed frame — no modal, no geometry change. The reserved-but-empty slot is directly
visible beside the pause button in `ipad13-portrait.png`.

### Exactly one semantic instance — measured at runtime

Accessibility-tree element counts, via a temporary harness (since removed):

| Identifier | Standard table | Face-to-face (two humans) |
|---|---|---|
| `game-turn-rail` | 1 | **1** |
| `game-round-timer` | 1 | **1** |
| `game-move-timer` | 1 | **1** |
| `game-pause-button` | 1 | **1** |
| `handoff-confirm` | 0 | **0** (absent, as required) |

Face-to-face renders **two** visual HUDs but exposes **one** semantic set — the rotated top
HUD carries `isPrimarySemantic: false` and is `.accessibilityHidden(true)` wholesale. Only
the acting human gets `visualMoveRemaining` (`ownsMoveTimer = viewerID == current`).

## Accessibility and motion

- **VoiceOver labels/identifiers**: verified programmatically — `"Round 1"` + value
  `"time remaining 2:56"`, `"YOUR TURN, clockwise play"`, `"6 seconds left to play"`.
  **VoiceOver itself was not run**; rotor order and spoken output were not audited.
- **Reduce Motion** (system): **measured** — 0 px change across consecutive frames; the
  static trace remains visible, so direction context persists rather than disappearing.
- **Reduced visual effects** (app setting): **verified visually** via the legacy settings
  launch — static arc clearly present.
- **Animation speed Off**: covered by the same `motionDisabled` code path
  (`directionAnimationDisabled || reducedVisualEffects || reduceMotion`); **not separately captured**.
- **Colour-blind + pattern fills**: **verified visually** — hatching and corner symbols
  present; element chip shows displayName + symbol (`≈ SKY`, `◈ GRASS`) as semantic truth.
- **Increased Contrast, Button Shapes, grayscale**: **NOT TESTED**.
- **Timer ticks do not spam VoiceOver**: no `announcement`/`AccessibilityNotification` is
  posted per tick — verified by inspection, not by listening.
- Ambient background is `.accessibilityHidden(true)` and only renders in `.playing`
  (`vs.phase == .playing ? vs.turnDirection : nil`).

### Finding (not fixed): the edge HUD does not scale with Dynamic Type

`GameEdgeHUD` uses fixed `.font(.system(size:))` throughout. At AX5 everything else scales
dramatically while the HUD stays at ~8–10 pt (see `ax5.png`). This is *why* the slot can be
width-reserved and the table never shifts — the two requirements are in direct tension, so I
did not change it unilaterally. VoiceOver coverage is unaffected. **Worth a product decision.**

### Minor observation: urgency boundary rounding

`isUrgent` tests `remaining <= 3` while the digit shows `Int(remaining.rounded())`, so the
slot can read "3" for ~half a second before turning amber. Cosmetic only.

## Persistence

- **Real legacy migration**: generated a genuine pre-Phase-19 settings file by running the
  **baseline** code (all 12 fields non-default, no `tableBackgroundStyle` key), then decoded
  it with the new code. Every prior preference survived; style defaulted to `.felt`.
- **App-level launch** with that file: rendered correctly with `largeCards`, `colourBlindMode`,
  `patternFills`, `reducedVisualEffects` all honoured, Felt background. The app did **not**
  rewrite the file — no key injected on read.
- **Style round-trip**: aurora → relaunch → contours → relaunch, each persisted; other
  preferences undisturbed.
- **Reset-all**: `UserSettings()` returns `.felt`.
- **`largeCards` never mutated**: `false` before, during an AX5 session, and after returning
  below AX3. AX3+ enlargement is derived (`largeCards || dynamicTypeSize >= .accessibility3`),
  read-only.
- Game snapshot/schema untouched — `WildPairsCore` diff is one file, +12 lines, additive.

## Performance

- Sustained play on iPhone 17 Pro and iPad Pro 13" (M5) with the ambient TimelineView active:
  no stalls, no stepping, no interference with card travel or overlays observed.
- The `.periodic` switch **reduces** run-loop pressure versus display-link driving.
- Opacity and update rate were left unchanged — no tuning proved necessary.
- **Energy/heat was not instrumented**; no Instruments trace was taken. Qualitative only.

## Deliberately untouched

- Engine/rules: no change. `WildPairsCore` diff = `UserSettings.swift` only, +12 additive lines
- `GameViewState` / `GamePresenter` / `GameViewModel`: no change
- Cards: `CardView`, `SoloArtFace`, `CardSkin`, faces/backs/assets — **no change**
- `CardColour` cases `crimson`/`cobalt`/`jade`/`amber` intact; display names via `displayName`
- No parallel timer, direction, current-player, or score model introduced
- No networking/accounts/IAP/analytics/GameKit/CloudKit/notifications/photo-library/permissions
- No test weakened, skipped, or renamed

## Remaining risks

1. **No iOS 17 execution anywhere.** Everything ran on iOS 26.5. The deployment target is
   correct, but iOS 17 runtime behaviour is unproven — worth installing the iOS 17 runtime
   before release sign-off.
2. **VoiceOver was never actually spoken.** The tree, labels, values, hidden-ness and element
   counts are verified; the listening pass is not.
3. **Increased Contrast, Button Shapes, grayscale untested.**
4. **Matrix gaps**: 375 pt iPhone, iPad landscape stills, Reverse flip live, Sun in isolation,
   Solo states, round-end/game-over overlays, Face-to-face seat variants.
5. **Pre-existing ~1-in-3 UI flake** will keep `quality_full` red intermittently until hardened.
6. **HUD does not honour Dynamic Type** (above) — needs a product call.
7. A `Invalid frame dimension (negative or non-finite)` SwiftUI runtime warning appears
   intermittently in UI-test logs. It is present at baseline too and was **not** traced.
