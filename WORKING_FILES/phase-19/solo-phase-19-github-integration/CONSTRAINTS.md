# Constraint checklist

| Constraint | Prepared change |
|---|---|
| Original game; no copied branding, card layout, art, or trade dress | Met. No card renderer, skin, face, back, or asset path is touched. |
| Production cards remain the existing Solo cards | Met. Preview cards are placeholders only and are not an implementation specification. |
| Display names remain Lava, Sky, Grass, Sun | Met. Existing `CardColour.displayName` remains authoritative. |
| Persisted colour cases remain `crimson`, `cobalt`, `jade`, `amber` | Met. No colour enum or save value is changed. |
| Offline and single-device only | Met. Backgrounds are built-in SwiftUI vector surfaces. No import, download, account, or remote service is introduced. |
| No duplicate game state | Met. Views consume existing current colour, direction, phase, timer, score, and seat facts. The only new persistence is an appearance preference. |
| Engine/presenter semantics unchanged | Met. No Engine, `GameViewState`, or `GamePresenter` file is in the patch. |
| Fixed HUD consumes existing facts | Met. No new authoritative turn, timer, score, or current-player store is introduced. |
| Colour does not carry meaning alone | Met. Existing element name/symbol and colour-blind pattern remain; direction retains full text and arrow geometry. |
| Reduced Motion equivalence | Met in source. System Reduce Motion, Solo Reduced visual effects, and Animation speed Off leave a static trace and exact text/state. Runtime verification remains required. |
| VoiceOver | Decorative backgrounds and mirrored visual HUD are hidden. One semantic turn/direction source is intended. Runtime order and identifier audit remains required. |
| Dynamic Type | AX3+ uses existing large human-hand sizes without mutating the saved setting. AX3/AX5 layout verification remains required. |
| iPhone portrait and iPad landscape | Both are represented in the approved state lab. Simulator/device verification remains required. |
| Existing identifiers preserved | No existing identifier is renamed. New identifier: `settings-table-background-picker`. |
| No forbidden capability | No networking, account, currency, IAP, store, social/chat, analytics, GameKit, CloudKit, notification, photo-library, or permission addition. |
| No external dependency | Met. No package, SDK, font, CDN, or network resource is introduced. |
| Later Phase 19 scope not silently pulled in | Met. Stable Face-to-face shelves, causal travel parity, Team Pass privacy, score/rematch, and AI reactions remain deferred. |
