# Execution State

Persisted execution state for multi-slice, resumable tasks. One file per task — see `rules/core/task-context.md` for schema.

When a project spans several tasks, `rules/core/project-state.md` sits above this file: it holds the task graph and project stage, and each of its nodes becomes one task governed here. A task never reads project state to decide its own next action.

For shared skill constraints, see `rules/core/common-rules.md`.

## Tasks

Stable ids: `TASK-001`, `TASK-002`, … — allocated by `/plan`, `/clarify`, `/classify`, or `/task`, never reused. No id for trivial one-offs.

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

`research` doesn't own a phase either: it can run any time before or during `clarify`/`plan`, and repeat later for one new targeted question, without advancing `phase`. It persists straight to `Comprehension Tips`/`Open Questions` (`rules/core/task-context.md`).

`classify` doesn't own a phase either: it's the entry point, run before `clarify`, and persists straight to `Strategy` (`rules/core/task-context.md`) without advancing `phase` past `new`.

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

## Autonomy

**What makes an `UNKNOWN` criterion block safe implementation** (Human Gate #1, Requirements): behavior would materially diverge depending on the answer — not every open question qualifies, only ones where guessing risks building the wrong thing. `/clarify` and `/next` apply this test the same way (`skills/clarify/SKILL.md`).

**Checkpoint frequency** — a separate axis from Human Gates, controlled by `execution_mode` (task frontmatter — `rules/core/task-context.md`, human-controlled, optional; unset behaves as `AUTONOMOUS`). It governs only how often `/execute` pauses the automation loop to report and wait, on top of — never instead of — the four Human Gates, which always apply regardless of mode:

- **`AUTONOMOUS`** (default) — no checkpoint beyond the four Human Gates. A `RECOVERABLE` failure routes to `/debug` → `/verify` automatically. `/execute` can run every remaining slice in one pass, stopping only at a gate or `COMPLETE`.
- **`SUPERVISED`** — checkpoint after each slice: once a slice's criteria are `VERIFIED`, `/execute` reports progress and stops before starting the next slice. A `RECOVERABLE` failure still auto-routes to `/debug` within the current slice — only the boundary *between* slices pauses.
- **`MANUAL`** — checkpoint before each slice starts, and before each `/debug` attempt on a `RECOVERABLE` failure — every step needs an explicit go-ahead to proceed.

A checkpoint is not a Human Gate: it never sets `status: BLOCKED` and needs no `Blockers` reason — it's a pause in the automation loop, resolved simply by the user re-invoking `/execute` to continue, not a stuck state requiring a decision. `/next`, used standalone outside `/execute`, always reports a single next action regardless of `execution_mode` — the mode only governs how far `/execute`'s own loop runs before stopping to report (`skills/execute/SKILL.md`, `skills/next/SKILL.md`).

## Principles

- Create `.ai/` lazily — no task file for trivial work.
- Repo is ground truth over stale task file.
- Progress = verified ACs, not code volume or slice count.
- Lifecycle skills write only inside task context — implement is normal work.
- Keep entries terse and structured.
