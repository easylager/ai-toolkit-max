---
name: reconcile
description: Detect drift between a task's persisted Task Context and the current code/git/conversation state — new requirements, changed acceptance criteria, human overrides, or stale verification evidence — and flip status to BLOCKED/REPLAN_REQUIRED or mark evidence STALE when material.
---

# Reconcile

Compare the task's persisted Task Context against ground truth — the repo, git history, and this conversation — and surface drift before it causes silent staleness. This is the explicit, on-demand version of the reconciliation every other skill already does opportunistically before acting (see `rules/core/task-context.md`).

## Rules

- Read the task file fresh off disk — never rely on what the conversation last saw.
- Detect, per `rules/core/task-context.md`'s "Detecting human edits": new or reworded Acceptance Criteria, changed `Requirement`/`Result` values, new Edge Cases, changed Constraints, new `Human Overrides` content, changed Test Strategy, new Blockers.
- For each Acceptance Criterion currently `VERIFIED`, compare its `Verified at` commit SHA against the repo's current state (`git diff <sha>..HEAD -- <relevant files>` or equivalent). If relevant files changed since, mark it `STALE` — do not leave a falsely-current `VERIFIED` in place.
- Human edits are authoritative — never revert one to match a prior AI assumption. If a human edit directly contradicts something else required in the file, surface it as an Open Question or a Blocker instead of picking a side.
- Material drift (a changed/new Acceptance Criterion, a Human Override that invalidates the current plan or an in-progress slice, a Blocker with no clear resolution) sets `status: BLOCKED` or `status: REPLAN_REQUIRED` — the same states `rules/core/execution-state.md` defines, never a new one. Non-material drift (an edge case added for later, a note in Business Context) doesn't change `status`.
- Do not modify files other than the task file, and only the sections drift actually requires updating (`Result` → `STALE`, `Blockers`, `status`, `Open Questions`) — never rewrite sections that didn't drift.
- Do not write implementation code and do not decide the next action (that's `/next`) — reconcile reports drift and updates status; `/next` acts on it.

## Output

Keep it concise.

### Drift found
Per item: `<field> — was: <old> → now: <new> — <source: human edit | repo state | conversation>`.
Omit this section entirely if nothing drifted.

### Staleness
`AC-<NNN>: STALE — <files changed since <sha>>` per newly-stale criterion. Omit if none.

### Status
`<unchanged>` or `<old status> → <new status>` with a one-line reason.

Recommend `/next` if status changed, `/plan` if REPLAN_REQUIRED, or say nothing further needs to happen if nothing drifted.
