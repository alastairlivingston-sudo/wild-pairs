# Stage 3 — Play choreography (the "after")

Real captured frames of the Phase 17 Stage 3 table-legibility redesign in motion — the
counterpart to `../current-ux/` (the "before"). Captured on iPhone 17 simulator via the
`WildPairsScreenshotCapture.testCaptureStage3Motion` harness (passive burst-capture during AI
turns, since an XCUITest interaction auto-waits animations out).

| Frame | Shows |
|---|---|
| `01-handoff-spotlight-arriving.png` | Turn hand-off: the Left Opponent seat lighting up (glow + thinking dots) as the turn arrives (Stage 3.3). |
| `02-played-card-in-flight.png` | A played wild card mid-flight from the Left Opponent's seat across the table to the discard (Stage 3.1); the seat is ringed by the active-turn spotlight. |
| `03-active-seat-tinted-to-scene.png` | A red "2" settling on the discard while the Right Opponent seat glows **orange** — the active-seat spotlight follows the current-colour scene (now Fire). |
| `04-resolved-wild-colour-chip.png` | The resolved wild on the discard carries a red colour chip (the image-skin's chosen-colour marker), and the whole scene has re-tinted blue→red as the colour changed. |

Not separately frozen here but built and verified in the same run: the count-scaled draw travel
(Stage 3.5, card-backs flying draw-pile→hand, staggered by count) and the "Reversed!" direction
flash (Stage 3.4). Draw travel reuses the identical table-anchor system proven by frames 01–02.
