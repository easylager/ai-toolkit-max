# Common Rules

Shared constraints referenced by multiple skills. Cite this file instead of repeating these patterns in every SKILL.md.

## File ownership

- Skills may write **only** the task's Task Context file sections they own (per `rules/core/task-context.md` Ownership table) — never source code, configs, or other project files.
- Exception: `/debug` may write source when recovering from RECOVERABLE failures; implement phase is normal Claude work, not a skill write.

## Reconciliation

Before acting on a task file: re-read it fresh off disk. Never rely on conversation memory. Required at minimum before `/plan`, slice implementation, `/verify`, `/review`, session resume. See `rules/core/task-context.md` Reconciliation section for drift criteria.

## Chat context is not state

The task file (`rules/core/task-context.md`) is the only source of truth. Applies to every skill that touches a task:

- Never treat this conversation's memory — an earlier skill's output, an AC or plan shown earlier in this chat, a state a previous turn reported — as equivalent to what's on disk. Re-read the file fresh (per Reconciliation above) before deciding or reporting anything.
- A conversation-only draft (e.g. `/clarify` or `/plan` reasoning before its first persist) is a hypothesis, not state. Say so explicitly in the output — never present it the way persisted content is presented — until it is actually written to the file this same pass.
- An empty or missing section means exactly that — not started. Never "probably done already," never inferred from what the conversation seems to assume. A skill needing a section that's empty says so and names the skill that owns it (`/clarify` for Acceptance Criteria, `/estimate` for Slices, etc.) rather than guessing or improvising.

## Persist-before-report

Every state-changing skill (`/clarify`, `/plan`, `/estimate`, `/verify`, `/reconcile`, `/debug`, `/execute`) follows this order, every pass:

1. **READ** — re-read the task file fresh off disk (Reconciliation, above).
2. **REASON** — decide what changes.
3. **PERSIST** — write the decided changes to the task file's owned sections, including the Execution History event for this pass.
4. **RE-READ / VALIDATE** — read the file back and confirm the write landed and frontmatter is still well-formed.
5. **REPORT** — only now show the result, per that skill's own Output contract.

A skill never reports a state-changing result (a new `phase`, a persisted AC/Slice/Result, a status change) before step 3 has completed and step 4 has confirmed it. If a pass stops short of persisting (blocked, incomplete), the output says so plainly instead of describing the would-be result as done.

## Interrupted work still leaves a record

If a skill's work is interrupted or blocked, add an entry to Execution History explaining what happened and what's needed next. A task file should always be readable after an interruption, with no mystery about what state the work is in.

## Task header

Every skill whose output concerns a specific task begins that output with:
```
Task: TASK-NNN — <title>
```
Omit only when no task file exists yet and none is being created this pass (fully trivial, one-off work). Once a task file exists, this line is mandatory — it's what lets a human, and the next skill invocation, know unambiguously which task a given response (including any Acceptance Criteria or plan shown in it) actually belongs to.

## Reading the task file

Load what you need from the task file. For most skills, read the whole file once. Avoid re-reading the same sections repeatedly in one pass.

## Skill rule references

- `/task` and `/status`: quick reference to task-context.md for file operations.
- `/execute`: reads `rules/core/execution-state.md` for phase logic.
- All skills: cite specific sections by name in your SKILL.md — keep the skill instruction concise.

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
