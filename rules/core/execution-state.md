# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, keep it in `.ai/` at the project root.

## Files

### `.ai/plan.md`
The destination — what needs to be done, and the intended slices. Written by `/plan` when a plan is persisted; `/next` may annotate it with slice groupings but doesn't rewrite it per slice.

### `.ai/state.md`
The current position, per slice: `not started`, `implemented` (code written, not yet verified), `verified`, `failing`, `blocked`, or `decision required`. Owned by `/next` and `/verify`; overwritten in place, not appended.

### `.ai/decisions.md`
Meaningful architectural/implementation decisions the agent shouldn't have to rediscover. Append-only. Not a diary — only decisions that would otherwise get re-litigated or re-derived.

## Execution loop

For plans with more than one slice: `/next` picks the slice → implement it (normal Claude work, not a skill) → `/verify` → checkpoint → `/next` again → … → `/next` reports Complete → final `/verify` and `/review`.

- Never implement an entire plan in one pass. Slice it — small, logically coherent, independently verifiable pieces. A trivial task can still be one slice; don't invent slices a small task doesn't need.
- A slice isn't done because code was written — it's done once `/verify` passes. Verify at the smallest scope that actually proves the slice works; don't run validation a trivial change doesn't warrant.
- If verification fails: stay on the current slice. Diagnose (`/debug`), fix only if the cause and fix are clear, verify again. If not clear, report Blocked or Decision required rather than guessing or moving on to unrelated work.
- After a slice is implemented and verified, record a short checkpoint before calling `/next` again:

```
Completed: <what changed>
Verified: <how>
Issue: <only if relevant>
Status: VERIFIED | BLOCKED | DECISION REQUIRED | PLAN INVALIDATED
Next: <next slice/action>
```

## Autonomy

Keep moving through the loop above without asking when the next action is obvious, the change is low-risk, acceptance criteria are unchanged, and verification passes.

Stop and ask the user when: an architectural decision is required, requirements changed, the plan is invalidated, a significant unexpected dependency surfaces, a destructive or high-risk action needs confirmation, or continuing would require guessing business intent. `/next` reports this as Decision required.

## Principles

- Create `.ai/` lazily — a task that doesn't need multi-slice tracking doesn't get one.
- State is advisory. The repository (git diff, test output, actual file contents) is always ground truth. If `state.md` claims something the repo contradicts, trust the repo and flag the mismatch.
- `/next`, `/verify`, `/plan`, and `/estimate` may write only inside `.ai/` — never source code, configs, or any other project file. Implementing the change itself is normal work, not something these skills do.
- Keep entries terse and structured, not prose logs. Record only what materially helps a fresh session resume without replaying the conversation.
- Commit `.ai/` to the project's own repository by default — that's what lets a new session or a teammate resume without reconstructing context.
