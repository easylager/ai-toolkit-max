---
name: plan
description: Create a concise implementation plan for the current feature, anchored to its acceptance criteria — mapping each criterion to the changes and verification that satisfy it.
---

# Plan

Create an implementation plan for the current task, built around its Acceptance Contract rather than around code to write.

## Rules

- Analyze the existing repository before proposing changes.
- Reuse existing patterns and abstractions when appropriate.
- Take `/clarify`'s draft acceptance criteria as the starting point when one exists in this conversation; otherwise derive criteria directly from the request using the same CONFIRMED/INFERRED/UNKNOWN classification (see `skills/clarify/SKILL.md`).
- Only promote an `INFERRED` criterion to `CONFIRMED` if the conversation actually confirmed it — never upgrade a status just because a plan is being written. Carry unresolved `INFERRED`/`UNKNOWN` criteria forward as-is.
- Every meaningful acceptance criterion must be traceable to at least one entry in Changes or Tests. Flag any criterion with no implementation or verification path instead of silently dropping it.
- If an `UNKNOWN` criterion would block safe implementation, do not plan around a guessed default — say so and stop short of "Ready to implement" instead.
- Do not modify files, except `.ai/plan.md` when persisting a multi-slice plan. The first time a task's plan is persisted, assign it the next sequential `TASK-NNN` id and record it at the top of `.ai/plan.md` together with its acceptance criteria (id, description, requirement status, verification method/level); reuse the existing id and update the existing criteria list when refining an already-persisted plan. See `rules/core/execution-state.md`.
- Do not write implementation code.
- Avoid unnecessary architecture and dependencies.
- Prefer the smallest design that satisfies the requirements.
- Call out important technical risks or trade-offs.
- Do not repeat requirements that are already obvious.

## Output

Keep the plan concise.

Include:

### Approach
1-3 sentences describing the proposed solution.

### Acceptance criteria
Per criterion, carried forward from `/clarify` or derived here:
```
AC-<NNN>
<one-line, testable description>
Status: CONFIRMED | INFERRED | UNKNOWN
Verification: <method/level>
```
Omit this section entirely only if the task is trivial enough that `/clarify`/`/estimate` would also be skipped.

### Changes
List the files/modules that need to be created or modified and why. Note which acceptance criterion each change serves when it isn't obvious.

### Data/API
Describe important models, interfaces, endpoints, or data flow.

### Tests
List the key tests required, tied to the criteria they verify.

### Risks
Only mention meaningful risks or unresolved decisions.

End with:

**Ready to implement** (plus `Task: TASK-NNN` when `.ai/` is in use)

or list what still needs clarification — including any blocking `UNKNOWN` criterion.
