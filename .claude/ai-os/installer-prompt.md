# Installer Prompt

Paste this into a capable model to recreate this operating system's approach for a new
project (or to rebuild it from scratch). It encodes the method, not the Wild Pairs specifics.

---

You are building a personal AI operating system for me from evidence, in this order:

1. **Audit before building.** Inspect the repo (CLAUDE.md-equivalent, docs, git log dates and
   messages), persistent memory, and past-session titles/transcripts. Produce a table of
   workstreams, recurring loops, tools, corrections I've made, and frictions — every row with
   a source and a High/Medium/Low confidence. Where history is thin, say so and plan an
   ingestion step; never compensate by inventing.

2. **Extract the canon into two layers.** Repo-level: one opinionated CLAUDE.md with identity,
   architecture decisions, canonical vocabulary, hard constraints, and quality gates.
   Personal-level: small single-fact memory files (types: user / feedback / project /
   reference), where feedback memories carry the correction plus **Why** and **How to apply**.
   Never store in memory what the repo already records.

3. **Codify only repeated loops as skills.** A loop qualifies after it has happened twice.
   Each SKILL.md gets: trigger-strong frontmatter description (situation, not topic); Purpose;
   When to Invoke; Inputs Required; numbered Steps naming real files and commands; Outputs;
   checkable Acceptance Criteria; Common Pitfalls drawn from actual past mistakes. Explicit
   STOP-for-user checkpoints wherever I've asked for them.

4. **Create agents only for delegable single jobs** with a measurable output (e.g. flaky-test
   hardening in an isolated worktree). Each gets: description frontmatter, When to Use, Remit,
   Out of Scope naming the neighbouring owner, Output Format, Quality Bar. No "assistant" or
   "researcher" agents.

5. **Write a ROUTER.md** mapping request *patterns* to components, with conflict rules (gates
   subsume reviews; hard constraints beat any request; reviews report rather than fix) and a
   default behaviour. Link it from the repo canon so sessions actually load it.

6. **Add the meta kit:** a history-ingestion prompt (source-backed, confidence-marked,
   contradiction-flagging), evaluation checklists for each layer, and this installer.

7. **Quality standard:** every component must be specific enough that a cold model uses it
   correctly, grounded in something that actually happened, and worth its maintenance cost.
   Prefer four sharp skills over ten vague ones. Fact and inference stay separated. When in
   doubt, leave it out and note the candidate in a status memory.

Deliver working files, not descriptions of files.
