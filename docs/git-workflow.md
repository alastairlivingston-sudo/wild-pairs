# Wild Pairs — Git Workflow

> Last updated: 2026-06-21  
> Replaces: OneDrive as the source-sync mechanism between Windows and Mac.

---

## Overview

GitHub (`https://github.com/alastairlivingston-sudo/wild-pairs.git`) is the single source of truth for Wild Pairs source code.

| Machine | Role |
|---|---|
| Windows (Claude Code) | Editing — Swift sources, docs, scripts |
| Mac (Xcode) | Validation — `swift build`, `swift test`, simulator builds |

**OneDrive must not be used for active source-code syncing.** OneDrive conflict copies, casing differences, and line-ending transformations have caused issues during Phase 1. All sync now goes through git.

---

## Branch Strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, phase-gated snapshots |
| `phase-2-core-engine` | Active development branch for Phase 2 |
| `phase-N-*` | One branch per phase, created at phase start |

Pull requests from a phase branch → `main` are created when the phase gate passes.

---

## Daily Workflow

### Before starting work (either machine)

```bash
git pull --ff-only
```

Fast-forward only — this will fail if there are unpushed local commits, which is the right behaviour. Resolve divergence consciously; never force-merge.

### After each small successful batch

```bash
git add <changed files>
git commit -m "short description of what and why"
git push
```

Commit after each logical unit of work, not at end of day. Small commits make Mac validation easier to bisect.

### On Mac after pulling

```bash
swift build
./scripts/swift_test.sh   # portable wrapper; see note below
```

If either fails, fix on Windows (or directly on Mac for trivial typos), commit, push, and re-pull on the other machine.

> **Why the wrapper (KI-028):** `WildPairsTests` uses Swift Testing (`import Testing`). On a Command-Line-Tools-only Mac, a bare `swift test` fails with `no such module 'Testing'` because the Testing framework is not on the default dyld search paths. `scripts/swift_test.sh` fixes this by deriving the paths from `xcode-select -p`, and also works once full Xcode is installed. See `enterprise-build-notes.md` §6 and `testing-strategy.md` §9.

---

## First-Time Mac Setup

```bash
git clone https://github.com/alastairlivingston-sudo/wild-pairs.git WildPairs
cd WildPairs
swift build
```

No OneDrive copy is needed. The clone is the authoritative working copy on Mac.

If a Mac working copy already exists from OneDrive:

```bash
cd ~/Developer/WildPairs          # or wherever it lives
git remote -v                     # check whether origin is already set
git remote add origin https://github.com/alastairlivingston-sudo/wild-pairs.git
git fetch origin
git checkout -B main origin/main  # reset local main to match remote
```

---

## Active Phase 2 Work

All Phase 2 code is written on the `phase-2-core-engine` branch.

```bash
git checkout phase-2-core-engine
```

Do not commit Phase 2 code directly to `main`. When the Phase 2 gate passes, open a PR from `phase-2-core-engine` → `main`.

---

## What Not to Do

| Action | Why not |
|---|---|
| Edit files directly in OneDrive without committing | Changes can be lost to conflict copies or overwritten by the other machine |
| `git push --force` | Overwrites remote history; banned in this project |
| Committing `.build/`, `DerivedData/`, `*.xcuserstate` | These are in `.gitignore`; they are machine-specific |
| Committing credentials, `.env`, `*.p12`, `*.pem` | These are in `.gitignore`; never commit secrets |
| Resolving a merge conflict by picking "mine" blindly | Read both sides before resolving |
