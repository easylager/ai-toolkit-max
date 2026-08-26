---
name: task
description: Create or open a task's persistent Task Context file (`.ai/tasks/TASK-NNN.md` by default, or the configured Obsidian vault) — the entry point when starting from a bare idea or an existing note rather than through /clarify or /plan.
---

# Task

Create or open the Task Context file for a task, outside the `/clarify`/`/plan` flow. Most tasks get a Task Context automatically the first time `/clarify` or `/plan` needs to persist something — this skill is for starting one directly, or resuming one you already have an id or title for.

## Rules

- Resolve the task root per `rules/core/task-context.md` (`TASK_CONTEXT_ROOT` → `.ai/config` → default `.ai/tasks/`), creating the directory if it doesn't exist yet. If resolution is genuinely ambiguous (e.g. more than one plausible project/root), ask the human directly which one — do not search the filesystem or the repository for evidence to disambiguate.
- Before creating a new task, check for an existing one covering the same request: a title/objective similarity scan over the resolved task root's `TASK-*.md` files only — never a broader filesystem search, never a spawned subagent, never source-code investigation. Open the existing one instead of creating a duplicate; ask if genuinely ambiguous.
- This is a Control Plane operation per `rules/core/lifecycle-planes.md`: a single mechanical read-and-write turn. No repository investigation beyond the checks above, no spawning subagents/background agents, no invoking the Supervisor decision model.
- Creating a task: allocate the next sequential `TASK-NNN` id, write the frontmatter and `## Objective`/`## Scope` from what's given, leave every other section empty rather than inventing content — this is a skeleton, not a substitute for `/clarify`. Append a `TASK_CREATED` `Execution History` event (`rules/core/execution-state.md`'s Execution History format) as part of this same write.
- Opening a task: read it fresh off disk and summarize its current `status`, `phase`, and any `Blockers`/`Human Overrides` — don't restate the whole file.
- Do not modify any file other than the task file being created/opened.
- Do not write implementation code.

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
