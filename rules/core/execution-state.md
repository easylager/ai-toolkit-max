# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, keep it in `.ai/` at the project root.

## Tasks

A task that gets a persisted plan gets a stable id: `TASK-001`, `TASK-002`, … — allocated sequentially, never reused. `/plan` assigns the id the first time a task's plan is persisted (see `skills/plan/SKILL.md`) and reuses it on later refinements of the same task. Don't allocate an id for a trivial one-off change — only once the workflow actually becomes stateful (multi-slice, resumable across sessions).

A task is **active** if its state isn't `COMPLETE`. `/next` and `/status` operate on a task by id (`/next TASK-003`, `/status TASK-003`); without one, `/next` uses the single active task if there's exactly one, asks if there are several, and says so if there are none — never guesses.

`.ai/state.md` is the single source of truth for a task's current position. `.ai/plan.md` holds the destination, slice map, and acceptance criteria; `.ai/decisions.md` holds the reasoning behind decisions. Neither duplicates what's in `.ai/state.md` — they're referenced from it, not repeated.

## Acceptance criteria

Every task with a persisted plan carries an Acceptance Contract: the criteria that define "done," drafted by `/clarify` and finalized by `/plan` — see `skills/clarify/SKILL.md` and `skills/plan/SKILL.md`. This is what task completion is actually derived from, not slice count, lines changed, or agent confidence.

Each criterion (`AC-NNN`) has two independent axes, tracked in different files because they change at different times and are owned by different skills:

