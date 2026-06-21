# Project Structure

> Owner: ios-architect | Updated: Phase 0

## Repository Layout

```
WildPairs/                              ← repo root
│
├── CLAUDE.md                           ← project operating manual for Claude Code
├── Package.swift                       ← Swift Package (WildPairsCore + WildPairsTests)
├── WildPairs.xcodeproj/               ← Xcode project (created on Mac in Phase 2)
│
├── WildPairsApp/                       ← Xcode app target source (iOS/iPadOS app)
│   ├── App/
│   │   ├── WildPairsApp.swift          ← @main entry point
│   │   └── AppEnvironment.swift        ← dependency container
│   ├── Views/
│   │   ├── Home/
│   │   ├── Setup/
│   │   ├── Game/
│   │   ├── Rules/
│   │   ├── Settings/
│   │   └── Statistics/
│   ├── ViewModels/
│   │   ├── GameViewModel.swift
│   │   ├── HomeViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── DesignSystem/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   ├── Spacing.swift
│   │   ├── CardView.swift
│   │   └── Tokens.swift
│   ├── Accessibility/
│   │   └── AccessibilityLabels.swift
│   ├── Persistence/
│   │   └── AppPersistence.swift        ← reads/writes game snapshot, settings, stats
│   └── Assets.xcassets/
│
├── WildPairsCore/                      ← Swift Package module (pure logic, no UIKit)
│   ├── Models/
│   │   ├── Card.swift                  ← Card value type
│   │   ├── Deck.swift                  ← Deck creation and shuffling
│   │   ├── Player.swift                ← Player model
│   │   ├── Team.swift                  ← Team model
│   │   ├── GameState.swift             ← Full Codable game snapshot
│   │   ├── GameAction.swift            ← All player/engine actions (enum)
│   │   ├── GameEffect.swift            ← Side effects for ViewModel (enum)
│   │   ├── RuleProfile.swift           ← Per-mode/house-rule configuration
│   │   └── Statistics.swift            ← Local stats model
│   ├── Rules/
│   │   ├── ValidMoveChecker.swift      ← Pure function: is this card playable?
│   │   ├── CardEffectResolver.swift    ← Applies card effects to GameState
│   │   ├── WinConditionChecker.swift   ← Checks all win conditions
│   │   └── RuleProfiles.swift          ← Built-in mode rule profiles
│   ├── Engine/
│   │   ├── GameEngine.swift            ← Pure reducer: (GameState, GameAction) → (GameState, [GameEffect])
│   │   ├── SeededRNG.swift             ← Deterministic random for tests
│   │   └── EventLog.swift              ← Debug event history (debug builds only)
│   ├── AI/
│   │   ├── AIPlayer.swift              ← AI turn decision entry point
│   │   ├── AIObservation.swift         ← Masked view of game state for AI
│   │   ├── MoveScorer.swift            ← Multi-factor move evaluation
│   │   ├── EasyAI.swift                ← Random valid move
│   │   ├── MediumAI.swift              ← Heuristic
│   │   ├── HardAI.swift                ← Scored heuristic
│   │   └── ExpertAI.swift              ← Lookahead simulation
│   ├── Persistence/
│   │   └── GameSnapshot.swift          ← Codable envelope with schema version
│   ├── Simulation/
│   │   └── GameSimulator.swift         ← Runs N games for AI balance testing
│   └── TestingSupport/
│       ├── GameStateBuilder.swift      ← Fluent builder for test game states
│       └── CardFactory.swift           ← Convenience card constructors for tests
│
├── WildPairsTests/                     ← Swift Package test target
│   ├── EngineTests/
│   │   └── GameEngineTests.swift
│   ├── RulesTests/
│   │   ├── ValidMoveTests.swift
│   │   ├── CardEffectTests.swift
│   │   └── WinConditionTests.swift
│   ├── AITests/
│   │   ├── AIObservationTests.swift
│   │   ├── AIFairnessTests.swift
│   │   └── AIValidityTests.swift
│   ├── PersistenceTests/
│   │   └── SnapshotTests.swift
│   └── SimulationTests/
│       └── BalanceSimulationTests.swift
│
├── WildPairsUITests/                   ← Xcode UI test target (created on Mac in Phase 5)
│   ├── GameFlowTests/
│   │   └── GameFlowUITests.swift
│   └── AccessibilitySmokeTests/
│       └── AccessibilitySmokeUITests.swift
│
├── docs/                               ← All project documentation
│   ├── product-spec.md
│   ├── ux-spec.md
│   ├── design-system.md
│   ├── game-rules.md
│   ├── technical-architecture.md
│   ├── state-machine.md
│   ├── ai-strategy.md
│   ├── testing-strategy.md
│   ├── accessibility-plan.md
│   ├── privacy-offline-plan.md
│   ├── permission-audit.md
│   ├── enterprise-build-notes.md
│   ├── release-checklist.md
│   ├── manual-test-scripts.md
│   ├── premortem.md
│   ├── persona-review-log.md
│   ├── promoter-score-review.md
│   ├── known-issues.md
│   ├── ai-balance-report.md
│   └── project-structure.md            ← this file
│
├── scripts/                            ← Quality gate scripts (run on Mac)
│   ├── quality_light.sh
│   ├── quality_full.sh
│   ├── run_unit_tests.sh
│   ├── run_ui_tests.sh
│   ├── run_simulations.sh
│   ├── check_no_network_usage.sh
│   ├── check_permissions_minimal.sh
│   ├── check_project_capabilities.sh
│   └── check_privacy_manifest.sh
│
└── .claude/
    ├── settings.local.json             ← Claude Code permissions + hooks
    ├── agents/                         ← Specialist subagent definitions
    │   ├── product-director.md
    │   ├── ux-lead.md
    │   ├── ios-architect.md
    │   ├── game-engine-engineer.md
    │   ├── ai-gameplay-engineer.md
    │   ├── qa-lead.md
    │   ├── accessibility-lead.md
    │   ├── performance-reliability-lead.md
    │   ├── privacy-brand-safety-lead.md
    │   ├── enterprise-build-lead.md
    │   └── release-manager.md
    └── skills/                         ← Repeatable workflow definitions
        ├── phase-gate/SKILL.md
        ├── ux-review/SKILL.md
        ├── premortem/SKILL.md
        ├── promoter-score-review/SKILL.md
        ├── rules-engine-test-design/SKILL.md
        ├── swiftui-quality-review/SKILL.md
        ├── accessibility-audit/SKILL.md
        ├── ai-balance-review/SKILL.md
        └── enterprise-permission-audit/SKILL.md
```

## Key Design Principles

### Why Swift Package for core engine?
The core game logic (`WildPairsCore`) lives in a Swift Package, not inside the Xcode project. This allows:
- Running `swift test` on macOS without opening Xcode
- Clean module boundary between logic and UI
- Testability without simulator overhead
- Potential future reuse (macOS app, etc.)

### Why no .xcodeproj hand-creation?
Xcode project files (`.pbxproj`) are fragile XML. Creating them by hand leads to build failures. The `.xcodeproj` is created via Xcode's "New Project" wizard on Mac in Phase 2, then the `WildPairsCore` package is added as a local dependency.

### Xcode project creation steps (Phase 2, on Mac)
1. Open Xcode → File → New → Project → iOS → App
2. Product Name: `WildPairs`, Bundle ID: `com.wildpairs.app` (or personal bundle)
3. Interface: SwiftUI, Language: Swift, tick iPhone + iPad
4. Save to the `WildPairs/` directory
5. File → Add Package Dependencies → Add Local → select `WildPairs/` (Package.swift)
6. Add `WildPairsCore` library to the `WildPairs` app target
7. Set Deployment Target: iOS 17.0
8. Device Family: iPhone + iPad (Universal)
9. Remove unnecessary capabilities from Signing & Capabilities
