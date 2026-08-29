---
name: reconcile
description: Detect drift between a task's persisted Task Context and the current code/git/conversation state — new requirements, changed acceptance criteria, human overrides, or stale verification evidence — and flip status to BLOCKED/REPLAN_REQUIRED or mark evidence STALE when material.
---

# Reconcile

Compare the task's persisted Task Context against ground truth — the repo, git history, and this conversation — and surface drift before it causes silent staleness. This is the explicit, on-demand version of the reconciliation every other skill already does opportunistically before acting (see `rules/core/task-context.md`).

## Rules

- Read the task file fresh off disk — never rely on what the conversation last saw.
- Detect, per `rules/core/task-context.md`'s "Detecting human edits": new or reworded Acceptance Criteria, changed `Requirement`/`Result` values, new Edge Cases, changed Constraints, new `Human Overrides` content, changed Test Strategy, new Blockers.
- For each Acceptance Criterion marked `VERIFIED`, check if relevant files changed since the `Verified at` commit. If so, mark it `STALE` — don't leave a false "verified" in place.
- Human edits in the file are authoritative — never silently revert them.
- Material drift (changed criterion, human override that breaks the plan, blockers that can't be resolved) may need status changes: `BLOCKED` or `REPLAN_REQUIRED`. Non-material drift (edge cases noted for later) doesn't change status.
- Update only sections that actually drifted. Write changes, re-read to confirm before reporting.
- Do not write implementation code and do not decide the next action (that's `/next`) — reconcile reports drift and updates status; `/next` acts on it.

## Output

Begin with the Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>`.

Keep it concise.

### Drift found
Per item: `<field> — was: <old> → now: <new> — <source: human edit | repo state | conversation>`.
Omit this section entirely if nothing drifted.

### Staleness
`AC-<NNN>: STALE — <files changed since <sha>>` per newly-stale criterion. Omit if none.

### Status
`<unchanged>` or `<old status> → <new status>` with a one-line reason.

Recommend `/next` if status changed, `/plan` if REPLAN_REQUIRED, or say nothing further needs to happen if nothing drifted.
