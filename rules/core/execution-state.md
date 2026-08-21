# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, keep it in `.ai/` at the project root.

## Files

### `.ai/plan.md`
The destination — what needs to be done, and the intended slices. Written by `/plan` when a plan is persisted; `/next` may annotate it with slice groupings but doesn't rewrite it per slice.

### `.ai/state.md`
The current position — what's in progress, what's complete, what's verified, what's failing, what's next. Owned by `/next` and `/verify`; overwritten in place, not appended.

### `.ai/decisions.md`
Meaningful architectural/implementation decisions the agent shouldn't have to rediscover. Append-only. Not a diary — only decisions that would otherwise get re-litigated or re-derived.

## Principles

- Create `.ai/` lazily — a task that doesn't need multi-slice tracking doesn't get one.
- State is advisory. The repository (git diff, test output, actual file contents) is always ground truth. If `state.md` claims something the repo contradicts, trust the repo and flag the mismatch.
- `/next`, `/verify`, `/plan`, and `/estimate` may write only inside `.ai/` — never source code, configs, or any other project file. Implementing the change itself is normal work, not something these skills do.
- Keep entries terse and structured, not prose logs. Record only what materially helps a fresh session resume without replaying the conversation.
- Commit `.ai/` to the project's own repository by default — that's what lets a new session or a teammate resume without reconstructing context.
