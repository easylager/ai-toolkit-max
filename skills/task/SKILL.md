---
name: task
description: Create or open a task's persistent Task Context file (`.ai/tasks/TASK-NNN.md` by default, or the configured Obsidian vault) — the entry point when starting from a bare idea or an existing note rather than through /clarify or /plan.
---

# Task

Create or open the Task Context file for a task, outside the `/clarify`/`/plan` flow. Most tasks get a Task Context automatically the first time `/clarify` or `/plan` needs to persist something — this skill is for starting one directly, or resuming one you already have an id or title for.

## Rules

- Find or create the task root (`.ai/tasks/` by default). If ambiguous, ask directly.
- Before creating a task, check for an existing one with the same title/goal — don't create duplicates.
- Creating: allocate next `TASK-NNN` id, write frontmatter (`phase: new`, `status: READY`) and Objective/Scope sections, leave others empty. This is a skeleton, not a full plan.
- Opening: read fresh off disk, report current status/phase, note any blockers.
- Write changes, re-read to confirm before reporting.
- Do not write code or modify other files.

## Output

### Created
```
Task: TASK-NNN — <title>
File: <path>
Status: READY
```
Recommend `/clarify` or `/plan` as the next step.

### Opened
```
Task: TASK-NNN — <title>
File: <path>
Status: <status>
Phase: <phase>
```
One line each for `Blockers` and `Human Overrides` if either is non-empty; otherwise omit.