- **Requirement status** — `CONFIRMED` / `INFERRED` / `UNKNOWN`. Whether the criterion is actually agreed, not just guessed. Lives in `.ai/plan.md`, owned by `/plan` (from `/clarify`'s draft). An `INFERRED` criterion never silently becomes `CONFIRMED` just because implementation proceeds. An `UNKNOWN` criterion that would block safe implementation keeps the task from reaching "Ready to implement" (pre-`.ai/`) or moves it to `BLOCKED` (mid-execution) until `/clarify` resolves it — never implemented on a guessed default.
- **Verification status** — `VERIFIED` / `FAILED` / `BLOCKED` / `NOT_VERIFIED`. Whether there's evidence the behavior actually works. Lives in `.ai/state.md`, owned by `/verify`, initialized `NOT_VERIFIED` by `/estimate`. `VERIFIED` requires evidence — a concrete check that was actually run or inspected, never "the implementation looks correct."

There is deliberately no third, separately-tracked "implementation status" per criterion — that's exactly what the slice's own `READY`/`EXECUTING`/`VERIFYING` position already tracks (see Execution loop below). Adding a parallel field would duplicate state that already exists; a criterion's implementation progress is read off the slice(s) that cover it.

A criterion's verification method/level (unit, integration, e2e, contract, performance, security, static analysis, migration, manual, exploratory, or other — chosen by what can actually prove the criterion, not a fixed default) is decided in `/clarify`/`/plan` as a category and refined into concrete checks by `/estimate`/`/verify`.

## Files

### `.ai/plan.md`
The destination — what needs to be done. Each task's plan starts with `Task: TASK-NNN — <title>`, followed by its acceptance criteria (`AC-NNN`: description, requirement status, verification method/level — see Acceptance criteria above). Written by `/plan`; extended by `/estimate` with that task's initial slice map (short slice id like `S1`, goal, scope, dependencies, the acceptance criterion/criteria it covers, estimate, verification criteria — see `skills/estimate/SKILL.md`). `/next` may reorder, split, merge, or annotate slices as execution surfaces new information, but doesn't originate the map or rewrite the acceptance criteria — a criterion changing is a `/plan` event (see REPLAN_REQUIRED below).

### `.ai/state.md`
The current position of every task, one block per task, using `/next`'s canonical states: `READY`, `EXECUTING`, `VERIFYING`, `BLOCKED`, `RECOVERABLE`, `REPLAN_REQUIRED`, or `COMPLETE` (see `skills/next/SKILL.md`), plus each acceptance criterion's verification status. Owned by `/next` and `/verify`, initialized by `/estimate`; overwritten in place per task, not appended. `EXECUTING` is advisory only — a stale `EXECUTING` marker from an interrupted session is re-derived from the repo, never trusted outright.

Per task:
```
## TASK-NNN — <title>
State: <state>
Slice: <n>/<total> — <slice id/name>
Objective: <current objective — omit if same as slice goal>
Last action: <what was just done>
Next: <what happens next>
Blocked: <reason, or omit/"no">
Acceptance:
  AC-001: VERIFIED — <evidence, one line>
  AC-002: NOT_VERIFIED
  (one line per criterion; FAILED/BLOCKED carry a one-line reason the same way VERIFIED carries evidence)
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
- A slice isn't done because code was written — it's done once `/verify` marks the criteria it covers `VERIFIED` with evidence. Verify at the smallest scope that actually proves the slice works; don't run validation a trivial change doesn't warrant. A task isn't COMPLETE because its slices were written or even because all slices ran through `/verify` once — only once every acceptance criterion is `VERIFIED`. Progress is reported as criteria verified (`n`/`m`), not slices touched or files changed.
- If verification fails, classify it rather than blindly continuing or retrying:
  - **RECOVERABLE** (local, understandable — failing test, wrong implementation, type error, straightforward regression): route to `/debug`, then `/verify` again, then back to READY for the next slice. Expected to happen without asking the user first.
  - **REPLAN_REQUIRED** (the failure invalidates an assumption in the approved plan — wrong architecture, a dependency behaving differently than assumed, a slice turning out fundamentally bigger or more cross-cutting than estimated, **or an acceptance criterion itself changes**: a `CONFIRMED` criterion turns out wrong, a new criterion surfaces, or resolving an `UNKNOWN` invalidates slices already planned): stop, tell the user what broke, and re-enter through `/plan` → `/estimate`. Never patch around this to keep going, and never quietly edit a criterion's requirement status outside `/plan`.
- After a slice is implemented and verified, record a short checkpoint before calling `/next` again:

```
Task: <id>
Completed: <what changed>
Verified: <how>
Acceptance: <n>/<m> criteria verified
Issue: <only if relevant>
Status: READY | COMPLETE | BLOCKED | RECOVERABLE | REPLAN_REQUIRED
Next: <next slice/action>
```

## Autonomy

Keep moving through the loop above without asking when the next action is obvious, the change is low-risk, the task's acceptance criteria in `.ai/plan.md` are unchanged from what was last approved, and verification passes — this includes RECOVERABLE failures, which route through `/debug` → `/verify` automatically.

Stop and ask the user when: the state is REPLAN_REQUIRED (an architectural decision is required, requirements or an acceptance criterion changed, or a significant unexpected dependency surfaces), the state is BLOCKED (missing credentials, tool/external access, infrastructure, or a decision only the user can make — including an `UNKNOWN` acceptance criterion that blocks safe implementation), or continuing would require guessing business intent. Never silently change the approved plan or an acceptance criterion's requirement status, skip verification, mark a criterion VERIFIED without evidence, mark a failed slice complete, or invent access that doesn't exist — when a situation is ambiguous, stop with a concise explanation instead of assuming.

## Principles

- Create `.ai/` lazily — a task that doesn't need multi-slice tracking doesn't get one, and doesn't get a `TASK-NNN` id.
- State is advisory. The repository (git diff, test output, actual file contents) is always ground truth. If `state.md` claims something the repo contradicts, trust the repo and flag the mismatch.
- Progress is defined by acceptance criteria, not proxies. Never infer that a task is done from code volume, files touched, subtasks/slices completed, or agent confidence — only from criteria marked `VERIFIED` with evidence.
- `/next`, `/verify`, `/plan`, and `/estimate` may write only inside `.ai/` — never source code, configs, or any other project file. Implementing the change itself is normal work, not something these skills do.
- Keep entries terse and structured, not prose logs. Record only what materially helps a fresh session resume without replaying the conversation.
- Commit `.ai/` to the project's own repository by default — that's what lets a new session or a teammate resume without reconstructing context.
