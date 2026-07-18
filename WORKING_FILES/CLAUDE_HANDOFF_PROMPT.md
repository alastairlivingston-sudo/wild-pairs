# Claude Code handoff prompt: Solo table redesign integration

You are integrating a project-aware visual redesign into **Solo**, an original, fully offline iOS/iPadOS card game written in SwiftUI for iOS 17 and later.

The supplied handoff package contains:

- The existing-project audit and integration contracts.
- A project-aware Git patch.
- Complete replacement files as a semantic-merge reference.
- Xcode asset-catalog image sets.
- A self-contained HTML interaction preview.
- Validation scripts and a 10/10 design acceptance rubric.
- The Swift source-context archive that was used to prepare the redesign.

## Primary objective

Integrate the redesigned table into the current repository **without creating a second UI architecture or a second source of game state**. Preserve the current rules engine, model ownership, timers, turn progression, animation anchors, accessibility behaviour, save compatibility, and test identifiers.

The result should feel like a polished physical card table while remaining recognisably the current Solo app. Cards are the visual hero. Supporting interface should be quiet, coherent, and subordinate.

## Read these files first, in this order

1. `WORKING_FILES/README_FIRST.md`
2. `WORKING_FILES/CLAUDE.md`
3. `WORKING_FILES/docs/EXACT_PROJECT_CONFLICT_REPORT.md`
4. `WORKING_FILES/docs/COMPONENT_AND_STATE_CONTRACTS.md`
5. `WORKING_FILES/docs/FILE_BY_FILE_CHANGELOG.md`
6. `WORKING_FILES/docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md`
7. `WORKING_FILES/docs/VALIDATION_REPORT.md`
8. `WORKING_FILES/docs/QUICK_CHAT_DECISION.md`
9. `WORKING_FILES/solo_project_aware_end_to_end_preview.html`

Treat those documents as the implementation contract. When a document conflicts with the current repository, inspect the live code and follow the conflict process below rather than blindly replacing it.

## Non-negotiable product constraints

- This is an original game. Do not introduce UNO, Mattel, Top Trumps, or any other existing game branding, artwork, logos, card-face layout, or trade dress.
- The user-facing colour names are **Lava**, **Sky**, **Grass**, and **Sun**.
- Preserve internal persisted enum cases such as `crimson`, `cobalt`, `jade`, and `amber` if they exist. Do not rename Codable or save-game values merely to change display names.
- The game remains fully offline and single-player. Do not add accounts, stores, currencies, social features, networking, tracking, or online dependencies.
- The partner hand remains face-up by design.
- Do not rely on colour alone. Retain the per-element symbols and patterns.
- Every animation must have a Reduced Motion fallback.
- Dynamic Type, VoiceOver, compact iPhone portrait, and iPad landscape are required, not optional polish.

## Existing architecture is authoritative

Do not introduce parallel ownership of any of the following:

- Current player or active seat
- Play direction
- Draw-pile or discard-pile contents
- Round timer or move timer
- Solo eligibility, Solo calls, catch eligibility, or penalties
- Card-flight or draw-flight events
- Score, round state, pending decisions, or AI decisions

Use the existing `GameViewModel`, presentation state, engine effects, and view closures. Presentation-only transient events may be added only when derived from an existing engine effect and only when they cannot mutate rules state.

## Integration targets

Evolve the existing views in place. Do not install a second table system around them.

- `GameTableView`: overall composition, state rail, layout adaptation, Solo placement.
- `TableCenterView`: draw stack, discard pile, direction orbit, pile spacing, draw interactions, anchors.
- `PlayerZoneView`: partner open-hand shelf, opponent fans, crests, active-turn treatment, catch affordance.
- `CardBackView`: one shared original card-back rendering used everywhere.
- `TableBackground`: restrained material grain, element pattern, centre atmosphere, edge vignette.
- `Theme`: project-native spacing and styling tokens.
- `GameViewModel` / presentation state: only the smallest presentation event needed for the caught-penalty moment.
- UI tests: preserve old identifiers and add coverage for the new state rail and interaction states.

## Required visual decisions

1. **Draw versus played cards**
   - Keep a clear physical separation between the draw deck and played-card pile.
   - Use the project token equivalent of 24 points by default, with a 16-point minimum only when necessary for compact layouts.
   - Place the draw-count badge on the outside edge of the draw deck, never in the gap between piles.
   - The discard remains the stronger focal pile.

2. **Direction of play**
   - Keep the direction orbit always visible behind the two piles.
   - It must visibly mirror or flip when direction changes.
   - It must remain subordinate to the cards and must not become a large glowing control.

3. **Opponent seats**
   - Show a small physical fan of face-down card backs with an exact readable count.
   - Add an abstract elemental crest, not a human face or character.
   - Active turn must use shape, label, elevation, and/or brackets in addition to colour.

4. **Partner hand**
   - Preserve the face-up hand.
   - Clarify ownership with a lightweight `PARTNER · OPEN HAND` treatment without putting the whole hand inside a dominant dashboard panel.

