# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, each task gets one file — `.ai/tasks/TASK-NNN.md` by default, or wherever `TASK_CONTEXT_ROOT` resolves to (see `rules/core/task-context.md` for the full document contract: schema, human/AI ownership, reconciliation, staleness). This file is that state — human-editable in Obsidian or any text editor, git-diffable, and the single source of truth for the task's position.

## Tasks

A task that gets a persisted plan gets a stable id: `TASK-001`, `TASK-002`, … — allocated sequentially, never reused. `/plan` assigns the id the first time a task's plan is persisted (see `skills/plan/SKILL.md`) and reuses it on later refinements of the same task. Don't allocate an id for a trivial one-off change — only once the workflow actually becomes stateful (multi-slice, resumable across sessions).

A task is **active** if its state isn't `COMPLETE`. `/next` and `/status` operate on a task by id (`/next TASK-003`, `/status TASK-003`); without one, `/next` uses the single active task if there's exactly one, asks if there are several, and says so if there are none — never guesses.

The task file is the single source of truth for a task's current position, destination, slice map, acceptance criteria, and decisions — see `rules/core/task-context.md` for the full schema.

## Acceptance criteria

Every task with a persisted plan carries an Acceptance Contract: the criteria that define "done," drafted by `/clarify` and finalized by `/plan` — see `skills/clarify/SKILL.md` and `skills/plan/SKILL.md`. This is what task completion is actually derived from, not slice count, lines changed, or agent confidence.

Each criterion (`AC-NNN`) has two independent axes, tracked as two separate fields on the same criterion because they change at different times and are owned by different skills:

