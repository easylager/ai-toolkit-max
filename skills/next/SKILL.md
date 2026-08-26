---
name: next
description: State-driven execution dispatcher for a task (optionally `/next TASK-NNN`). Inspects that task's plan, slice map, and state, plus the repo, to decide the single next action and routes automatically through verification, recoverable failures, and blockers. Reports READY, VERIFYING, BLOCKED, RECOVERABLE, REPLAN_REQUIRED, or COMPLETE.
---

# Next

Decide the single next action for one task, using the canonical execution states below. Not the next plan item — the next safe, minimal step given what's actually true right now.

## Which task

`/next` optionally takes a `TASK-NNN` argument. Without one:

- Exactly one active task (status not `COMPLETE`) among the task files in the resolved `TASK_CONTEXT_ROOT` (per `rules/core/task-context.md`) → use it.
- More than one active task → list them briefly (id, title, status) and ask which one, rather than guessing.
- No tasks at all → say so plainly and recommend `/plan`.

Given `/next TASK-NNN` for an id with no matching task file, say so — don't invent one.

## States

- **READY** — a slice is ready to execute.
- **VERIFYING** — a slice is implemented and needs `/verify`.
- **BLOCKED** — execution needs something external: credentials, tool/MCP access, an external API, infrastructure, or a user decision — including an `UNKNOWN` acceptance criterion that would block safe implementation (see `rules/core/execution-state.md`'s Autonomy section). A missing MCP only blocks when `/verify` found no adequate local alternative (see `rules/core/capabilities.md`) — name the specific capability, never resolvable by Claude alone.
- **RECOVERABLE** — verification failed for a local, understandable reason (failing test, wrong implementation, type error, integration mistake, straightforward regression). Routes to `/debug` → `/verify` → READY, normally without asking the user first.
- **REPLAN_REQUIRED** — the failure or new information invalidates an assumption in the approved plan (wrong architecture, a dependency behaving differently than assumed, a "local" change turning out to be cross-service, a slice fundamentally bigger/different than estimated, a needed capability that doesn't exist, or an acceptance criterion itself changing — a confirmed one turning out wrong, a new one surfacing, an unknown resolving in a way that invalidates planned slices). Routes to `/plan` → `/estimate` → READY. Always stop and tell the user — never patch around an invalidated plan.
- **COMPLETE** — every acceptance criterion in the task file is `VERIFIED` (never `STALE`, `NOT_VERIFIED`, or `FAILED`), not merely every slice implemented. Recommend final `/verify` and `/review`; don't generate further work.

EXECUTING (actually implementing a slice) is not a state `next` reports — it's the runtime interval between a READY dispatch and its checkpoint. If the task file shows a slice still EXECUTING (e.g., resumed after an interrupted session), don't trust it — reconcile first (re-read the file fresh, per `rules/core/task-context.md`) and re-derive status from the repo. This is also how `/next` recovers a task after an interruption — there is no separate recovery command.

## Rules

Per `rules/core/common-rules.md`: file ownership, reconciliation, context-pack loading.

- Load task context per `rules/core/context-pack.md` (implement/next stage sections).
- Reconcile first, then inspect repo scoped to the current/candidate slice's `Scope:` field when a slice map exists — trust repo over stale file.
- No repository-wide search beyond selected task/slice, no subagent or background-agent spawning, no invoking the Supervisor decision model directly (that's `/execute`'s).
- If no slice map exists yet, say so and recommend `/estimate` rather than improvising slices.
- A slice already implemented but unverified is VERIFYING, not a new READY slice — don't propose work on top of unverified work.
- A failed verification is always RECOVERABLE or REPLAN_REQUIRED, never a bare "it failed" — classify it using the definitions above before reporting.
- Among multiple READY slices, prefer the one that moves a `NOT_VERIFIED` or `FAILED` acceptance criterion toward `VERIFIED` — the goal is verified acceptance, not code volume.
- Never report COMPLETE from slice count alone — cross-check the task file's Acceptance Criteria section; a task with unverified, failed, or stale criteria isn't COMPLETE even if every slice was touched.
- If a slice touches shared/public surfaces, flag rollout risk inline — do not invoke a separate skill.
- If a slice represents a weighty, hard-to-reverse decision, stress-test assumptions inline — do not invoke a separate skill.
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
Covers: <acceptance criterion id(s) this slice targets — omit if none>
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
Acceptance: <n>/<n> criteria verified
```
One line: all criteria verified, recommend final `/verify` and `/review`.
