# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, keep it in `.ai/` at the project root.

## Tasks

A task that gets a persisted plan gets a stable id: `TASK-001`, `TASK-002`, … — allocated sequentially, never reused. `/plan` assigns the id the first time a task's plan is persisted (see `skills/plan/SKILL.md`) and reuses it on later refinements of the same task. Don't allocate an id for a trivial one-off change — only once the workflow actually becomes stateful (multi-slice, resumable across sessions).

A task is **active** if its state isn't `COMPLETE`. `/next` and `/status` operate on a task by id (`/next TASK-003`, `/status TASK-003`); without one, `/next` uses the single active task if there's exactly one, asks if there are several, and says so if there are none — never guesses.

`.ai/state.md` is the single source of truth for a task's current position. `.ai/plan.md` holds the destination and slice map; `.ai/decisions.md` holds the reasoning behind decisions. Neither duplicates what's in `.ai/state.md` — they're referenced from it, not repeated.

## Files

### `.ai/plan.md`
The destination — what needs to be done. Each task's plan starts with `Task: TASK-NNN — <title>`. Written by `/plan`; extended by `/estimate` with that task's initial slice map (short slice id like `S1`, goal, scope, dependencies, estimate, verification criteria — see `skills/estimate/SKILL.md`). `/next` may reorder, split, merge, or annotate slices as execution surfaces new information, but doesn't originate the map.

### `.ai/state.md`
The current position of every task, one block per task, using `/next`'s canonical states: `READY`, `EXECUTING`, `VERIFYING`, `BLOCKED`, `RECOVERABLE`, `REPLAN_REQUIRED`, or `COMPLETE` (see `skills/next/SKILL.md`). Owned by `/next` and `/verify`, initialized by `/estimate`; overwritten in place per task, not appended. `EXECUTING` is advisory only — a stale `EXECUTING` marker from an interrupted session is re-derived from the repo, never trusted outright.

Per task:
```
## TASK-NNN — <title>
State: <state>
Slice: <n>/<total> — <slice id/name>
Objective: <current objective — omit if same as slice goal>
Last action: <what was just done>
Next: <what happens next>
Blocked: <reason, or omit/"no">
Plan: .ai/plan.md
Decisions: <relevant .ai/decisions.md entries — omit if none>
Updated: <date>
```
Keep one block per task; don't grow it into a log. Post-work estimate Records (see `skills/estimate/SKILL.md`) append tersely under the relevant task's block.

### `.ai/decisions.md`
Meaningful architectural/implementation decisions the agent shouldn't have to rediscover. Append-only. Not a diary — only decisions that would otherwise get re-litigated or re-derived. Tag each entry with its task id (`TASK-NNN: ...`) once more than one task is active, so `state.md` can reference it.

## Execution loop

Per task, once it has a slice map: `/estimate` initializes it (READY) → `/next` picks a slice (READY) → implement it (normal Claude work, not a skill) → `/verify` (VERIFYING) → checkpoint → `/next` again → … → `/next` reports COMPLETE → final `/verify` and `/review`.

State transitions:
```
READY → (implement) → VERIFYING → READY (next slice) | COMPLETE
VERIFYING → RECOVERABLE → (/debug) → VERIFYING
VERIFYING → REPLAN_REQUIRED
(any) → BLOCKED → READY (once unblocked)
```

- Never implement an entire plan in one pass. Slice it — small, logically coherent, independently verifiable pieces. A trivial task can still be one slice; don't invent slices a small task doesn't need.
- A slice isn't done because code was written — it's done once `/verify` passes against its stated verification criteria. Verify at the smallest scope that actually proves the slice works; don't run validation a trivial change doesn't warrant. A task isn't COMPLETE because its slices were written — only once its slices are verified.
- If verification fails, classify it rather than blindly continuing or retrying:
  - **RECOVERABLE** (local, understandable — failing test, wrong implementation, type error, straightforward regression): route to `/debug`, then `/verify` again, then back to READY for the next slice. Expected to happen without asking the user first.
  - **REPLAN_REQUIRED** (the failure invalidates an assumption in the approved plan — wrong architecture, a dependency behaving differently than assumed, a slice turning out fundamentally bigger or more cross-cutting than estimated): stop, tell the user what broke, and re-enter through `/plan` → `/estimate`. Never patch around this to keep going.
- After a slice is implemented and verified, record a short checkpoint before calling `/next` again:

```
Task: <id>
Completed: <what changed>
Verified: <how>
Issue: <only if relevant>
Status: READY | COMPLETE | BLOCKED | RECOVERABLE | REPLAN_REQUIRED
Next: <next slice/action>
```

## Autonomy

Keep moving through the loop above without asking when the next action is obvious, the change is low-risk, acceptance criteria are unchanged, and verification passes — this includes RECOVERABLE failures, which route through `/debug` → `/verify` automatically.

Stop and ask the user when: the state is REPLAN_REQUIRED (an architectural decision is required, requirements changed, or a significant unexpected dependency surfaces), the state is BLOCKED (missing credentials, tool/external access, infrastructure, or a decision only the user can make), or continuing would require guessing business intent. Never silently change the approved plan, skip verification, mark a failed slice complete, or invent access that doesn't exist — when a situation is ambiguous, stop with a concise explanation instead of assuming.

## Principles

- Create `.ai/` lazily — a task that doesn't need multi-slice tracking doesn't get one, and doesn't get a `TASK-NNN` id.
- State is advisory. The repository (git diff, test output, actual file contents) is always ground truth. If `state.md` claims something the repo contradicts, trust the repo and flag the mismatch.
- `/next`, `/verify`, `/plan`, and `/estimate` may write only inside `.ai/` — never source code, configs, or any other project file. Implementing the change itself is normal work, not something these skills do.
- Keep entries terse and structured, not prose logs. Record only what materially helps a fresh session resume without replaying the conversation.
- Commit `.ai/` to the project's own repository by default — that's what lets a new session or a teammate resume without reconstructing context.
