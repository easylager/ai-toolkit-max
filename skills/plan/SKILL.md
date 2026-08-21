---
name: plan
description: Create a concise implementation plan for the current feature based on the requirements and repository context.
---

# Plan

Create an implementation plan for the current task.

## Rules

- Analyze the existing repository before proposing changes.
- Reuse existing patterns and abstractions when appropriate.
- Do not modify files, except `.ai/plan.md` when persisting a multi-slice plan. The first time a task's plan is persisted, assign it the next sequential `TASK-NNN` id and record it at the top of `.ai/plan.md`; reuse the existing id when refining an already-persisted plan. See `rules/core/execution-state.md`.
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

### Changes
List the files/modules that need to be created or modified and why.

### Data/API
Describe important models, interfaces, endpoints, or data flow.

### Tests
List the key tests required.

### Risks
Only mention meaningful risks or unresolved decisions.

End with:

**Ready to implement** (plus `Task: TASK-NNN` when `.ai/` is in use)

or list what still needs clarification.
