#!/bin/sh
set -eu

REPO_DIR=${1:-.}
cd "$REPO_DIR"

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

for file in \
  WildPairsApp/Views/GameTableView.swift \
  WildPairsApp/Views/TableCenterView.swift \
  WildPairsApp/Views/PlayerZoneView.swift \
  WildPairsApp/Views/CardView.swift \
  WildPairsApp/ViewModels/GameViewModel.swift \
  WildPairsApp/Theme/TableBackground.swift \
  WildPairsApp/Theme/Theme.swift \
  WildPairsCore/Presentation/GameViewState.swift; do
  [ -f "$file" ] || fail "missing $file"
done

for asset in \
  solo_table_card_back \
  solo_table_direction_ring_clockwise \
  solo_table_crest_lava \
  solo_table_crest_sky \
  solo_table_crest_grass \
  solo_table_crest_sun; do
  [ -d "WildPairsApp/SoloCards.xcassets/$asset.imageset" ] || fail "missing asset $asset"
done

grep -q 'accessibilityIdentifier("game-turn-rail")' WildPairsApp/Views/GameTableView.swift || fail "turn rail identifier missing"
grep -q 'accessibilityIdentifier("game-solo-button")' WildPairsApp/Views/GameTableView.swift || fail "Solo identifier missing"
grep -q 'accessibilityIdentifier("game-draw-card-button")' WildPairsApp/Views/TableCenterView.swift || fail "draw identifier missing"
grep -q 'reportTableAnchor(.drawPile' WildPairsApp/Views/TableCenterView.swift || fail "draw anchor missing"
grep -q 'reportTableAnchor(.discard' WildPairsApp/Views/TableCenterView.swift || fail "discard anchor missing"
grep -q 'return "Lava"' WildPairsCore/Presentation/GameViewState.swift || fail "Lava display name missing"
grep -q 'return "Sky"' WildPairsCore/Presentation/GameViewState.swift || fail "Sky display name missing"
grep -q 'return "Grass"' WildPairsCore/Presentation/GameViewState.swift || fail "Grass display name missing"
grep -q 'return "Sun"' WildPairsCore/Presentation/GameViewState.swift || fail "Sun display name missing"

if command -v swiftc >/dev/null 2>&1; then
  echo "Running syntax parse checks..."
  for file in \
    WildPairsApp/Views/GameTableView.swift \
    WildPairsApp/Views/TableCenterView.swift \
    WildPairsApp/Views/PlayerZoneView.swift \
    WildPairsApp/Views/CardView.swift \
    WildPairsApp/ViewModels/GameViewModel.swift \
    WildPairsApp/Theme/TableBackground.swift \
    WildPairsApp/Theme/Theme.swift \
    WildPairsCore/Presentation/GameViewState.swift; do
    swiftc -frontend -parse "$file"
  done
else
  echo "swiftc not found; skipping syntax parse"
fi

echo "Static Solo table integration checks passed. Xcode build and UI tests are still required."
