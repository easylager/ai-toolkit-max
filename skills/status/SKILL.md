---
name: status
description: Read-only report of one task's execution state (`/status TASK-NNN`) or all active tasks (`/status`). Never modifies files or invents state.
---

# Status

Report execution state exactly as recorded in each task's Task Context file. Never modify anything, never invent state.

## Rules

- Read-only. Just read and report, no changes.
- Read task files from `.ai/tasks/` (or resolved root). One task: `/status TASK-NNN`. All tasks: bare `/status`.
- Report only what's in the file: status, phase, current slice, criteria verified, blockers.
- If task root doesn't exist or is empty, say so.
- Keep output short — this is a status check, not analysis.

## Output

### One task
`/status TASK-NNN`, or `/status` when exactly one task exists.
```
Task: <id> — <title>
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
