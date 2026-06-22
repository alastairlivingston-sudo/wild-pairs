#!/usr/bin/env bash
# Run on Mac. Works with full Xcode OR Command Line Tools only.
# Usage: bash scripts/swift_test.sh [extra swift-test args, e.g. --filter EngineTests]
#
# Why this wrapper exists (KI-028):
# WildPairsTests uses the Swift Testing framework (`import Testing`). On a machine
# with only the Command Line Tools (no Xcode.app), `swift test` cannot find
# Testing.framework or lib_TestingInterop.dylib at runtime, because they live under
# the active developer dir and are not on the default dyld search paths. This script
# adds the framework search path and the two runtime rpaths derived from
# `xcode-select -p`. With full Xcode installed, the flags are harmless and bare
# `swift test` also works.
# Exit 0 = PASS. Non-zero = build error or test failure.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DEV="$(xcode-select -p)"
FW="$DEV/Library/Developer/Frameworks"
LIB="$DEV/Library/Developer/usr/lib"

EXTRA=()
if [ -d "$FW/Testing.framework" ]; then
    EXTRA+=( -Xswiftc -F -Xswiftc "$FW" -Xlinker -rpath -Xlinker "$FW" )
    [ -d "$LIB" ] && EXTRA+=( -Xlinker -rpath -Xlinker "$LIB" )
fi

if [ "${#EXTRA[@]}" -gt 0 ]; then
    exec swift test --package-path "$PROJECT_ROOT" "${EXTRA[@]}" "$@"
else
    exec swift test --package-path "$PROJECT_ROOT" "$@"
fi
