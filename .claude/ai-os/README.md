# AI Operating System — Meta Kit

The Wild Pairs repo doubles as Alastair's AI-staffed studio. The working parts live elsewhere:

| Layer | Location |
|---|---|
| Project canon | `CLAUDE.md` (repo root) |
| Personal canon | `~/.claude/projects/-Users-alastair-dev/memory/` (indexed by `MEMORY.md`) |
| Router | `.claude/ROUTER.md` |
| Skills (13) | `.claude/skills/*/SKILL.md` |
| Agents (12) | `.claude/agents/*.md` |

This directory holds the meta layer — prompts and checklists for maintaining and reproducing
the system itself:

- `history-ingestion-prompt.md` — run when returning to a dormant project (Budget & Tax
  Companion, VIVO) or feeding new material into memory
- `evaluation-checklists.md` — score any skill, agent, the router, or the canon before
  trusting or extending it
- `installer-prompt.md` — compact prompt to recreate this system's approach for a new
  project or a fresh model

Maintenance rules: extend by evidence, not by ambition — a new skill needs a loop that has
already repeated at least twice. Prune anything not invoked for two phases. Memory hygiene
runs through the harness `/consolidate-memory` skill, not by hand.
