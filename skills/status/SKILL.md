---
name: status
description: Read-only report of one task's execution state (`/status TASK-NNN`) or all active tasks (`/status`). Never modifies files or invents state.
---

# Status

Report execution state exactly as recorded in each task's Task Context file. Never modify anything, never invent state.

## Rules

- Read-only. Do not modify any file.
- Read from the task file(s) under the resolved `TASK_CONTEXT_ROOT` (per `rules/core/task-context.md`) — one task with `/status TASK-NNN`, all of them for a bare `/status` (glob for `TASK-*.md`, read each frontmatter). See `rules/core/execution-state.md`.
- If the resolved task root doesn't exist, or has no tasks, say so plainly — don't infer or fabricate a task.
- Report only what's actually recorded. Never guess at a blocker, slice count, or next action that isn't in the file.
- Given `/status TASK-NNN` for an id with no matching task file, say so — don't invent one.
- Keep output minimal — this is a status check, not an analysis.

## Output

### One task
`/status TASK-NNN`, or `/status` when exactly one task exists.
```
<id> — <title>
State: <state>
Current slice: <n/total, or "n/a">
Acceptance: <n>/<m> criteria verified — omit if none recorded
Last action: <omit if not recorded>
Next: <omit if not recorded>
Blocked: <reason, or "no">
```

### Multiple tasks
`/status` with more than one task recorded. One line per task:
```
<id>   <STATE>   <one short qualifier — slice n/total, or blocker — omit if not useful>
```

### No tasks
One line: none recorded, and that persistent tasks start at `/plan`.
