---
name: next
description: State-driven execution dispatcher for a task (optionally `/next TASK-NNN`). Inspects that task's plan, slice map, and state, plus the repo, to decide the single next action and routes automatically through verification, recoverable failures, and blockers. Reports READY, VERIFYING, BLOCKED, RECOVERABLE, REPLAN_REQUIRED, or COMPLETE.
---

# Next

Decide the single next action for one task, using the canonical execution states below. Not the next plan item — the next safe, minimal step given what's actually true right now.

## Which task

`/next` optionally takes a `TASK-NNN` argument. Without one:

- Exactly one active task (state not `COMPLETE`) in `.ai/state.md` → use it.
- More than one active task → list them briefly (id, title, state) and ask which one, rather than guessing.
- No tasks at all → say so plainly and recommend `/plan`.

Given `/next TASK-NNN` for an id that doesn't exist in `.ai/state.md`, say so — don't invent one.

## States

- **READY** — a slice is ready to execute.
- **VERIFYING** — a slice is implemented and needs `/verify`.
- **BLOCKED** — execution needs something external: credentials, tool/MCP access, an external API, infrastructure, or a user decision. Never resolvable by Claude alone.
- **RECOVERABLE** — verification failed for a local, understandable reason (failing test, wrong implementation, type error, integration mistake, straightforward regression). Routes to `/debug` → `/verify` → READY, normally without asking the user first.
- **REPLAN_REQUIRED** — the failure or new information invalidates an assumption in the approved plan (wrong architecture, a dependency behaving differently than assumed, a "local" change turning out to be cross-service, a slice fundamentally bigger/different than estimated, a needed capability that doesn't exist). Routes to `/plan` → `/estimate` → READY. Always stop and tell the user — never patch around an invalidated plan.
- **COMPLETE** — all slices implemented and verified. Recommend final `/verify` and `/review`; don't generate further work.

EXECUTING (actually implementing a slice) is not a state `next` reports — it's the runtime interval between a READY dispatch and its checkpoint. If `.ai/state.md` shows a slice still EXECUTING (e.g., resumed after an interrupted session), don't trust it — re-derive status from the repo.

## Rules

- Do not modify files except `.ai/state.md` (and `.ai/plan.md`, only to annotate or reorder slices during execution — the initial slice map itself comes from `/estimate`). See `rules/core/execution-state.md`.
- Do not write implementation code and do not run verification yourself — recommend `/verify`, `/debug`, `/plan`, or `/estimate` instead of doing that work here.
- Inspect `.ai/plan.md`, `.ai/state.md`, `.ai/decisions.md` if present, plus the actual repo: git diff, current implementation, tests, known failures. Trust the repo over stale state. Scope everything to the selected task — other tasks' blocks in `.ai/state.md` are context, not input.
- If no slice map exists yet, say so and recommend `/estimate` rather than improvising slices.
- A slice already implemented but unverified is VERIFYING, not a new READY slice — don't propose work on top of unverified work.
- A failed verification is always RECOVERABLE or REPLAN_REQUIRED, never a bare "it failed" — classify it using the definitions above before reporting.
- If a slice touches shared/public surfaces, recommend `/impact` rather than assessing it here.
- If a slice represents a weighty, hard-to-reverse decision, recommend `/challenge` rather than assessing it here.
- Model/profile suggestions are advisory text carried over from `/estimate` — never claim to switch models automatically.
- Execution approval (auto-continue vs. confirming before each change) follows the session's own permission mode — `next` doesn't override it.
- Do not re-explain the repository or the plan on every call — assume context is already known.

## Output

Exactly one state. Keep it short.

### READY
```
Task: <id> — <title>
State: READY
Slice: <id/name> (<n>/<total>)
Goal: <one line>
Scope: <files/areas — omit if obvious from Goal>
Verification: <criteria from the slice map>
Model: <suggested profile — omit if not useful>
Estimate: <story points, from the slice map>
Do not touch: <only if relevant>
```
Ready to execute.

### VERIFYING
```
Task: <id> — <title>
State: VERIFYING
```
One line: what was implemented and that `/verify` should confirm it.

### BLOCKED
```
Task: <id> — <title>
State: BLOCKED
```
State plainly: what's blocking, why it's required, and the exact action/input that unblocks it. Never invent credentials, access, or infrastructure.

### RECOVERABLE
```
Task: <id> — <title>
State: RECOVERABLE
```
One line: what failed and why it's local.
Next: `/debug` → `/verify`.

### REPLAN_REQUIRED
```
Task: <id> — <title>
State: REPLAN_REQUIRED
Reason: <assumption that broke>
```
Next: `/plan` → `/estimate`.

### COMPLETE
```
Task: <id> — <title>
State: COMPLETE
```
One line: all slices done, recommend final `/verify` and `/review`.
