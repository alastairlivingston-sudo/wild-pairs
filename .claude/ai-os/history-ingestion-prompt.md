# History Ingestion Prompt

Use this when returning to a dormant project or feeding exported chats, notes, or docs into
the memory canon. Paste it (or follow it) at the start of the session, pointed at the
material.

---

You are ingesting work history for Alastair to update his persistent memory canon at
`~/.claude/projects/-Users-alastair-dev/memory/`. Read `MEMORY.md` there first — it indexes
what is already known. Known dormant targets (see the `cross-project-index` memory):

- **Budget and Tax Companion** — `~/Library/CloudStorage/OneDrive-Personal/Alastair's
  Documents/Claude/Budget and Tax Companion` (phased build; dormant since 2026-06-22)
- **VIVO Defence Design System** — sibling folder (pptx-from-HTML templates; dormant since
  2026-05-18)

## Rules

1. **Source-backed only.** Every extracted fact cites its file or transcript. Never
   extrapolate a project's goals from its name.
2. **Confidence-mark everything** High / Medium / Low. Low-confidence items go under an
   "Open Questions" heading, not into standing facts.
3. **Mark contradictions explicitly.** If the material contradicts an existing memory, do not
   silently overwrite — present both versions with dates and ask, or mark the memory stale.
4. **Flag staleness.** Convert every relative date to absolute. Anything older than the last
   session in that project is "as of <date>", not present tense.
5. **Extract in this priority order:**
   - repeated *corrections* (things Alastair pushed back on) → feedback memories with
     **Why** and **How to apply**
   - reusable *workflows* (commands that worked, verification recipes, traps hit)
   - project *state* (what is built, what is open, what was decided and why)
   - preferences and vocabulary (naming conventions, tone, formats he chose)
6. **Do not ingest what the artefacts already record.** Code structure, git history, and
   committed docs stay where they are; memory holds only what a fresh session could not
   re-derive from them.
7. **Update, don't duplicate.** One fact per memory file; extend an existing file over
   creating a near-twin; keep `MEMORY.md` to one line per memory.
8. **Revise skills/agents only on evidence.** Propose a new skill only if the material shows
   the same loop happening at least twice. Otherwise note the candidate in the project's
   status memory and move on.

## Output

- New/updated memory files + `MEMORY.md` index lines
- A per-project status summary: what it is, current state, open items, next sensible step
- A short "contradictions and open questions" list for Alastair to resolve
