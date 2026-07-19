# Task: Integrate the Solo table redesign + UX improvements (UNO-Mobile-informed)

> Paste-ready brief for a fresh local session (Mac + Xcode — simulator work is required).
> Assumes you start cold. The ChatGPT design step is COMPLETE; its output is committed in
> this repo. Your job is Tier-0 bug fixes, then the redesign integration, then the rest.

## Context (read these first)
- Repo: `alastairlivingston-sudo/wild-pairs`. Work on branch `claude/game-ux-video-analysis-29ddem`
  (branch from latest default if it's already merged).
- Read `CLAUDE.md` (identity, offline/no-IAP/no-network/no-GameKit enterprise constraints,
  design vocabulary) and `.claude/ROUTER.md` (skill/agent routing) before doing anything.
- Read the benchmark under `docs/video-ux-benchmarks/uno-mobile-gowild/`:
  `feature-inventory.md`, `gap-analysis.md`, `ux-match-plan.md`, and this file.
- Key finding to respect: **the in-round game feel is already built** (cross-table card
  travel, turn hand-off sweep, active-seat glow, stack pops, seat cues, playable-card lift,
  confetti). Do NOT rebuild it.
- Hard boundary: anything needing network, accounts, IAP, telemetry, or GameKit is a
  non-goal. Dramatise *score*, never coins.

## The redesign handoff package (ChatGPT, received 2026-07-18)

The single-prompt ChatGPT design flow (see `chatgpt-design-brief.md`) returned a
**project-aware integration package**, committed at repo root under **`WORKING_FILES/`**:

- `WORKING_FILES/CLAUDE_HANDOFF_PROMPT.md` — the full integration prompt from ChatGPT
  (conflict template, resolution modes 1–5, validation matrix, required outputs). Follow
  its process, subject to the **owner-adjudicated rulings below**, which take precedence.
- `WORKING_FILES/patch/solo-table-project-aware-v2.patch` — binary git patch (9 Swift
  files + 6 imagesets).
- `WORKING_FILES/repo-overlay/` — full replacement copies at real repo paths (semantic
  merge fallback only).
- `WORKING_FILES/docs/` — read in this order: `EXACT_PROJECT_CONFLICT_REPORT.md`,
  `COMPONENT_AND_STATE_CONTRACTS.md`, `FILE_BY_FILE_CHANGELOG.md`,
  `TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md`, `VALIDATION_REPORT.md`, `QUICK_CHAT_DECISION.md`.
- `WORKING_FILES/solo_project_aware_end_to_end_preview.html` — offline visual reference
  (this is the owner-approved look).
- `WORKING_FILES/tools/verify_solo_table_integration.sh` — post-apply static checks.

What the patch delivers: Lava/Sky/Grass/Sun display names (via `displayName` only);
image-based card back through the existing `CardBackView`; physical three-layer draw
deck with outside-edge count badge and a 24 pt draw/discard gap; always-visible mirrored
direction orbit + `REVERSED` confirmation; opponent fans of card backs topped by
elemental crests; `PARTNER · OPEN HAND` shelf; white active-turn brackets + `UP NOW`
flag; unified state rail (element + turn + round timer, `game-turn-rail`); native
thumb-zone Solo! burst button; `CATCH +2` affordance and transient `+2 CAUGHT` stamp
driven by a new one-shot `SoloPenaltyEvent` derived from the existing
`GameEffect.soloCallMissed`; restrained new `TableBackground` (5 motes, 12 fps cap,
Reduce Motion / Reduced Visual Effects fallbacks); one added UI smoke test.

### Verified facts (checked against tip `d8a6b8d`, 2026-07-18 — re-verify if the branch moved)

- `git apply --check WORKING_FILES/patch/solo-table-project-aware-v2.patch` **passes
  cleanly** on the current tree.
- No symbol/asset collisions: `Theme.Table`, `SoloPenaltyEvent`, `game-turn-rail`, and
  `solo_table_*` do not exist in the repo today.
- `GameEffect.soloCallMissed(playerName:penaltyCards:)` exists
  (`WildPairsCore/Models/GameEffect.swift:105`); the package's display-name fallback for
  AI-originated catches is the correct adaptation.
- Identifiers `game-solo-button`, `game-round-timer`, `game-move-timer`,
  `game-draw-card-button`, `seat-<position>` all exist and are exercised by
  `WildPairsUITests`.

### Owner-adjudicated conflict rulings (Fable, 2026-07-18) — these are decisions, not questions

Where the ChatGPT package, the earlier plan text, and the repo disagreed, the owner
delegated the call. Apply these as settled:

- **R1 — In-place patch beats `TableRedesignKit.swift`.** The earlier brief asked for a
  standalone kit; the package instead evolves the existing owners (`TableCenterView`,
  `PlayerZoneView`, `CardBackView`, `GameTableView`, `TableBackground`, `Theme`) in
  place. The package wins — it matches the repo's single-owner MVVM/reducer architecture.
  All "adapt TableRedesignKit" language in `chatgpt-design-brief.md` is superseded.
- **R2 — Integration mode: direct apply (mode 1), reviewed.** Because the patch checks
  cleanly and no collisions exist, apply it directly — do NOT hand-merge from
  `repo-overlay`. But review the applied diff file-by-file against
  `EXACT_PROJECT_CONFLICT_REPORT.md` (highest risk: `GameTableView.swift`) before
  committing, and run the full validation below. If the branch has moved and the check
  fails, fall back to the package's semantic-merge process.
- **R3 — Round-timer bug lands FIRST (Tier-0 a), then the patch.** The new state rail
  takes over the `game-round-timer` identifier (overlay `GameTableView.swift:740`). Fix
  the reset-every-turn bug in engine/VM before applying the patch so the rail displays a
  correct single 3-minute countdown; re-run timer checks after the patch. After apply,
  `RoundTimerBadge` (`DecisionViews.swift:301`) becomes unused — delete it (no dead
  code), keeping the identifier in the rail. `MoveTimerBar` is untouched and stays.
- **R4 — Quick-chat: owner approval AND the package's ship-gate both stand.** The owner
  approved quick-chat as a REAL hint the AI partner weighs (decision Q4); the package
  correctly refuses to ship decorative buttons. Resolution: build it as a full-stack
  feature in the shape of `WORKING_FILES/docs/QUICK_CHAT_DECISION.md` —
  `GameAction.partnerInstruction`, one pending non-binding preference in `GameState`,
  AI-scorer hook, the 8 deterministic seeded tests listed there — with engine +
  `docs/game-rules.md` (Team Communication Rules) + CLAUDE.md + tests travelling as one
  unit per process rule 3. The UI strip lands only after the engine tests pass, and is
  hidden in pass-and-play / human-partner modes. This is compatible with AI fairness:
  partner hands are open by design and the instruction is public, non-binding team talk.
- **R5 — Native SwiftUI Solo!/caught treatments beat baked-text PNGs.** The package
  intentionally omits the Solo-burst and +2-badge PNGs the old brief requested and
  renders both natively. Accept: native text scales with Dynamic Type and VoiceOver;
  text baked into images does not. The old brief's asset list (section B items 4) is
  superseded. The six shipped assets (card back, direction ring, four crests) stand.
- **R6 — Crest identity: patch's seat-position mapping is v1; `AIProfile` becomes the
  authority.** Apply the patch as-is, then when Tier-1 item 1 introduces `AIProfile`
  (name + crest, built in `GameViewModel`), replace the local seat-position mapping with
  that field — per the package's own conflict rule §6. Never two identity sources.
- **R7 — Thermal pass (Tier-0 d) splits around the patch.** Do NOT profile the current
  aurora/weave background the patch deletes. Instrument timer/redraw suspects
  (`GameViewModel` timers, publish frequency) any time; do the animation/energy
  profiling AFTER the patch lands — the new background (5 motes, 12 fps cap, RM/RVE
  static fallbacks) is expected to be a net win and is what ships.
- **R8 — Colour-rename docs travel with the patch commit.** The patch changes only code
  strings. In the same commit, update every Fire/Rain/Earth/Wind display reference:
  `CLAUDE.md` (Canonical Design Vocabulary display columns), `docs/design-system.md`,
  `docs/game-rules.md`, `docs/release-checklist.md`, `docs/phase-17-requirements.md`.
  Internal names (`crimson`/`cobalt`/`jade`/`amber`), raw values, and save files never
  change (Phase 11 pattern). VoiceOver reads through `displayName` — verify, don't edit.
- **R9 — "Single-player" in the handoff prompt means "no online multiplayer".** The game
  is single-device 2v2 with AI seats and pass-and-play. Repo wording wins; do not remove
  pass-and-play affordances (the package itself protects seat rotation).
- **R10 — Nested `WORKING_FILES/CLAUDE.md` is reviewed and aligned**, but the repo-root
  `CLAUDE.md` overrides it on any disagreement (the nested file's own source-of-truth
  order agrees). Delete the entire `WORKING_FILES/` directory in its own commit once the
  integration is validated and merged — it is working material, not product.
- **R11 — Sign-off gate is satisfied for the patch scope.** The owner supplied this
  package for integration; the HTML preview is the approved look. Do not stop to
  re-request sign-off for the patch. Anything BEYOND patch scope with new visuals
  (quick-chat strip, rank ceremony) still stops for owner review before building.

### Validation (required before the integration commit is considered done)

1. `WORKING_FILES/tools/verify_solo_table_integration.sh`, then `./scripts/quality_light.sh`.
2. Clean iOS 17 build; full `swift test` + `WildPairsUITests` (including the added
   `testRedesignedTableChromeIsPresent`); confirm all six `solo_table_*` assets resolve.
3. `/simulator-verify` (iPhone → iPad, checkpoint between), then `/swiftui-quality-review`
   and `/accessibility-audit` — the state rail, fans, orbit, and Solo control are new
   affordances.
4. Work through `WORKING_FILES/docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md`: all critical
   gates, the 13-row state matrix, and a scored sheet with evidence. A compile-only
   result caps at 70/100 — do not claim 10/10 without the matrix.
5. Card-flight/draw-flight anchors still originate and land on the visible piles;
   375 pt-wide iPhone shows no clipping (side columns drop 80 → 72 pt).
6. Report any deviation from the package with the conflict template in
   `WORKING_FILES/CLAUDE_HANDOFF_PROMPT.md`.

## Process (per .claude/ROUTER.md)
1. Before the Tier-1 items, run `/premortem` then `/promoter-score-review`.
2. Design elements are DONE (package above). `chatgpt-design-brief.md` is historical
   record only.
3. Rule/behaviour changes travel as a unit (engine + game-rules.md + CLAUDE.md + tests).
4. Verify every visual change with `/simulator-verify`, then `/swiftui-quality-review`
   and `/accessibility-audit` for anything with new affordances.
5. Commit per item; do not open a PR unless I ask.

## Work items and sequence

**Tier 0 (bug fixes — route via `/playtest-fix`):**
a. Round timer resets every turn instead of counting down once per round — **must land
   before the patch** (ruling R3).
b. Skip does not resolve correctly in partner/Side-to-Side mode.
c. Draw Four challenge prompt sometimes offers only "Accept", never "Decline".
d. Thermal/battery: timer/redraw instrumentation now; animation/energy profiling after
   the patch (ruling R7). Route performance-reliability-lead.

**Tier 1:**
1. **Apply the redesign patch** per the rulings above, including the colour-rename doc
   sweep (R8) and full validation. This delivers what were previously "Tier-1 item 3"
   (table centre + presence), most of "Solo! enhancements" strands (a) call-moment drama
   and (b) catching flow, the partner-peek clarity fix, and the colour renaming.
2. Opponent identity — `AIProfile` (name + crest) built in `GameViewModel`; replaces the
   patch's seat-position crest mapping as the single authority (ruling R6). Compact on
   iPad landscape; never colour alone.
3. End-of-game rank ceremony + one-tap "Play again" (same opponents/mode/teammate).
   Targets: `RoundEndView` game-over branch in `PauseMenuView.swift`;
   `restartWithSameConfig()` on `GameViewModel`. Skippable + Reduced-Motion safe.
   New visuals → owner sign-off first (R11).

**Tier 1.5 — Quick-chat (full-stack, ruling R4):** engine contract + AI hook + 8
deterministic tests + docs as one unit; UI strip only after tests pass; hidden without
an AI partner; owner sign-off on the strip's visual before building it.

**Tier 2 (independent polish):**
4. Elevate the per-move timer in the final seconds (central numeral / stronger pulse;
   keep the calm bar otherwise). `MoveTimerBar` in `DecisionViews.swift` + a
   `GameTableView` overlay.
5. Colour-pick confirmation flourish (colour wash into the existing discard-tint pulse);
   keep the accessible swatch grid.
6. AI-personality reaction bubbles (difficulty-scaled, rare, settings-gated) — Solo!
   strand (c): AI seats visibly react to calls/catches. Run `/promoter-score-review`.

Sequence: Tier 0 a → (b, c, d-instrumentation in any order) → Tier 1 item 1 (patch) →
Tier 1 items 2–3 → d-profiling → Tier 1.5 → Tier 2. Cleanup: delete `WORKING_FILES/`
once merged (R10).

## Owner playtest feedback log (2026-07-17) — resolution status
<!-- Original nine points, now mapped to the work items above. -->

- **(E) Solo! enhancements** — strands (a) call drama + (b) catch flow: **delivered by
  the patch** (Solo burst button, CATCH +2 affordance, +2 CAUGHT stamp). Strand (c) AI
  reactions: Tier-2 item 6.
- **(B/perf) Device runs hot** — Tier-0 item d, split per ruling R7.
- **(B+E) Partner mode** — Skip bug: Tier-0 item b. Partner peek too small/hidden:
  **delivered by the patch** (`PARTNER · OPEN HAND` shelf); verify it reads clearly on
  iPhone in `/simulator-verify`.
- **(E) Turn-order + whose-turn clarity** — **delivered by the patch** (always-visible
  mirrored direction orbit, `REVERSED` confirmation, white brackets + `UP NOW`, state
  rail).
- **(E) Quick-chat** — Tier 1.5, ruling R4 (real hint, engine-first).
- **(B/E) Middle-of-table redesign** — **delivered by the patch** (three-layer draw
  deck, 24 pt gap, outside-edge badge, opponent fans of real card backs).
- **(B) Challenge flow** (Accept-only bug) — Tier-0 item c.
- **(E) Colour renaming** — code **delivered by the patch**; docs sweep travels in the
  same commit (ruling R8).
- **(B) Round timer resets** — Tier-0 item a, lands before the patch (ruling R3).

## Other issues I'm noticing (ADD YOURS HERE)
<!-- Template per issue: Screen/flow · what you saw · why it feels off · video timestamp if any -->
