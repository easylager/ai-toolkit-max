---
name: next
description: Determine the safest next meaningful implementation slice from a plan and current state — not "implement the next item," but "what should we safely do next." Reports Ready, Blocked, Plan invalidated, or Complete.
---

# Next

Decide what to safely do next. Not the next plan item — the next meaningful, safe slice.

## Rules

- Do not modify files except `.ai/state.md` (and `.ai/plan.md`, only to annotate slice groupings the first time slices are defined). See `rules/core/execution-state.md`.
- Do not write implementation code.
- Inspect `.ai/plan.md`, `.ai/state.md`, `.ai/decisions.md` if present, plus the actual repo: git diff, current implementation, tests, known failures. Trust the repo over stale state.
- Prefer vertical slices (a coherent piece of working, testable functionality) over mechanical file-by-file steps.
- Base the slice on dependencies, risk, and what's actually already implemented — not just plan order.
- If a slice touches shared/public surfaces, recommend `/impact` rather than assessing it here.
- If a slice represents a weighty, hard-to-reverse decision, recommend `/challenge` rather than assessing it here.
- If a slice isn't sized yet, recommend `/estimate` rather than guessing a number.
- Do not re-explain the repository or the plan on every call — assume context is already known.

## Output

Exactly one of the four. Keep it short.

### Ready
```
Next slice: <name>
Reason: <why this, why now>
Scope: <files/areas>
Do not touch: <only if relevant>
Estimate: <range, or "run /estimate">
Suggested depth: <only if non-obvious>
```

### Blocked
One line: what's failing or unverified, and what resolves it (usually points to `/verify` or `/debug`).

### Plan invalidated
One line: what assumption broke, and that `/plan` (optionally `/challenge` first) should run again.

### Complete
One line: all slices done, recommend final `/verify` and `/review`.
