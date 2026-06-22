# Wild Pairs — Phase 6–8 Engineering Brief (new-session handoff)

> Drop this into a fresh session as the working prompt. It is self-contained: a senior engineer
> with no prior context should be able to execute from here. The git repo is the source of truth.

---

You are a senior iOS engineer continuing work on Wild Pairs, an offline Universal (iPhone+iPad)
SwiftUI card game. You have NO memory of prior sessions; the git repo is the source of truth.
Work in `/Users/alastair/dev` on a Mac with full Xcode 26.5.

## Where things stand (verify, don't trust)
`main` (~commit 8de9a9a) builds, tests pass, and runs in the Simulator for the first time —
everything was previously written blind on Windows and only recently compiled/fixed on Mac.
Confirmed green at handoff: `swift build`; `./scripts/swift_test.sh` (205 tests, 22 suites,
deterministic across repeated runs); `xcodegen generate` → `WildPairs.xcodeproj`; `xcodebuild
build` + `xcodebuild test` (4 XCUITests) on iPhone 17 and iPad Air 13" (M4). Phases 2–5 are done.
Your job is Phases 6–8 PLUS the specific user-observed issues listed at the end.

FIRST, re-establish ground truth before changing anything:
```
git fetch && git status && git log --oneline -8
swift build && ./scripts/swift_test.sh
xcodegen generate
xcodebuild build -scheme WildPairs -destination 'platform=iOS Simulator,name=iPhone 17'
```
Report the results. If any are not green, STOP and fix that before new work.

## Read first (canonical, in this order)
- `CLAUDE.md` — identity, architecture, enterprise constraints, coding style, vocabulary
- `docs/git-workflow.md` — branch/commit rules
- `docs/release-checklist.md` §Phase-6/7/8 — the actual gate criteria you must satisfy
- `docs/game-rules.md` — canonical rules (the timed-round scoring rule is now the default; read it)
- `docs/accessibility-plan.md`, `docs/design-system.md`, `docs/testing-strategy.md`
- `docs/playtest-review.md` — documented deferred gaps G1–G5
- `docs/phase-5-app-notes.md` — verification boundary

## Environment realities (learned the hard way — save yourself the rediscovery)
- The Xcode project is GENERATED from `project.yml`. Never hand-edit `WildPairs.xcodeproj`; it's
  gitignored. After any `project.yml` or file-layout change: `xcodegen generate`.
- This runtime is iOS 26.5 ONLY. "iPhone 15" / "iPad Air (5th generation)" do NOT exist. Use
  iPhone 17 and "iPad Air 13-inch (M4)". Scripts take `IPHONE_SIM`/`IPAD_SIM` env overrides.
- The scheme/target is `WildPairs` (NOT `WildPairsApp` — that name in some older docs is wrong).
- `./scripts/swift_test.sh` is the canonical test command (handles the Swift Testing framework
  paths). macOS ships bash 3.2 — beware empty-array `set -u` expansion.
- DETERMINISM TRAP: never break ties with `Dictionary.max(by:)` over enum/UUID keys — hash
  iteration order is randomized per process and silently breaks seed reproducibility. Break ties
  via a fixed order (e.g. `CardColour.allCases`, `seatPosition`). Two such bugs were already
  fixed; don't reintroduce the pattern.

## Hard constraints (non-negotiable)
- Offline only. NO URLSession/Network/analytics/telemetry/3rd-party runtime deps. Info.plist
  has ZERO permission/usage-description keys. PrivacyInfo.xcprivacy declares no tracking.
- NO sudo/system changes. Tooling is already installed; if you think you need a new tool
  (brew/npm/etc.), STOP and ask first.
- Git: small commits per green gate; never force-push; never skip hooks; branch off main (e.g.
  `phase-6-polish`) — do not commit straight to main. End every commit body with:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- Do NOT change documented RuleProfile defaults or canonical rules to make a test pass. Fix the
  code or the test. If a CHANGE to the canonical rules is genuinely wanted (see observed issue #1
  below), update `docs/game-rules.md` deliberately and call it out — don't smuggle it in.
- Never call anything "tested" unless you compiled/ran it and saw it pass. After each gate,
  report output summary, failures, fixes, and pass/fail.

## Scope — Phases 6, 7, 8 (gated; finish and verify each before advancing)

