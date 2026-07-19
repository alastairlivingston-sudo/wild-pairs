# Comprehensive changelog

| File | What changes | Why | Integration risk |
|---|---|---|---|
| `WildPairsApp/Views/GameEdgeHUD.swift` | Adds the shared fixed-height HUD for round clock, exact scores, compact turn/direction, a width-reserved move timer, and optional pause. Supports a rotated visual copy while exposing one semantic copy. | Keeps timer appearance from moving the table or hand and places the approved smaller turn/direction information at the physical edge. | High: check width, AX3/AX5, mirrored Face-to-face semantics, long names, and timer ownership. |
| `WildPairsApp/Views/GameTableView.swift` | Replaces the old score bar, centre turn rail, and hand-area move timer with `GameEdgeHUD`; adds local active-seat brackets and `PLAY NOW`; derives effective large cards at AX3+; passes current direction, phase, selected background style, and animation-off state to the table surface. | Implements the approved clarity hierarchy without duplicating engine facts. | High: large structural view diff; check vertical fit, overlays, anchors, taps, and existing animation layers. |
| `WildPairsApp/Views/PassAndPlayTableView.swift` | Adds orientation-correct top/bottom HUDs, one semantic source, active-human brackets, AX3+ card sizing, one side pause button, and the same background style/direction inputs. | Gives the existing two-human table Wave A parity without creating another mode or state owner. | High: check top/bottom perspective, one set of identifiers, pause overlap, legacy active/collapsed geometry, and no handoff path. |
| `WildPairsApp/Views/TableCenterView.swift` | Removes duplicate persistent direction text below the piles, retains the direction orbit, shows a compact symbol/name current-element chip, and keeps the short `REVERSED` confirmation. | The top HUD owns the compact text; the centre retains table-coordinate arrows and element truth. | Medium: confirm pile hit targets and transient/chip collision at the smallest height. |
| `WildPairsApp/Theme/Theme.swift` | Adds fixed HUD and move-timer dimensions and raises the resting direction-orbit opacity from `0.24` to `0.42`. | Centralises stable geometry and improves still-frame direction legibility. | Low–medium: tune only after device review; do not make the orbit compete with cards. |
| `WildPairsApp/Views/PlayerZoneView.swift` | Makes the existing `ActiveSeatBrackets` available module-wide. | Reuses the established non-colour turn shape for local and shared-table human hands. | Low. |
| `WildPairsApp/Views/DecisionViews.swift` | Removes the obsolete hand-area `MoveTimerBar`. | Prevents a second timer UI and keeps `game-move-timer` in the fixed HUD. | Low: confirm there are no remaining call sites. |
| `WildPairsApp/Theme/TableBackground.swift` | Adds Felt, Aurora, and Contours surfaces; strengthens the authoritative active-element field and pattern; adds the low-opacity clockwise/counter-clockwise ambient arc with static motion fallbacks; adds display copy for the styles. | Makes direction subtly present in the background and makes Lava/Sky/Grass/Sun clearer without enlarging the HUD. | Medium–high: continuous drawing, contrast, and performance need iPhone/iPad validation. |
| `WildPairsApp/Views/SettingsView.swift` | Adds an Appearance section with the `settings-table-background-picker` and previews the selected surface. | Exposes the three built-in offline backgrounds as a persisted preference. | Low–medium: verify Form layout and VoiceOver value at AX sizes. |
| `WildPairsCore/Persistence/UserSettings.swift` | Adds stable Codable `TableBackgroundStyle` cases (`felt`, `aurora`, `contours`) and a `.felt` default in the custom decoder. | Persists appearance without parallel game state and lets older settings load safely. | Medium: verify migration with a real pre-change settings file. |
| `WildPairsTests/UnitTests/PersistenceTests.swift` | Adds raw-value, non-default round-trip, and missing-key fallback assertions. | Locks the persistence contract. | Low. |
| `docs/accessibility-plan.md` | Documents that background direction/colour are supplementary and hidden, with static fallbacks. | Keeps accessibility equivalence explicit. | Low. |
| `docs/design-system.md` | Documents the three surfaces, shared active-element layer, ambient direction treatment, and motion behavior. | Aligns implementation and visual contract. | Low. |
| `docs/ux-spec.md` | Adds the Appearance → Table background setting. | Keeps information architecture current. | Low. |

## Deliberately unchanged

```text
WildPairsApp/Views/CardView.swift
WildPairsApp/Views/SoloArtFace.swift
WildPairsApp/Theme/CardSkin.swift
WildPairsApp/Views/HandView.swift
WildPairsApp/ViewModels/GameViewModel.swift
WildPairsApp/WildPairsApp.swift
WildPairsCore/Engine/**
WildPairsCore/Presentation/GameViewState.swift
WildPairsCore/Presentation/GamePresenter.swift
all card and app asset catalogs
WildPairsUITests/**
project.yml
```

The live integration may update tests or project metadata only when the current repository requires it. Any such deviation must be reported and must not alter engine semantics, card design, identifiers, or enterprise constraints.
