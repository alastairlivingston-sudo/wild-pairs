#!/bin/sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PACKAGE_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
PATCH_FILE="$PACKAGE_DIR/patch/solo-table-project-aware-v2.patch"
REPO_DIR=${1:-.}

cd "$REPO_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "error: git is required" >&2
  exit 1
fi

if [ ! -f "$PATCH_FILE" ]; then
  echo "error: patch not found at $PATCH_FILE" >&2
  exit 1
fi

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: target is not a git work tree: $REPO_DIR" >&2
  exit 1
fi

if [ -n "$(git status --porcelain)" ]; then
  echo "error: work tree is not clean; commit or stash changes first" >&2
  exit 1
fi

echo "Checking patch against $(pwd)..."
git apply --check "$PATCH_FILE"

echo "Applying project-aware Solo table redesign..."
git apply "$PATCH_FILE"

echo "Patch applied. Review the diff, build in Xcode, then run the test targets."
