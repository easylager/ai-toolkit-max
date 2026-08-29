---
name: execute
description: Run a task through its workflow automatically, phase by phase, stopping only at blockers, decisions, or completion. Resume with `/execute TASK-NNN`.
---

# Execute

Run the task's workflow automatically. At each phase boundary, decide the next skill to invoke based on the current state. Each phase follows that skill's normal rules. Continue until a Human Gate, blocker, or completion.

## Which task

Optionally takes a `TASK-NNN` argument, same resolution as `/next`/`/status`:

- Given `TASK-NNN`, resume that task from its persisted state.
- Given a bare description with no existing task, bootstrap one the same way `/task` would (allocate the id, write Objective/Scope from what's given), then continue.
- Without an argument: exactly one active task → use it. More than one → list them briefly and ask which. None, and no description given → say so and ask what to work on.

## Rules

- Reconcile first per `rules/core/common-rules.md` — re-read the task file fresh and check if repo changes affect its validity.
- One phase at a time. After each phase completes and is persisted, re-read the task file and decide what's next.
- If you encounter a Human Gate (requirements unclear, creative approval needed, high-risk action, final review), stop and present it.
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
