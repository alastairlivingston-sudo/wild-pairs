#!/bin/sh
# Phase 17 E1 — build the app's card-art catalogue from the supplied asset pack.
#
# The raw pack (docs/solo_swiftui_asset_pack.zip, 192 MB, gitignored) holds 75 pre-rendered
# 900x1350 card masters in a SoloCards.xcassets. That's far larger than any on-screen card
# (~136x204pt), so this script extracts the catalogue and downscales every master to 500x750
# (~@3x of the largest card) into WildPairsApp/SoloCards.xcassets, which xcodegen then compiles
# into the app. The zip stays on disk as the full-resolution master archive.
#
# Run on macOS with Xcode command-line tools (uses sips). Idempotent: rebuilds the catalogue.
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIP="$ROOT/docs/solo_swiftui_asset_pack.zip"
DEST="$ROOT/WildPairsApp/SoloCards.xcassets"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -f "$ZIP" ] || { echo "error: $ZIP not found"; exit 1; }

echo "Extracting SoloCards.xcassets from the pack…"
unzip -oq "$ZIP" "solo_swiftui_asset_pack/SoloCards.xcassets/*" -d "$TMP"

rm -rf "$DEST"
mv "$TMP/solo_swiftui_asset_pack/SoloCards.xcassets" "$DEST"

echo "Downscaling masters to 500x750…"
count=0
find "$DEST" -name "*.png" | while read -r png; do
    sips -Z 750 "$png" >/dev/null 2>&1
    count=$((count + 1))
done
pngs=$(find "$DEST" -name "*.png" | wc -l | tr -d ' ')

echo "Done: $pngs card images in $DEST"
du -sh "$DEST"
