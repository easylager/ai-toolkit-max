# Execution State

Persisted execution state for multi-slice, resumable tasks. One file per task — see `rules/core/task-context.md` for schema.

For Supervisor orchestration details, see `rules/core/execution-state-supervisor.md` (`/execute` only).

For stage-aware reading, see `rules/core/context-pack.md`.

For shared skill constraints, see `rules/core/common-rules.md`.

Control Plane vs Reasoning Plane boundary: `rules/core/lifecycle-planes.md`.

## Tasks

Stable ids: `TASK-001`, `TASK-002`, … — allocated by `/plan` or `/clarify`, never reused. No id for trivial one-offs.

A task is **active** if status ≠ `COMPLETE`. `/next` and `/status` resolve by id or ask if ambiguous.

## Acceptance criteria

Two independent axes per `AC-NNN`:

- **Requirement:** `CONFIRMED` / `INFERRED` / `UNKNOWN` — owned by `/plan` (from `/clarify` draft).
- **Result:** `VERIFIED` / `FAILED` / `BLOCKED` / `NOT_VERIFIED` / `STALE` — owned by `/verify`; `/reconcile` may mark STALE.

No separate "implementation status" — read from slice status. `VERIFIED` requires evidence, never agent confidence.

## Execution loop

`/estimate` (READY) → `/next` picks slice → implement → `/verify` (VERIFYING) → checkpoint → repeat → COMPLETE → `/review`.

```
READY → implement → VERIFYING → READY | COMPLETE
VERIFYING → RECOVERABLE → /debug → VERIFYING
VERIFYING → REPLAN_REQUIRED → /plan → /estimate
(any) → BLOCKED → READY
```

- Never implement an entire plan in one pass.
- A slice isn't done until `/verify` marks its criteria VERIFIED.
- RECOVERABLE: local failure → `/debug` → `/verify` automatically.
- REPLAN_REQUIRED: assumption broke or AC changed → stop → `/plan` → `/estimate`.

Checkpoint format (detail for CHECKPOINT events):

```
Task: <id>
Completed: <what changed>
Verified: <how>
Acceptance: <n>/<m>
Status: READY | COMPLETE | BLOCKED | RECOVERABLE | REPLAN_REQUIRED
Next: <action>
```

## Autonomy

Keep moving when next action is obvious, low-risk, ACs unchanged, verification passes.

**Four Human Gates** (never invent more):

1. **Requirements** — UNKNOWN AC blocks safe implementation.
2. **Creative Approval** — design/creative-explore output still DRAFT.
3. **High-risk action** — destructive/irreversible ops.
4. **Final review** — before COMPLETE: all AC VERIFIED, `/review` clean, `/design-review` clean if UI task.

Gate = `BLOCKED` (or DRAFT for creative) with reason in Blockers. Also `REPLAN_REQUIRED` when plan invalidates.

`/execute` chains phases within one invocation; individual skills remain independently invocable.

## Loop detection

Same phase + same failure signature for `max_verify_iterations` times (`.ai/config`, default 3) → `BLOCKED`, report attempts and needed decision.

## Supervisor decision model

Moved to `rules/core/execution-state-supervisor.md` — loaded by `/execute` only. Other skills cite specific sections of this file.

### Execution History format

Pipe-delimited one-liners. Event types and ownership: `rules/core/execution-state-supervisor.md` Execution History format section.

Trim when >50 lines — archive to `.ai/tasks/archive/TASK-NNN-history.md`, keep last 20.

## Principles

- Create `.ai/` lazily — no task file for trivial work.
- Repo is ground truth over stale task file.
- Progress = verified ACs, not code volume or slice count.
- Lifecycle skills write only inside task context — implement is normal work.
- Keep entries terse and structured.
