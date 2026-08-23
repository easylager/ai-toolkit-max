---
name: execute
description: Autonomous orchestration entry point — a state-driven Supervisor (rules/core/execution-state.md's Supervisor decision model) that re-evaluates the current Task Context at every phase boundary and picks exactly one next action from clarify/design/creative-explore/plan/estimate/implement/verify/design-review/review, never a precomputed chain. Checkpoints after every phase and stops only at a Human Gate, a blocker, a loop-detection limit, or COMPLETE. `/execute` or `/execute TASK-NNN` resumes a task from persisted state — it never restarts a workflow already in progress. Runs autonomously within an invocation, not as an unattended background process — resuming after a closed session means re-invoking it, not waiting for it.
---

# Execute

Run a task's next phase automatically, one decision at a time, within this conversation — instead of the user invoking `/clarify`, `/design`, `/plan`, `/next`, `/verify`, and so on by hand at each step. This is a driver for the existing skills, not a replacement for them: every phase still follows that skill's own rules and output format verbatim. `/execute` never decides the whole path up front — it re-evaluates the current Task Context after every phase and picks exactly one next action, per `rules/core/execution-state.md`'s Supervisor decision model (which also carries the Autonomy and Loop detection policy this follows).

## Which task

Optionally takes a `TASK-NNN` argument, same resolution as `/next`/`/status`:

- Given `TASK-NNN`, resume that task from its persisted state.
- Given a bare description with no existing task, bootstrap one the same way `/task` would (allocate the id, write Objective/Scope from what's given), then continue.
- Without an argument: exactly one active task → use it. More than one → list them briefly and ask which. None, and no description given → say so and ask what to work on.

## Rules

### Startup (every invocation)
- Reconcile first: re-read the task file fresh off disk (`rules/core/task-context.md`), inspect the actual repo state, and trust the repo over a stale file — this is what makes resuming after an interrupted session, a closed terminal, or a fresh session safe. Never assume this conversation's history matches the file.
- If reconciliation finds material drift (`skills/reconcile/SKILL.md`'s criteria), handle it before continuing — don't execute on top of a stale plan or stale acceptance criteria.

### Supervisor decision loop
Follow `rules/core/execution-state.md`'s Supervisor decision model exactly — this section is a pointer to it, not a second copy of it.

- **Never precompute a phase list.** There is no chain to "walk." At every boundary — including the very first — make one decision from the current state (the Inputs in the Supervisor decision model: phase/status, requirements, Acceptance Criteria, what's actually persisted vs. only discussed, test strategy, evidence, human context since the last decision, blockers, repo state, Execution History) and select exactly one of `EXECUTE` / `ASK_HUMAN` / `RETRY` / `REPLAN` / `STOP` / `COMPLETE`.
- On `EXECUTE`, perform exactly one phase/action by following the corresponding skill's own rules and output exactly (`/clarify`, `/design`, `/creative-explore`, `/plan`, `/estimate`, `/next`'s READY dispatch plus the implementation itself, `/verify`, `/design-review`, `/review`) — do not reinvent or shortcut a skill's own logic here, and never assume what the next `EXECUTE` will be before this one finishes.
- Persist that phase's output per the Phase completion table before deciding again — a phase that only happened in conversation isn't done. For `design-review` and `review` specifically, since neither writes the task file itself, record their outcome as an Execution History entry on their behalf.
- A human message since the last decision — including a mid-run correction like "actually, use a light background" — is itself an input to the next decision, not something queued behind whatever was already in flight. Re-derive the next action with it factored in; never finish executing a direction a human just changed.
- For a UI-facing task, run the Visual loop from the Supervisor decision model (`implement → design-review → PASS/FAIL → fix → design-review`) as its own decision cycle, not folded silently into code `/verify`.
- `RETRY` (a `RECOVERABLE` failure, code or visual) routes through `/debug` or a fix and back through verification automatically — not a Human Gate.
- `REPLAN` always stops — re-enter through `/plan` → `/estimate`, report why, and wait.

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
Current stage: <phase>
Supervisor decision: EXECUTE — <the one next action, not a plan beyond it>
```
Then proceed directly into execution — don't wait for acknowledgment. Never list a multi-step chain here; only the single decision just made.

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