- **Requirement status** (`Requirement:`) — `CONFIRMED` / `INFERRED` / `UNKNOWN`. Whether the criterion is actually agreed, not just guessed. Owned by `/plan` (from `/clarify`'s draft). An `INFERRED` criterion never silently becomes `CONFIRMED` just because implementation proceeds. An `UNKNOWN` criterion that would block safe implementation keeps the task from reaching "Ready to implement" (pre-`.ai/`) or moves it to `BLOCKED` (mid-execution) until `/clarify` resolves it — never implemented on a guessed default.
- **Verification status** (`Result:`) — `VERIFIED` / `FAILED` / `BLOCKED` / `NOT_VERIFIED` / `STALE`. Whether there's evidence the behavior actually works, and whether that evidence is still current. Owned by `/verify`, initialized `NOT_VERIFIED` by `/estimate`; `/reconcile` may flip a `VERIFIED` result to `STALE` (see `rules/core/task-context.md`). `VERIFIED` requires evidence — a concrete check that was actually run or inspected, never "the implementation looks correct."

There is deliberately no third, separately-tracked "implementation status" per criterion — that's exactly what the slice's own `READY`/`EXECUTING`/`VERIFYING` position already tracks (see Execution loop below). Adding a parallel field would duplicate state that already exists; a criterion's implementation progress is read off the slice(s) that cover it.

A criterion's verification method/level (unit, integration, e2e, contract, performance, security, static analysis, migration, manual, exploratory, or other — chosen by what can actually prove the criterion, not a fixed default) is decided in `/clarify`/`/plan` as a category and refined into concrete checks by `/estimate`/`/verify`. A criterion may also carry an optional capability hint (e.g. Playwright, Sentry) naming the external system that most naturally supplies that evidence — advisory only, per `rules/core/capabilities.md`; `/verify` never blocks on a missing hinted capability while an adequate local alternative exists.

## The task file

`.ai/tasks/TASK-NNN.md` (or the resolved `TASK_CONTEXT_ROOT` location) holds everything for one task: acceptance criteria (id, description, requirement status, verification method/level, capability hint, result, evidence — see `rules/core/task-context.md`), the slice map, current state, blockers, decisions, and human-authored context. Nothing about a task lives in a second, separately-synced file — `/plan`, `/estimate`, `/next`, and `/verify` all read and write the same file, each owning a different section of it (see the ownership matrix in `rules/core/task-context.md`).

Overwritten in place per section, not appended — except `Execution History`, which accumulates terse checkpoints (not a prose log) and should be trimmed/archived rather than left to grow unbounded.

## Execution loop

Per task, once it has a slice map: `/estimate` initializes it (READY) → `/next` picks a slice (READY) → implement it (normal Claude work, not a skill — consulting `rules/core/capabilities.md` for relevant external context only if it reduces uncertainty) → `/verify` (VERIFYING) → checkpoint → `/next` again → … → `/next` reports COMPLETE → final `/verify` and `/review`.

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

This applies across the whole task lifecycle, not just the post-plan execution loop — `skills/execute/SKILL.md` is what actually drives a task through it end to end, chaining `/clarify` → `/design`/`/creative-explore` → `/plan` → `/estimate` → the execution loop below → `/design-review` → `/review` within one invocation instead of requiring a separate prompt per skill; `/next`, `/clarify`, `/design`, `/verify`, and the rest remain independently invocable for manual, granular control.

Keep moving without asking when the next action is obvious, the change is low-risk, the task's acceptance criteria in the task file are unchanged from what was last approved, and verification passes — this includes RECOVERABLE failures, which route through `/debug` → `/verify` automatically.

Stop and ask the user at exactly four points (Human Gates) — never invent additional ones:

- **Requirements** — an `UNKNOWN` acceptance criterion would block safe implementation, or continuing would require guessing business intent.
- **Creative Approval** — `/design` or `/creative-explore` produced a recommendation still `DRAFT` (see `skills/design/SKILL.md`).
- **High-risk action** — the next action is destructive or hard to reverse: force-push, `reset --hard`, dropping data, a production deploy, a credential change, a major architectural rewrite, modifying a critical business rule. Same bar as the standing "Executing actions with care" guidance — this isn't a separate, looser policy for autonomous runs.
- **Final review** — before reporting `COMPLETE`: every acceptance criterion `VERIFIED`, `/review` run with no open Critical/High findings, `/design-review` run (if the task went through `/design`) with a "matches approved design intent" assessment, no unresolved blockers.

A Human Gate is never a new state value — it's always the existing `BLOCKED` status (or `DRAFT`, for Creative Approval) with the specific reason recorded in `Blockers` or the relevant skill's own status field. The state is also `REPLAN_REQUIRED` when an architectural decision is required, requirements or an acceptance criterion changed, or a significant unexpected dependency surfaces — always stop and tell the user rather than patch around an invalidated plan. Never silently change the approved plan or an acceptance criterion's requirement status, skip verification, mark a criterion VERIFIED without evidence, mark a failed slice complete, or invent access that doesn't exist — when a situation is ambiguous, stop with a concise explanation instead of assuming.

## Loop detection

Track repeated attempts at the same phase via `Execution History`. If the same phase fails with the same failure signature (same test, same error, same diff shape) for `max_verify_iterations` consecutive attempts (`.ai/config`'s `max_verify_iterations` key if set, default 3), stop rather than retrying again hoping for a different result — report what was attempted, how many times, why it isn't progressing, and the specific human decision needed. This is a `BLOCKED` outcome, not a silent failure or an infinite retry.

## Supervisor decision model

This is the canonical description of how `skills/execute/SKILL.md` actually decides what happens next — the real implementation, not an idealized one. It replaces "pick a phase chain once, then walk it" with re-evaluating at every phase boundary, across the whole lifecycle (THINK phases and the EXECUTE loop alike) rather than only the post-plan portion.

### Inputs

At every boundary, the decision reads — never assumes — from the task file plus the repo:

1. Current phase and status (frontmatter).
2. Business requirements (Objective, Business Context — human-controlled, never inferred).
3. Acceptance Criteria — both axes (`Requirement:`, `Result:`), per criterion.
4. What's actually persisted for the current phase (see Phase completion below) versus what's still only in conversation.
5. Test strategy (Test Strategy section, if set).
6. Existing evidence (`Evidence:`/`Verified at:` on each criterion, plus Execution History entries).
7. Human-authored context since the last decision — Human Overrides, and anything said in this conversation since the last boundary. This always takes precedence over the direction a previous decision was heading in; a mid-run correction changes the next action, it never queues behind a stale one.
8. Blockers (open or resolved).
9. Repository state (git diff, test results — ground truth over the file, per Principles below).
10. Execution History (for loop detection — same phase, same failure signature, repeated).
11. Slice map, if one exists (for the EXECUTE loop specifically — `/next`'s own state definitions apply unchanged here).

### Decision

Apply `/classify`'s own assessment dimensions (complexity, uncertainty, risk, blast radius, UI-facing-ness, significance) to the *current state* above — not the original raw request, and not a repeated invocation of `/classify` itself — to answer one question: **given where this task actually is right now, what is the smallest correct next action that moves it toward `COMPLETE`?** The answer is always exactly one of:

| Decision | When | Typical action |
|---|---|---|
| **EXECUTE** | Next action is obvious, low-risk, ACs unchanged since last approved | Run exactly one phase/skill, then re-decide |
| **ASK_HUMAN** | One of the four Human Gates trips (Requirements / Creative Approval / High-risk action / Final review — see Autonomy above) | Stop, present per that gate's format, wait |
| **RETRY** | Verification (code or visual) is `RECOVERABLE` | Route through `/debug` (code) or a fix (visual), then re-verify, then re-decide |
| **REPLAN** | `REPLAN_REQUIRED` — an assumption broke, an AC changed, scope turned out different | Stop, re-enter via `/plan` → `/estimate`, report why |
| **STOP** | External `BLOCKED`, or the same phase/failure signature repeated `max_verify_iterations` times | Persist the blocker, ask the human |
| **COMPLETE** | Every AC `VERIFIED`, `/review` clean, `/design-review` clean if applicable, no unresolved blockers | Report `COMPLETE` |

No phase list is ever precomputed and walked. `EXECUTE` names exactly one next phase or action — never more than one — and the decision is made again immediately after it completes.

### Phase completion

A phase counts as complete only once its output is actually persisted in the task file — never on "the response covered it." Ownership is unchanged from the existing schema (`rules/core/task-context.md`); this just states what "done" means per phase:

| Phase | Persisted as | Owned by |
|---|---|---|
| `clarify` | Acceptance Criteria, Edge Cases, Test Strategy | `/clarify` |
| `design` | `## Design Context` pointer, Decisions | `/design` |
| `creative-explore` | Decisions (recommendation + rejected concepts + approval status) | `/creative-explore` |
| `plan` | Technical Plan, finalized Acceptance Criteria | `/plan` |
| `estimate` | Slices | `/estimate` |
| `implement` | Code (not in the task file) + a Progress/Execution History entry | normal work |
| `verify` | Per-criterion `Result`/`Evidence`/`Verified at` | `/verify` |
| `design-review` | An Execution History entry (pass/fail + one-line reason) — `design-review` itself is read-only per its own rules and writes nothing, so `/execute` is what checkpoints its outcome | `/execute`, on `design-review`'s behalf |
| `review` | An Execution History entry (clean, or open findings) | `/execute`, on `review`'s behalf |

### Visual loop, made explicit

For a UI-facing task, `implement` and `verify` are not the whole story — this loop runs alongside/after them and is subject to the same loop-detection cap:

```
implement → design-review → PASS → continue (next slice, or Final review)
                          → FAIL → fix → design-review (again)
```

Each `design-review` outcome is persisted per Phase completion above before the next decision is made — the loop's state lives in the task file, not only in `design-review`'s own (unpersisted) output.

### Unified transition diagram

```
LOAD + RECONCILE task file (ground truth: repo > file)
        ↓
SUPERVISOR DECISION (Inputs above → EXECUTE|ASK_HUMAN|RETRY|REPLAN|STOP|COMPLETE)
        ↓
   EXECUTE one phase/action (THINK: clarify/design/creative-explore/plan/estimate,
                              or EXECUTE: /next's own READY→implement→VERIFYING loop,
                              or QUALITY: design-review/review)
        ↓
   PERSIST its output (Phase completion above) + Execution History checkpoint
        ↓
SUPERVISOR DECISION again ← (loop back — nothing here assumes what comes next)
```

This is one decision loop, not two layers with different rigor — the THINK phases and the post-plan EXECUTE loop (`/next`'s own `READY → VERIFYING → RECOVERABLE/REPLAN_REQUIRED/COMPLETE` machine, unchanged) both go through the same Supervisor Decision at their boundaries now.

## Principles

- Create `.ai/` lazily — a task that doesn't need multi-slice tracking doesn't get one, and doesn't get a `TASK-NNN` id.
- State is advisory. The repository (git diff, test output, actual file contents) is always ground truth. If the task file claims something the repo contradicts, trust the repo and flag the mismatch.
- Progress is defined by acceptance criteria, not proxies. Never infer that a task is done from code volume, files touched, subtasks/slices completed, or agent confidence — only from criteria marked `VERIFIED` with evidence.
- `/task`, `/clarify`, `/plan`, `/estimate`, `/next`, `/verify`, `/reconcile`, and `/debug` (only for a durable edge case/decision) may write only inside `.ai/` (or the resolved `TASK_CONTEXT_ROOT`) — never source code, configs, or any other project file. Implementing the change itself is normal work, not something these skills do.
- Keep entries terse and structured, not prose logs. Record only what materially helps a fresh session resume without replaying the conversation.
- Commit `.ai/` to the project's own repository by default — that's what lets a new session or a teammate resume without reconstructing context.
