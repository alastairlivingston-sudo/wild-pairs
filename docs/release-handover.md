# Wild Pairs — Release Handover (Phase 6–8 session)

> Written at the end of an autonomous session executing `docs/phase-6-8-brief.md`.
> Branch: `phase-6-polish` (not yet merged to `main`). Status: Phases 6 and 7 complete;
> Phase 8 complete except the App Store submission steps, which need the owner's Apple
> Developer account and explicit go-ahead (the brief explicitly stops short of these).

---

## 1. What shipped this session

### Phase 6 — UX polish & accessibility
- **Rule change (owner-approved):** partner hands are now open to both the human and the AI
  (symmetric) — `docs/game-rules.md` §Team Communication Rules, `AIObservation.partnerHand`.
- Landscape layout fix for `GameTableView` (a real bug: the partner zone was invisible in
  landscape, traced to `CardView` corrupting its parent's layout when sized too small).
- First-launch onboarding overlay (4-page `TabView`, `hasSeenOnboarding` persisted).
- Colour-blind pattern fills on cards (diagonal/horizontal/vertical lines + dot grid per
  `design-system.md` §8), plus the colour-picker swatches and table colour indicator.
- Sound coordinator: `AVAudioPlayer`-based, `.ambient` session category (respects the
  silent switch, no mic/capture). 14 placeholder SFX synthesized via
  `scripts/generate_placeholder_sounds.swift` — **these are placeholders, not final sound
  design**; swap the files in `WildPairsApp/Resources/Sounds/` for real assets later,
  filenames must match `SoundEffect.rawValue`.
- VoiceOver pass: canonical per-spec card labels, Solo!/round-end live announcements, a real
  bug fix (`PlayerZoneView`'s `.accessibilityElement(children: .combine)` was silently
  swallowing the catch-out button from VoiceOver navigation).
- Dynamic Type AX3: found and fixed real bugs (a `Capsule` background that self-destructively
  clips multi-line text at large sizes; toolbar text truncation; an unbounded seat row that
  clipped off-screen) — caught by a new XCUITest that actually launches at AX3, not just
  unit-level assertions.
- Visible round/move timer UI (previously implemented in the engine with zero UI — players
  had no way to see either countdown).
- Full UX overhaul pass against `ux-spec.md`/`design-system.md`: copy fixes to match exact
  canonical wording, win/loss celebration (confetti + glow / gentle desaturate), AI thinking
  indicator, active-player pulsing glow, Solo! badge pop animation, colour-picker spec
  compliance. A few lower-priority spec items (target-picker pulsing ring, the partner
  "sets you up" luminous arc, a uniform animation-speed multiplier across every animation)
  were deliberately left for a future pass — flagged, not silently dropped.

### Phase 7 — QA hardening
- Full 1,000-game balance suite (`docs/ai-balance-report.md`): 0 illegal moves, 0 stuck
  games across 11,600+ games; all three placeholder acceptance criteria pass (Hard beats
  Easy 60.5%, Hard beats Medium 56.1%, Expert beats Easy 60.5%).
- Performance/memory pass (`WildPairsUITests/WildPairsPerformanceTests.swift`): ~0.91s cold
  launch, no memory-growth trend across multiple rounds, backgrounding/resume verified.
- Expanded XCUITest coverage: multi-round sessions, onboarding, colour-blind mode, timers,
  Side-to-Side Team Pass. Solo!/catch and round-timer-expiry UI automation were deliberately
  **not** added — see the inline comment in `WildPairsUITests.swift` for why (AI never misses
  Solo!, so it's structurally untestable against AI; both are covered at the unit level).
- Deferred gaps G1–G5 resolved or re-confirmed deferred:
  - **G1 (Side-to-Side Team Pass) — built**, owner approved. New `GamePhase.teamPass`,
    `GameAction.submitTeamPass`, AI heuristic, UI picker. Tests in
    `WildPairsTests/UnitTests/TeamPassTests.swift`.
  - **G4 (`maxTurnsPerRound` enforcement) — built.** `GameViewModel.enforceTurnCapIfNeeded`.
  - G2 (Draw Four challenge), G3 (Draw stacking), G5 (unused rule flags) — still
    intentionally deferred, low priority, documented in `docs/playtest-review.md`.

### Phase 8 — Release prep (partial — see §3 for what's NOT done)
- All automated quality gates green except one pre-existing, documented false positive
  (`check_no_network_usage.sh` flags the word "tracking" in "tracking your stats" UI copy —
  not analytics; see `docs/permission-audit.md` audit history).
- Trademark scan clean (`docs/premortem.md` §9.2 gate): no UNO/Mattel references in
  user-visible content.
- App icon added (`WildPairsApp/Assets.xcassets/AppIcon.appiconset`) — an original four-card
  fan design in the game's own colour palette, generated via
  `scripts/generate_app_icon.swift`.
- Launch screen background colour added (was a blank default).
- `docs/release-checklist.md` Phase 6 accessibility section updated with what's genuinely
  verified vs. what still needs a human (manual test scripts, Accessibility Inspector,
  physical-device haptics, Product Director/QA Lead sign-off).

---

## 2. How to build and test (Mac only — per `CLAUDE.md`, this repo is authored on Windows)

```bash
cd /path/to/repo
xcodegen generate                          # regenerates WildPairs.xcodeproj (gitignored)

# Unit tests (WildPairsCore logic)
swift test --package-path .
# or: ./scripts/swift_test.sh

# UI tests (requires a booted simulator)
xcodebuild test -scheme WildPairs \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'

# Full quality gate (build + both test suites on iPhone + iPad + quality checks)
bash scripts/quality_full.sh
```

Current state: **219 unit tests, 18 UI tests, all passing.** The UI test run takes
15–20 minutes (several tests drive real AI-paced gameplay to completion).

**A note on simulator stability:** during this session, after several hours of consecutive
`xcodebuild test` invocations, one test (`testGameTableSurvivesLandscapeRotation`) started
failing with "Activation point invalid" errors unrelated to any code change. A
`xcrun simctl shutdown` + `boot` cycle fixed it immediately. If you see a UI test fail with
that exact error message and it passed earlier in the session, suspect simulator resource
exhaustion before suspecting a real regression — reboot the simulator and retry once.

---

## 3. What's explicitly NOT done (and why)

- **App Store submission (release-checklist.md Phase 8 "App Store Submission Preparation"
  section):** App Store Connect record, screenshots, app description/keywords, age rating,
  signing, archive, upload. All of this needs the owner's Apple Developer account and
  explicit go-ahead — the brief stops short of this deliberately, and so does this session.
- **Manual test scripts (MTS-017 through MTS-034):** these are written for a human tester
  with a physical device; nothing here substitutes for actually running them.
- **Accessibility Inspector pass:** an interactive Xcode tool, not scriptable from this
  session.
- **Haptic feedback on a physical device:** the simulator cannot produce haptics; this needs
  a real device session.
- **Large card mode legibility, iPhone SE / Pro Max specific layout checks, iPad Split View
  narrow width:** not exercised this session — the UI test suite covers iPhone 17 and iPad
  Air 13" (M4) only.
- **`docs/accessibility-notes.md`:** referenced by the release checklist but doesn't exist
  yet. The underlying decisions are in code comments and this session's commit messages;
  worth consolidating into that file before the accessibility sign-off.
- **Sound assets are placeholders.** Synthesized sine-wave tones, not sound-designed audio.
  Swap files in `WildPairsApp/Resources/Sounds/` (same filenames, matching `SoundEffect`
  cases) whenever real assets are available — no code changes needed.
- **G2/G3/G5** (Draw Four challenge, draw stacking, unused rule flags) remain deferred,
  consistent with `docs/playtest-review.md`'s existing low-priority assessment.

---

## 4. Merging this branch

`phase-6-polish` has not been merged to `main`. Per the brief: "Merge to main only when a
phase's gate is fully green, via `--no-ff` from the phase branch." All phases 6 and 7 gates
are green; Phase 8 is green for everything in scope for this session (App Store submission
itself is out of scope, not a failing gate). Suggested merge command once you've reviewed
the diff:

```bash
git checkout main
git pull --ff-only
git merge --no-ff phase-6-polish
```

## 5. Suggested next steps, roughly in order

1. Review this session's commits (17 commits, `git log main..phase-6-polish`) and merge.
2. Source real sound-design assets to replace the placeholder SFX.
3. Run the manual test scripts (MTS-017 through MTS-034) on a physical device.
4. Consolidate accessibility decisions into `docs/accessibility-notes.md`.
5. Decide on G2/G3/G5 (or leave deferred indefinitely — they're genuinely low priority).
6. When ready to ship: App Store Connect setup, screenshots, metadata, archive, submit —
   all needs the owner directly, per the brief.