### P6 — UX polish & accessibility (release-checklist §Phase-6, accessibility-plan.md)
- Onboarding overlay (first-launch rules explainer; dismissible; persisted "seen" flag).
- Colour-blind PATTERN FILLS on cards (modelled in settings as `patternFills` but NOT yet drawn
  — see `CardView`; the four patterns are specified in CLAUDE.md's colour table).
- Sound coordinator (offline bundled audio only; gated on a settings toggle; respect silent
  mode; no `AVCaptureSession`/mic).
- VoiceOver pass: every interactive element labelled/hinted; Solo! announcements; round-end.
- Dynamic Type: layouts survive accessibility text sizes without clipping/overlap.
- VISIBLE TIMER UI: the timed-round rule (3-min round timer, 10-sec per-move timer) is fully
  implemented in the engine/`GamePresenter` and wired in `GameViewModel`, but has NO on-screen
  representation — players can't see either countdown. Add tasteful countdown UI, plus the
  "lowest score wins" round-end state when the round timer fires. (Confirmed: timers are
  referenced only in `GameViewModel`, nowhere in the Views.)

### P7 — QA hardening (release-checklist §Phase-7, testing-strategy.md)
- Run the FULL 1,000-game balance suite (smoke suite currently runs 100/difficulty); confirm 0
  illegal moves, no genuine stuck games, sane win-rate spread across easy→master. Record results
  in `docs/ai-balance-report.md`.
- Performance/memory pass on device-class simulators (launch time, frame hitches during AI turns
  and animations, memory growth across many rounds, save/resume after backgrounding).
- Expand XCUITest coverage for new flows (onboarding, full multi-round session, the Solo!/catch
  moment, round-timer expiry if surfaced).
- Decide the documented deferred gaps G1–G5 (`playtest-review.md`): at minimum G4
  (`maxTurnsPerRound` engine enforcement) is a real defensive fix. G1 (Side-to-Side Team Pass)
  is a genuine missing feature needing a model change — flag scope before building it.

### P8 — Release prep (release-checklist §Phase-8)
- All quality gates clean: `quality_full.sh`, `check_no_network_usage.sh`,
  `check_permissions_minimal.sh`, `check_project_capabilities.sh`, `check_privacy_manifest.sh`,
  and `grep -rIn "UNO|Mattel|uno" docs WildPairsCore WildPairsApp` (matches only in meta-docs
  about the rule itself are acceptable).
- App icon + launch screen, version/build numbers, accessibility audit sign-off.
- Produce the release handover doc. STOP before any signing/upload/TestFlight/App Store step —
  that needs the owner's Apple account and explicit go-ahead.

## Issues already observed by the owner (treat as P6 priorities)

1. **Teammate's hand should be visible to the human player.** Currently NOT possible, and this
   CONTRADICTS the current canonical rules — `docs/game-rules.md` (Team Communication, ~line 388)
   states only the *count* of each player's cards is visible, and `GameViewState.PlayerSeatViewState`
   deliberately exposes `handCount` only, never card contents. The owner wants the human to SEE
   the AI partner's actual cards. This is therefore a deliberate RULE CHANGE, not a bug fix:
   - Update `docs/game-rules.md` Team Communication / visibility section to make the partner's
     hand open to the human (state it explicitly as the new canonical behaviour).
   - Add partner-hand contents to the presentation layer (e.g. extend `PlayerSeatViewState` /
     `GameViewState`) and render the partner's cards face-up in `PlayerZoneView` for the partner
     seat only — opponents stay count-only.
   - DECISION TO RAISE WITH OWNER before coding: does this also relax the AI-fairness model
     (CLAUDE.md says no player sees others' hidden hands)? I.e. should the AI partner likewise
     "see" the human's hand for better cooperative play, or is open-hand strictly a human-facing
     UI affordance? Confirm scope; don't assume.

2. **Landscape layout: content falls off the sides.** `GameTableView` uses fixed `HStack`/`VStack`
   geometry with no landscape adaptation and no scroll/safe-area handling, so seats/hand/controls
   overflow horizontally in landscape (both iPhone and iPad). Make the table layout responsive:
   honour safe-area insets, adapt to the size class / orientation, and ensure the hand and all
   four seats fit on every supported device in BOTH orientations. Verify on iPhone 17 and iPad
   Air 13" (M4) in portrait AND landscape.

3. **Overall UX quality is poor.** The app was authored blind and is functional but unpolished.
   Treat P6 as a genuine UX overhaul against `docs/ux-spec.md` and `docs/design-system.md`, not a
   checkbox pass: spacing/hierarchy/legibility, card and table visual quality, animation/feedback
   on play/draw/Solo!/round-end, empty and transitional states, and consistent use of the design
   tokens in `Theme/`. Where the spec and the current implementation disagree, the spec wins;
   where the spec is thin, propose a direction and confirm with the owner before large rebuilds.

## How to work
- Confirm P6 scope with the owner before starting (sound assets, onboarding copy, the issue-#1
  rules/fairness decision, and any large UX rebuild direction are choices the owner owns).
- One feature → build → `swift test` → `xcodebuild test` → commit, in small increments.
- When you hit a decision only the owner can make (rules ambiguity, balance regression, signing,
  tooling, sound/onboarding content, a deferred gap needing a model change), STOP and ask.
- Merge to main only when a phase's gate is fully green, via `--no-ff` from the phase branch.
```
