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

- **Read-only.** `/next` reads the task file and repo; never writes. It reports the current state, not persisted facts.
- Reconcile first — re-read the file fresh off disk, never assume what an earlier turn reported.
- For each slice, check: are all its criteria verified? If not, it's READY or BLOCKED or RECOVERABLE.
- If no slices exist, recommend `/estimate`.
- Among READY slices, prefer ones that move unverified criteria toward completion.
- COMPLETE only when all acceptance criteria are VERIFIED (not just all slices touched).
- Keep it short — assume context from earlier work.

## Output (in Russian)

Simple summary of where the task is and what to do next.

Example:
```
Task: TASK-001 — User list

Статус: READY
Срез: 1/3 — List endpoint
Что проверяем: pagination, error handling
Готово к реализации.

Следующий шаг: implement
```

Other states:
- `VERIFYING` — slice implemented, ready for `/verify`
- `BLOCKED` — something external is needed (name it clearly)
- `COMPLETE` — all criteria verified, ready for `/review`
- `RECOVERABLE` — test/type failure, needs `/debug`
- `REPLAN_REQUIRED` — plan assumption broke, needs `/plan`
