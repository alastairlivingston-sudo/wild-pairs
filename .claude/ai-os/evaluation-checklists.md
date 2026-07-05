# Evaluation Checklists

Score 1–10 per item; anything under 7 gets fixed or the component gets pruned. Run when
adding a component, when one misfires, and at release-phase gates.

## 1. Skills (`.claude/skills/*/SKILL.md`)

- [ ] **Triggering:** the frontmatter description alone tells a model when to invoke — includes
      the situation, not just the topic
- [ ] **Specificity:** steps name real files, commands, and precedents from this repo, not
      generic advice
- [ ] **Evidence:** the loop it codifies has actually happened ≥2 times (cite commits/sessions)
- [ ] **Checkpoints:** every stop-for-user moment is explicit (form-factor confirms, direction
      picks)
- [ ] **Evaluability:** acceptance criteria are checkable, not vibes ("regression test fails on
      old code")
- [ ] **Pitfalls are paid-for:** each Common Pitfall traces to a real past mistake
- [ ] **No overlap:** doesn't duplicate another skill's job; hands off by name where adjacent

## 2. Agents (`.claude/agents/*.md`)

- [ ] **Mission is one job:** could fail or succeed measurably on a single task
- [ ] **Remit vs Out of Scope:** boundaries name the neighbouring owner (per CLAUDE.md table)
- [ ] **Autonomy-safe:** operating rules prevent the known failure (e.g. flake-hardener may not
      weaken assertions or change product behaviour)
- [ ] **Output format specified** concretely enough to diff two runs
- [ ] **Escalation:** states when to stop and ask vs proceed
- [ ] **Quality bar:** mechanism-level, not effort-level ("root cause as mechanism, demonstrated")

## 3. Router (`.claude/ROUTER.md`)

- [ ] Every skill and agent appears in at least one row
- [ ] Rows are request-*patterns* (what a user actually says), not component names restated
- [ ] Conflict rules resolve the real collisions (gate vs reviews; constraint vs request)
- [ ] Default behaviour defined; no row routes to something that doesn't exist
- [ ] A cold model given only ROUTER.md + CLAUDE.md picks the same component a warm one would

## 4. Memory Canon (`~/.claude/.../memory/`)

- [ ] One fact per file; description line alone is enough to judge relevance
- [ ] Nothing duplicates what git/CLAUDE.md/docs already record
- [ ] Feedback memories carry **Why** and **How to apply**
- [ ] No dangling `[[links]]` older than one session; no stale claims (file paths, flags verified)
- [ ] `MEMORY.md` has exactly one line per memory and no content of its own
- [ ] Dates absolute; dormant-project facts marked "as of <date>"

## 5. Overall System

- [ ] A fresh session handled a real task end-to-end using only canon + router + skills, without
      recap questions — test this occasionally on purpose
- [ ] No component unused for two consecutive phases (prune or merge)
- [ ] Every user correction this phase ended up in a memory or a skill pitfall — none live only
      in a transcript
- [ ] The system stayed smaller than the work it saves
