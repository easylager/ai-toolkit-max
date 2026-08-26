# Common Rules

Shared constraints referenced by multiple skills. Cite this file instead of repeating these patterns in every SKILL.md.

## File ownership

- Skills may write **only** the task's Task Context file sections they own (per `rules/core/task-context.md` Ownership table) — never source code, configs, or other project files.
- Exception: `/debug` may write source when recovering from RECOVERABLE failures; implement phase is normal Claude work, not a skill write.

## Reconciliation

Before acting on a task file: re-read it fresh off disk. Never rely on conversation memory. Required at minimum before `/plan`, slice implementation, `/verify`, `/review`, session resume. See `rules/core/task-context.md` Reconciliation section for drift criteria.

## Context loading

Use `rules/core/context-pack.md` stage-aware contract — do not load the full task file when the compact pack suffices.

## Scoped rule reads

- Control Plane skills (`/task`, `/status`): per `rules/core/lifecycle-planes.md` — no full `execution-state.md`.
- `/execute`: reads `rules/core/execution-state-supervisor.md` for Supervisor model.
- All other skills: cite specific sections of `rules/core/execution-state.md` by name — never read the whole file unless the skill explicitly requires Supervisor behavior.

## Investigation bounds

- No repository-wide search beyond the current task/slice scope unless `/plan` or `/clarify` explicitly requires it.
- No subagent or background-agent spawning unless the skill's own rules explicitly allow it.
- Trust repo state (git diff, tests) over stale task file claims.

## Output brevity

Agent output is for the human, not for storing execution logs. After completing work, show at most:

```
DONE

What changed:
- ...

Tests:
- N passed (or omit if none run)

Cost/Tokens: (only if Claude emitted them — never estimate)

Next:
- ...

Needs you:
- ...
```

For decisions, use:

```
DECISION NEEDED

Recommended:
A — ...

Alternative:
B — ...

Why:
...

Your choice:
A / B
```

Details belong in Task Context / artifacts / telemetry — not in the chat response.

## Human Gates

Exactly four gates (never invent more): Requirements, Creative Approval, High-risk action, Final review. See `rules/core/execution-state.md` Autonomy section. A gate is `BLOCKED` status (or `DRAFT` for creative) with reason in Blockers — not a new state value.
