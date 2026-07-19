# Hand-back protocol — ChatGPT → Claude Code (Phase 19)

This is the contract for what ChatGPT must output at the end of a Phase 19 UX task
so **Claude Code** can integrate it cleanly, build/test on simulators, and push to
GitHub. It mirrors the proven Phase 18 loop (`WORKING_FILES/`), scoped to UX.

ChatGPT cannot build Xcode or run tests — so its deliverable is *correct,
project-aware code* plus enough context for Claude Code to verify and merge without
re-deriving intent.

## What ChatGPT delivers per accepted change set

Ask ChatGPT (in the project) to produce a **hand-off package** with these parts:

1. **CHANGELOG** — a table: file · what changed · why · risk. One row per touched file.
   List files deliberately *not* changed when it prevents confusion.
2. **The code**, in whichever form applies:
   - **Full replacement files** at real repo paths (preferred for a file ChatGPT
     rewrote substantially), OR
   - **A unified diff / `git apply`-able patch** for smaller edits. No `…` elisions
     inside applied code.
   - New assets described by name + spec (ChatGPT can't emit binary PNGs reliably);
     if art is needed, it says exactly which imageset name and size, and Claude Code
     or the user provides the actual PNG.
3. **HTML preview** — the self-contained `.html` used to sign off the look.
4. **Constraint checklist** — ChatGPT confirms, per change: internal colour cases
   untouched; no networking/IAP/GameKit/etc.; no duplicated game state; Reduced Motion
   fallback present; VoiceOver labels/order preserved; accessibility identifiers
   unchanged; iPhone-portrait + iPad-landscape considered.
5. **Verification asks** — the exact things Claude Code must build/run/screenshot,
   since ChatGPT couldn't.

## How you (the user) move it to Claude Code

Two ways — pick one:

**A. Paste (simplest for small changes).** Copy the CHANGELOG + code blocks into a
Claude Code session on branch `claude/phase-19-chatgpt-setup-evm8ms` (or the Phase 19
branch in use) and say: *"Integrate this Phase 19 UX change, following
docs/phase-19-chatgpt/HANDBACK_PROTOCOL.md. Verify then push."*

**B. Drop files into the repo (best for multi-file changes).** Save ChatGPT's
package under `WORKING_FILES/phase-19/` (patch + any full files + the HTML preview +
CHANGELOG), commit nothing yet, and tell Claude Code to integrate from there.

## What Claude Code does on receipt (its side of the contract)

1. Inspect the current repo; compare each target file with ChatGPT's version.
   Where the live file has moved on, **semantic-merge** — don't blindly overwrite.
2. Apply the change, keeping engine/view-model state authoritative and all existing
   accessibility identifiers and rule feedback intact.
3. Build the iOS 17 target; run unit tests and `WildPairsUITests`.
4. Run the visual/accessibility matrix (`/simulator-verify`, `/accessibility-audit`,
   `/swiftui-quality-review` as appropriate): local/partner/left/right turn,
   clockwise/counter-clockwise, Lava/Sky/Grass/Sun, Solo normal/urgent/called/caught,
   iPhone 375 pt + iPad landscape, default + AX Dynamic Type, VoiceOver, Reduce Motion.
5. Report a file-by-file changelog, build/test results, screenshots, deviations, and
   remaining risks. Stop and ask if a treatment would require changing engine
   semantics — it will not silently rewrite game logic.
6. Commit with a clear message and push to the Phase 19 branch. **No pull request
   unless you explicitly ask for one.**

## Anti-patterns Claude Code will reject
- A second table/UI system or a parallel view model instead of evolving the existing
  views in place.
- Renamed Codable/save values or accessibility identifiers.
- Any networking/account/currency/IAP/GameKit/analytics addition.
- Decorative controls that imply behaviour they don't have (e.g. fake quick-chat that
  doesn't affect AI — see `WORKING_FILES/docs/QUICK_CHAT_DECISION.md`).
- A "10/10 / it builds" claim from ChatGPT, which cannot compile the project.
