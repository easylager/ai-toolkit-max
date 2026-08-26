---
name: execute
description: Orchestration entry point — state-driven Supervisor (`rules/core/execution-state-supervisor.md`) that re-evaluates Task Context at every phase boundary and picks exactly one next action. Checkpoints after every phase. `/execute TASK-NNN` resumes from persisted state. See `rules/core/common-rules.md` for output format.
---

# Execute

Run a task's next phase automatically — a driver for existing skills, not a replacement. Every phase follows that skill's rules. Re-evaluates after every phase per `rules/core/execution-state-supervisor.md`. Load task context via `rules/core/context-pack.md`.

## Which task

Optionally takes a `TASK-NNN` argument, same resolution as `/next`/`/status`:

- Given `TASK-NNN`, resume that task from its persisted state.
- Given a bare description with no existing task, bootstrap one the same way `/task` would (allocate the id, write Objective/Scope from what's given), then continue.
- Without an argument: exactly one active task → use it. More than one → list them briefly and ask which. None, and no description given → say so and ask what to work on.

## Rules

### Startup (every invocation)
- Reconcile first per `rules/core/common-rules.md` — load compact context per `rules/core/context-pack.md`, then inspect repo state.
- If reconciliation finds material drift (`skills/reconcile/SKILL.md`), handle before continuing.
- Read `execution_mode` from frontmatter. `MANUAL` → say so, point at individual skills. `SUPERVISED`/`AUTONOMOUS` per supervisor model.

### Supervisor decision loop
Follow `rules/core/execution-state-supervisor.md` exactly.

- Never precompute a phase list. One decision per boundary from current state.
- On `EXECUTE`, run exactly one phase via the corresponding skill's rules.
- Persist output per Phase completion table before deciding again.
- `SUPERVISED`: stop after each persisted phase (except RETRY sub-loops within one phase).
- Human corrections since last decision are inputs to the next decision.
- Visual loop for UI tasks: implement → design-review → fix if FAIL.
- `REPLAN` always stops.

### Human Gates
Four gates per `rules/core/execution-state.md` Autonomy section. Append `HUMAN_GATE`/`HUMAN_DECISION` events.

### Loop detection
Per `rules/core/execution-state.md` Loop detection section.

### Reporting
Per `rules/core/common-rules.md` output brevity rules. Checklist progress (✓ per phase), not transcripts.

## Output

### Started / Resumed
```
Task: <id> — <title>
Mode: AUTONOMOUS | SUPERVISED  (from execution_mode; AUTONOMOUS if unset)
Current stage: <phase>
Supervisor decision: EXECUTE — <the one next action, not a plan beyond it>
```
Then proceed directly into execution — don't wait for acknowledgment. Never list a multi-step chain here; only the single decision just made.

### Paused (SUPERVISED)
```
Task: <id> — <title>
Mode: SUPERVISED
✓ <phase just completed> — <one line result>
Current: <phase>
Next Supervisor decision (pending): <what it will be, so the user knows what continuing means>
```
Reply, or re-invoke `/execute TASK-NNN`, to continue. This is not a Human Gate — nothing is blocked, no decision is needed beyond "go ahead" — it's a pacing pause, distinct from the Human Gate format below.

### Progress (between gates)
```
✓ <phase> — <one line result>
✓ <phase> — <one line result>
...
Current: <phase>
Next human checkpoint: <gate name, or "none — running to completion">
```

### Stopped at a Human Gate / Blocker / Loop limit
State exactly which one, in that gate's own format (Requirements' questions, Creative Approval's recommendation per `skills/design/SKILL.md`'s Output, the high-risk action's description and blast radius, or the loop's attempted/failed/needed summary). End with what response continues execution.

### COMPLETE
```
Task: <id> — <title>
State: COMPLETE
Acceptance: <n>/<n> criteria verified
Review: <no open Critical/High findings>
Design review: <assessment, or "n/a — not a UI-facing task">
```
