---
name: execute
description: Run a task through its workflow automatically, phase by phase, stopping only at Human Gates, checkpoints, or completion. Resume with `/execute TASK-NNN`; optionally set the checkpoint frequency with `/execute [TASK-NNN] manual|supervised|autonomous` in either order.
---

# Execute

Run the task's workflow automatically. At each phase boundary, decide the next skill to invoke based on the current state. Each phase follows that skill's normal rules. Continue until a Human Gate, a checkpoint (per `execution_mode`), a blocker, or completion — see `rules/core/execution-state.md`'s Autonomy section for what governs how far a single invocation runs.

## Which task and mode

Arguments are optional and order-independent — matched by shape: a `TASK-NNN` token is the task id, a `manual`/`supervised`/`autonomous` token (case-insensitive) is the mode.

- `/execute` — resolve the task same as `/next`: exactly one active task → use it. More than one → list them briefly and ask which. None, and no description given → say so and ask what to work on.
- `/execute TASK-NNN` — resume that task, using its persisted `execution_mode` (defaults to `AUTONOMOUS` if unset).
- `/execute manual` (or `supervised`/`autonomous`, no task id) — resolve the task as above, then set its `execution_mode` to the given mode before proceeding.
- `/execute TASK-NNN manual` (either order) — resume that task and set its `execution_mode` to the given mode before proceeding.
- Given a bare description with no existing task, bootstrap one the same way `/task` would (allocate the id, write Objective/Scope from what's given), then continue under the given mode or `AUTONOMOUS` if none given.

Setting `execution_mode` from an explicit argument is writing a Human-controlled field (`rules/core/task-context.md` Ownership) — allowed here specifically because the user typed it this turn, same as any other explicit request. Persist it before proceeding; it then applies to future `/execute` invocations too until changed again.

## Rules

- Reconcile first per `rules/core/common-rules.md` — re-read the task file fresh and check if repo changes affect its validity.
- One phase at a time. After each phase completes and is persisted, re-read the task file and decide what's next.
- If you encounter a Human Gate (requirements unclear, creative approval needed, high-risk action, final review), stop and present it.
- Respect the resolved `execution_mode`'s checkpoint frequency (`rules/core/execution-state.md` Autonomy section) — under `SUPERVISED`, stop and report after each slice's criteria are `VERIFIED`, before starting the next; under `MANUAL`, stop before starting each slice and before each `/debug` attempt. A checkpoint pause is not a Human Gate — don't set `BLOCKED` or write a `Blockers` reason for it, just stop the loop and report; the next `/execute` call resumes it.
- If a blocker is present, stop and tell the user what's needed.
- If all acceptance criteria are VERIFIED, move to review.
- Output the phase result simply — what happened, what's next.
- Write to task file only what the current phase owns (per `rules/core/task-context.md` Ownership table).

## Output (in Russian)

Show progress in phases. When work completes or hits a blocker, explain what happened and what's next.

Example during execution:
```
Task: TASK-001 — Users list

✓ clarify — 3 criteria confirmed, 2 open
✓ plan — 5 slices
→ estimate — breaking down work

Продолжаем...
```

At a checkpoint (`SUPERVISED`/`MANUAL`, not a Human Gate):
```
Task: TASK-003 — Order pagination

Режим: SUPERVISED
✓ Срез 2/5 verified — pagination endpoint, tests pass

Остановка на checkpoint. Продолжить: /execute TASK-003
```

When complete:
```
Task: TASK-001 — Users list

Готово: 5/5 критериев проверены.

Что сделано:
- требования уточнены
- план утвержден
- реализованы все срезы
- пройдена финальная проверка

Следующий шаг: /review
```
