# Bundle manifest

## Identity

| Field | Value |
|---|---|
| Bundle | `solo-phase-19-github-integration` |
| Prepared | 19 July 2026 |
| Product | Solo — offline Universal iPhone/iPad card game |
| Target | iOS 17+ / SwiftUI |
| Patch baseline | `5e3d18412502bfef5cc6922759e98f55579b407e` |
| Integration model | Reopen live files, apply cleanly or semantic-merge, verify, commit, push |

## Approved scope

- P19-01 fixed edge HUD and move-timer relocation;
- P19-02 smaller top turn/direction information and stronger seat-local turn ownership;
- P19-05 AX3+ effective large-card mode without mutating the saved preference;
- subtle presenter-owned clockwise/counter-clockwise table-background ambience;
- selectable built-in offline Felt, Aurora, and Contours table surfaces;
- clearer Lava/Sky/Grass/Sun table state through tint plus colour-blind pattern;
- settings persistence and backward-compatible missing-key fallback;
- documentation and persistence-test updates for this scope.

## Patch

```text
PATCH/solo-phase-19-wave-a-backgrounds.patch
```

This is the only production patch in the bundle. It contains 14 changed repository paths, including one new Swift file.

## Changed repository paths

```text
WildPairsApp/Theme/TableBackground.swift
WildPairsApp/Theme/Theme.swift
WildPairsApp/Views/DecisionViews.swift
WildPairsApp/Views/GameEdgeHUD.swift
WildPairsApp/Views/GameTableView.swift
WildPairsApp/Views/PassAndPlayTableView.swift
WildPairsApp/Views/PlayerZoneView.swift
WildPairsApp/Views/SettingsView.swift
WildPairsApp/Views/TableCenterView.swift
WildPairsCore/Persistence/UserSettings.swift
WildPairsTests/UnitTests/PersistenceTests.swift
docs/accessibility-plan.md
docs/design-system.md
docs/ux-spec.md
```

## Review artifacts

- `PREVIEW/solo-phase-19-state-lab-backgrounds.html` — final self-contained offline state lab;
- `PREVIEW/solo-phase-19-gameplay-concept.mp4` — 25.2-second, 1280×720, silent concept capture;
- `PREVIEW/solo-phase-19-gameplay-contact-sheet.jpg` — video overview;
- `PROOF/` — four approved background/state references.

The preview cards are neutral placeholders. Production card faces, backs, skins, and assets are outside this change set.

## Process artifacts

- `CLAUDE_CODE_INTEGRATION_PROMPT.md`
- `CHANGELOG.md`
- `SOURCE_ANCHORS.md`
- `CONSTRAINTS.md`
- `VERIFICATION.md`
- `VALIDATION.md`
- `FINAL_REPORT_TEMPLATE.md`
- `HANDBACK_PROTOCOL.md`
- `SHA256SUMS.txt`
