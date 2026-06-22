# Phase 5 — App Build Notes & Verification Boundary

> Authored on Windows (no Apple toolchain). This document is honest about what has and has
> not been compiled/run. **Nothing in `WildPairsApp/` has been built or run** — SwiftUI,
> UIKit, the iOS SDK, the Simulator, and XCUITest are Apple-only and cannot exist on Windows.
> The code is written to a high standard and is intended to compile on Mac, but it is
> unverified until built there.

---

## What was done off-Mac, and how far it can be trusted

| Layer | Location | Status on Windows |
|---|---|---|
| Engine, rules, AI, persistence | `WildPairsCore` (Models/Engine/AI/Persistence) | Written + designed. Compiles on any Swift toolchain in principle; **not compiled here** (no toolchain). |
| Presentation logic | `WildPairsCore/Presentation` (`GameViewState`, `GamePresenter`) | Platform-agnostic (no SwiftUI/Combine) so it is unit-testable on Mac/Linux. **Not compiled here.** |
| Headless end-to-end harness | `WildPairsTests/EndToEndSessionTests.swift` | Drives full games through the presenter as a simulated human. Closest achievable E2E without Apple tooling. **Not run here.** |
| SwiftUI app | `WildPairsApp/` | **Cannot be compiled or run anywhere except a Mac.** Written to spec; unverified. |
| XCUITest | `WildPairsUITests/` | Mac-simulator only. Written; unverified. |

The architecture deliberately pushes *all* game and presentation logic into `WildPairsCore`
so the SwiftUI layer is a thin, near-logicless shell. That maximises how much of the app is
verifiable without a Mac (via `swift test`) and minimises the unverified surface.

---

## Generating and running on Mac

The Xcode project is **not** committed as a hand-written `.xcodeproj` (that would be fragile
and almost certainly wrong, authored blind on Windows). Instead it is generated from
`project.yml` with XcodeGen, which is deterministic and reviewable.

```bash
# one-time
brew install xcodegen          # NOTE: violates the project's no-Homebrew dev rule — see below

# from the repo root
xcodegen generate              # produces WildPairs.xcodeproj referencing the local package
open WildPairs.xcodeproj
# Select the WildPairs scheme → an iPhone 15 / iPad Air simulator → Run.
```

> **Constraint note:** `docs/git-workflow.md` / CLAUDE.md forbid Homebrew for the *engine*
> work. XcodeGen is a build-tooling convenience, not a runtime dependency, and produces no
> third-party code in the app. If you prefer zero extra tools, create the app target by hand
> in Xcode (File ▸ New ▸ Target ▸ App, name `WildPairs`, add the local `WildPairsCore`
> package, set the sources to `WildPairsApp/`, and point Info.plist at `WildPairsApp/Info.plist`).
> Either path yields the same target.

Run the logic tests (the part that is genuinely testable) with the Phase-2 wrapper:

```bash
./scripts/swift_test.sh        # WildPairsCore + WildPairsTests, incl. the E2E harness
```

---

## App structure

```
WildPairsApp/
  WildPairsApp.swift        @main + RootView (Home ⇄ live game, resume-from-save)
  Info.plist                No permission keys — fully offline (enterprise constraint)
  Theme/Theme.swift         Design tokens (colours, spacing, radius, motion) from design-system.md
  ViewModels/
    AppSettings.swift       UserSettings + GameStats store (persists via Core)
    HapticEngine.swift      UIKit feedback, gated on the haptics setting (§13)
    GameViewModel.swift      Thin @MainActor wrapper over GamePresenter; AI timing + effects
  Views/
    HomeView, NewGameFlowView, GameTableView, TableCenterView, HandView, CardView,
    PlayerZoneView, DecisionViews (colour/target/prompt), PauseMenuView, RoundEndView,
    SettingsView, StatisticsView, RulesView
WildPairsUITests/           Critical-journey XCUITests (UIT-01/03/04/06/09)
project.yml                 XcodeGen spec (app + UI test target + local package dep)
```

### Design decisions worth knowing on review
- **Suit emblems use SF Symbols** (`flame.fill`, `water.waves`, `leaf.fill`, `sun.max.fill`)
  rather than hand-drawn `Path` shapes. The design system specifies custom `Shape`s; SF
  Symbols were chosen because hand-authored geometry can't be visually verified off-Mac.
  Swapping in custom `Shape`s later is isolated to `CardView`/`TableCenterView`.
- **Colour-blind safety by default**: every card shows its suit symbol; the active-colour
  indicator always shows the colour name. The colour-blind setting adds the name onto cards.
  Pattern fills (§8) are modelled in settings but not yet drawn — a `CardView` enhancement.
- **AI turn pacing** lives in `GameViewModel` (Task.sleep using `AIPlayer.thinkDelay`), so the
  pure `GamePresenter` stays synchronous and testable.

---

## First things to check when you reach a Mac

1. `swift build` + `./scripts/swift_test.sh` — confirms Core + presentation + E2E harness.
   These are the genuinely-trustworthy artifacts; fix any compile/test failures here first.
2. `xcodegen generate && open WildPairs.xcodeproj` — confirms the app target wires up.
3. Build & run on an iPhone 15 simulator: New Game → Standard → play a round.
4. Likely fix-ups (written blind): exact SwiftUI modifier availability on iOS 17, the
   get-only `.sheet` bindings in `GameTableView` (decision sheets), and the
   `ContentUnavailableView` / `.onChange(of:_:)` iOS-17 signatures.
5. Then run the XCUITests and the manual accessibility passes (VoiceOver, Dynamic Type) —
   none of which are possible off-Mac.

---

## Phase status (off-Mac)

| Phase | Scope | Off-Mac status |
|---|---|---|
| 2 | Core engine | Code complete; unit + scenario tests written; **needs Mac `swift test`** |
| 3 | Full rules | Code complete (all card effects, win/Solo!); tests written; **needs Mac** |
| 4 | AI | All four levels + simulator + balance tests written; **needs Mac** |
| 5 | SwiftUI app | **Written, not buildable off-Mac.** Logic extracted to Core + E2E harness. |
| 6 | UX polish / a11y | Partial: haptics, Dynamic Type via system fonts, colour-blind labels, VoiceOver labels written. Animation polish, pattern fills, onboarding overlay, and sound are still TODO and need a Mac to tune. |
| 7 | QA hardening | Logic-level coverage is strong; XCUITests written. Performance, memory, and device QA need a Mac. |
| 8 | Release | Not started; needs a signed build, TestFlight, and the release checklist run on Mac. |
