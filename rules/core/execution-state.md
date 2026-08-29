# Execution State

Persisted execution state for multi-slice, resumable tasks. One file per task — see `rules/core/task-context.md` for schema.

For shared skill constraints, see `rules/core/common-rules.md`.

## Tasks

Stable ids: `TASK-001`, `TASK-002`, … — allocated by `/plan` or `/clarify`, never reused. No id for trivial one-offs.

A task is **active** if status ≠ `COMPLETE`. `/next` and `/status` resolve by id or ask if ambiguous.

## Acceptance criteria

Two independent axes per `AC-NNN`:

- **Requirement:** `CONFIRMED` / `INFERRED` / `UNKNOWN` — owned by `/plan` (from `/clarify` draft).
- **Result:** `VERIFIED` / `FAILED` / `BLOCKED` / `NOT_VERIFIED` / `STALE` — owned by `/verify`; `/reconcile` may mark STALE.

No separate "implementation status" — read from slice status. `VERIFIED` requires evidence, never agent confidence.

## Work loop (estimate → verify → review)

Once a plan is estimated, work is slice-by-slice:

1. `/next` tells you which slice to work on
2. Implement the slice
3. `/verify` checks if the slice's acceptance criteria hold
   - If yes: move to next slice
   - If verification fails locally (test fails, code bug): `/debug` → `/verify` again
   - If plan is wrong (assumption broke): stop, `/plan` → `/estimate` again
4. When all criteria are verified: `/review` for final quality check

Never implement the entire plan in one pass; work incrementally and verify at each step.

## Phases

Workflow sequence. `phase` starts at `new` and advances when the owning skill persists its results.

| Phase | What's needed to advance | Owned by |
|---|---|---|
| `new` | Acceptance criteria and questions | `/clarify` |
| `clarify` | Technical plan and final criteria | `/plan` |
| `plan` | Slices broken down | `/estimate` |
| `estimate` | First slice result persisted | `/verify` |
| `verify` | All criteria verified | `/review` |
| `review` | (task complete) | — |

`design` and `creative-explore` happen alongside `plan` for UI work — see `rules/frontend/design.md`.

`research` doesn't own a phase either: it can run any time before or during `clarify`/`plan`, and repeat later for one new targeted question, without advancing `phase`. It persists straight to `Research Notes`/`Open Questions` (`rules/core/task-context.md`).

A skill sets `phase` **only** when it persists that phase's output. `/next` and `/status` never change phase.

## Human Gates

**Four decision points** (never invent more):

1. **Requirements** — UNKNOWN AC blocks safe implementation.
2. **Creative Approval** — design/creative-explore output needs user approval.
3. **High-risk action** — destructive/irreversible ops.
4. **Final review** — before COMPLETE: all AC VERIFIED, `/review` clean.

When a gate is reached, the task is `BLOCKED` with reason in Blockers until the user decides.

`/execute` chains phases in one invocation; individual skills remain independently invocable.

### Execution History

Simple log of what happened. Minimal format: timestamp | what changed | why or evidence.

Example:
```
2025-08-26 14:30 | clarified requirements | 3 ACs confirmed, 2 unknown
2025-08-26 14:45 | plan approved | 5 slices
2025-08-26 16:00 | slice 1 verified | tests pass
```

Keep last 20 entries; older entries are less useful.

## Principles

- Create `.ai/` lazily — no task file for trivial work.
- Repo is ground truth over stale task file.
- Progress = verified ACs, not code volume or slice count.
- Lifecycle skills write only inside task context — implement is normal work.
- Keep entries terse and structured.
