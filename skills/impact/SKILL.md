---
name: impact
description: Analyze the blast radius of a change that touches shared code, public interfaces, migrations, or infrastructure — affected consumers, breaking surfaces, rollout risk. Not for isolated or local changes.
---

# Impact

Analyze what else is affected by this change. Deeper than a plan's Risks line — only worth running when the change actually has reach.

## Rules

- Do not modify files.
- Do not write implementation code.
- Use only when the change touches shared modules, public APIs/interfaces, data migrations, infrastructure, or cross-team consumers.
- If the change is isolated or local, say so and stop — point back to `plan`'s Risks section instead of forcing this analysis.
- Identify actual consumers/callers from the codebase, not hypothetical ones.
- Distinguish breaking changes from non-breaking ones explicitly.
- Do not repeat risks already obvious from the plan.
- Only include what's material — omit categories that don't apply.

## Output

### Affected surfaces
Who/what depends on this. Omit if nothing material.

### Breaking changes
What breaks, and for whom. Omit if none.

### Rollout risk
Only for migrations/infra/staged rollouts. Omit otherwise.

If the change doesn't have meaningful blast radius, say so in one line instead of producing these sections.