5. **Solo and catch**
   - Make the Solo call prominent only when relevant and place it in a reachable trailing-thumb area.
   - Retain existing rule ownership and eligibility checks.
   - Provide an explicit catch affordance during the valid window.
   - Show `+2 CAUGHT` as a transient presentation derived from the existing engine effect; never apply cards from the view.

6. **Background**
   - Use a dark table surface, subtle material grain, low-contrast element pattern, broad centre atmosphere, and restrained edge vignette.
   - Avoid decorative panel soup, giant watermarks, permanent particle fields, or continuous glowing effects.

7. **Quick chat**
   - Do not add decorative buttons that have no effect on partner AI.
   - Follow `WORKING_FILES/docs/QUICK_CHAT_DECISION.md`.
   - Defer the feature unless the engine receives the documented one-turn, non-binding AI preference contract and deterministic tests.

## Conflict-resolution procedure

Before editing, inventory the current repository and compare each target file with the supplied patch and overlay.

For every conflict, record:

```text
Conflict:
Current owner:
Redesign intent:
Why both versions cannot remain unchanged:
Options considered:
Chosen resolution:
Files changed:
Files intentionally preserved:
Regression risk:
Validation:
```

Use one of these resolution modes per component:

1. Apply the supplied change directly when the current file matches the audited baseline.
2. Semantically merge the redesign into a newer existing implementation.
3. Preserve the existing component and restyle its internals when it already owns more state or behaviour.
4. Add a narrow adapter between existing models and presentation values.
5. Omit a supplied visual component when the current implementation is demonstrably better and still satisfies the acceptance gates.

Never overwrite a newer file wholesale merely because a replacement file exists in `WORKING_FILES/repo-overlay`.

## Patch workflow

First test the patch without changing the repository:

```sh
git apply --check WORKING_FILES/patch/solo-table-project-aware-v2.patch
```

If it applies cleanly and the repository matches the audited baseline, apply it:

```sh
git apply WORKING_FILES/patch/solo-table-project-aware-v2.patch
```

If it does not apply cleanly, do not force it. Use the patch and `WORKING_FILES/repo-overlay` as semantic merge references, then document every conflict.

## Asset rules

- Add the supplied namespaced image sets to the existing asset catalog without deleting unrelated assets.
- Keep one authoritative card back through the existing `CardBackView`.
- Preserve transparency, dimensions, and asset names.
- Confirm target membership and test each asset with `Image(...)` in the real app.
- Do not redraw, compress, rename, or reinterpret approved card-face assets.

## Required validation

Run and report all checks available in the actual project:

- Clean Xcode build for the iOS 17 target.
- Unit tests and UI tests.
- iPhone portrait at the smallest supported width.
- iPad landscape with compact vertical space.
- Local, partner, left-opponent, and right-opponent turns.
- Clockwise and counterclockwise direction.
- Lava, Sky, Grass, and Sun states.
- Solo normal, urgent, called, catch-available, and caught-penalty states.
- Large Dynamic Type sizes.
- VoiceOver order, labels, values, and actions.
- Reduce Motion enabled.
- Greyscale or colour-filter review proving patterns and symbols remain sufficient.
- Long hands, maximum realistic pile counts, pending draw stack, wild resolution, reverse, and timed-round edge states.
- Animation-anchor correctness for draw and discard card flights.
- No new clipping, overlap, unsafe-area intrusion, inaccessible hit targets, or frame-rate regressions.

Preserve existing accessibility identifiers and add new ones only where documented. The redesign is not accepted if a visually attractive change breaks automation or rule feedback.

## 10/10 standard

Do not claim 10/10 based on appearance alone. Use `WORKING_FILES/docs/TEN_OUT_OF_TEN_ACCEPTANCE_GATES.md` and provide evidence for:

- Visual hierarchy and coherence
- Spatial clarity of draw and discard piles
- Immediate turn and direction comprehension
- Physical card-table feel
- Thumb reach and interaction ergonomics
- Colour-blind and low-vision safety
- VoiceOver, Dynamic Type, and Reduced Motion
- iPhone and iPad responsiveness
- Animation and rendering performance
- Integration safety, state ownership, tests, and maintainability

A release candidate must have no critical gate failure, no unresolved state-ownership conflict, and no deceptive or non-functional control.

## Required output from this task

Before making changes, return:

1. A concise repository inventory.
2. A conflict table for every affected file.
3. The chosen integration mode for each component.
4. A list of files you will modify and files you will intentionally preserve.

After implementation, return:

1. A file-by-file changelog.
2. Any deviations from the supplied design and the reason for each.
3. Build and test results.
4. Accessibility and device-size validation results.
5. Remaining risks or manual checks.
6. A scored acceptance-gate report with evidence, not an unsupported 10/10 claim.

Do not silently rewrite game logic. Stop and explain whenever a requested visual treatment would require changing engine semantics.
