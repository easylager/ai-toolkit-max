---
name: execute
description: Autonomous orchestration entry point — runs the adaptive skill chain (clarify → design/creative-explore → plan → estimate → implement → verify → design-review → review, as applicable) end to end within one invocation, checkpointing to the task's Task Context after every phase, and stopping only at a Human Gate, a blocker, a loop-detection limit, or COMPLETE. `/execute` or `/execute TASK-NNN` resumes a task from persisted state — it never restarts a workflow already in progress. Runs autonomously within an invocation, not as an unattended background process — resuming after a closed session means re-invoking it, not waiting for it.
---

# Execute

Run a task's adaptive workflow chain automatically, phase by phase, within this conversation — instead of the user invoking `/clarify`, `/design`, `/plan`, `/next`, `/verify`, and so on by hand at each step. This is a driver for the existing skills, not a replacement for them: every phase still follows that skill's own rules and output format verbatim. `/execute` decides when to run which one, checkpoints between them, and knows when to stop — see `rules/core/execution-state.md`'s Autonomy and Loop detection sections for the policy this follows.

## Which task

Optionally takes a `TASK-NNN` argument, same resolution as `/next`/`/status`:

- Given `TASK-NNN`, resume that task from its persisted state.
- Given a bare description with no existing task, bootstrap one the same way `/task` would (allocate the id, write Objective/Scope from what's given), then continue.
- Without an argument: exactly one active task → use it. More than one → list them briefly and ask which. None, and no description given → say so and ask what to work on.

## Rules

### Startup (every invocation)
- Reconcile first: re-read the task file fresh off disk (`rules/core/task-context.md`), inspect the actual repo state, and trust the repo over a stale file — this is what makes resuming after an interrupted session, a closed terminal, or a fresh session safe. Never assume this conversation's history matches the file.
- If reconciliation finds material drift (`skills/reconcile/SKILL.md`'s criteria), handle it before continuing — don't execute on top of a stale plan or stale acceptance criteria.
- Determine the workflow chain for this task using the same reasoning `/classify` applies — once at the start, and again only if `REPLAN_REQUIRED` or reconciled drift changes what the task actually needs.

### Orchestration loop
- Determine the current phase from the task's `phase`/`status` fields, then perform that phase's work by following the corresponding skill's own rules and output exactly (`/clarify`, `/design`, `/creative-explore`, `/plan`, `/estimate`, `/next`'s READY dispatch plus the implementation itself, `/verify`, `/design-review`, `/review`) — do not reinvent or shortcut a skill's own logic here.
- After each phase, checkpoint the task file per that skill's own write-ownership rules (`rules/core/task-context.md`), then re-evaluate: continue directly to the next phase in the same turn if the Autonomy policy allows it, or stop at a Human Gate if it doesn't.
- Only run phases the chosen chain actually calls for — a backend-only task never touches `design`/`creative-explore`/`design-review`; a small UI tweak skips `creative-explore` even though `design` runs; a trivial task skips straight to `implement → verify`.
- A `RECOVERABLE` verification failure routes through `/debug` → `/verify` automatically, per the existing Autonomy policy — not a Human Gate.
- A `REPLAN_REQUIRED` state always stops — re-enter through `/plan` → `/estimate`, report why, and wait.

### Human Gates
Exactly the four defined in `rules/core/execution-state.md` — Requirements, Creative Approval, High-risk action, Final review. Never invent additional ones, never skip these. None of them are new state values — a Human Gate is always `status: BLOCKED` (or `DRAFT`, for Creative Approval) with the specific reason recorded in `Blockers` or the relevant skill's own status field.

### Loop detection
Per `rules/core/execution-state.md`'s Loop detection section: the same phase failing with the same signature for `max_verify_iterations` consecutive attempts (`.ai/config`, default 3) stops execution and reports as `BLOCKED` rather than retrying indefinitely.

### Reporting
- Give concise, checklist-style progress (✓ per completed phase), not a transcript of internal reasoning. State the current stage and, if one applies, the next Human Gate — don't narrate every read/tool call.
- On stopping for any reason (gate, blocker, loop limit, or COMPLETE), give the full picture: state, what's done, what's next, and exactly what's needed to continue.
- Resuming (`/execute TASK-NNN` after a gate was cleared) picks up silently from the checkpointed state — don't replay everything that already happened before this invocation.

## Output

### Started / Resumed
```
Task: <id> — <title>
Mode: AUTONOMOUS
Chain: <the decided workflow chain>
Human gates in this chain: <which of Requirements/Creative Approval/High-risk/Final review apply — omit any that don't>
Current stage: <phase>
```
Then proceed directly into execution — don't wait for acknowledgment.

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
