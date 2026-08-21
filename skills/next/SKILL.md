---
name: next
description: Dispatcher for incremental, state-driven execution. Inspects the current plan, state, and repo to determine the single next action — implement a new slice, verify one already implemented, resolve a blocker, escalate a decision, replan, or finish. Reports Ready, Verify, Blocked, Decision required, Plan invalidated, or Complete.
---

# Next

Decide the single most appropriate next action. Not the next plan item — the next safe, minimal step given what's actually true right now.

## Rules

- Do not modify files except `.ai/state.md` (and `.ai/plan.md`, only to annotate slice groupings the first time slices are defined). See `rules/core/execution-state.md`.
- Do not write implementation code and do not run verification yourself — recommend `/verify`, `/debug`, `/impact`, `/challenge`, or `/estimate` instead of doing that work here.
- Inspect `.ai/plan.md`, `.ai/state.md`, `.ai/decisions.md` if present, plus the actual repo: git diff, current implementation, tests, known failures. Trust the repo over stale state.
- Prefer vertical slices (a coherent piece of working, testable functionality) over mechanical file-by-file steps. A trivial task may be a single slice — never split one up artificially.
- Base the slice on dependencies, risk, and what's actually already implemented — not just plan order.
- If the repo shows an implementation for the current slice that hasn't been verified yet, report Verify — don't propose a new slice on top of unverified work.
- If a slice touches shared/public surfaces, recommend `/impact` rather than assessing it here.
- If a slice represents a weighty, hard-to-reverse decision, recommend `/challenge` rather than assessing it here.
- If a slice isn't sized yet, recommend `/estimate` rather than guessing a number.
- Report Decision required — not Ready — when continuing would mean guessing business intent, an architectural choice with no clear default, a changed requirement, an unexpected significant dependency, or a destructive or high-risk action. See the autonomy rule in `rules/core/execution-state.md`.
- Do not re-explain the repository or the plan on every call — assume context is already known.

## Output

Exactly one of the six. Keep it short.

### Ready
```
Next slice: <name>
Reason: <why this, why now>
Scope: <files/areas>
Do not touch: <only if relevant>
Estimate: <range, or "run /estimate">
Suggested depth: <only if non-obvious>
```

### Verify
One line: what was implemented for the current slice and that `/verify` should confirm it before continuing.

### Blocked
One line: what's failing or unverified, and what resolves it (usually points to `/verify` or `/debug`).

### Decision required
One line: what decision is needed and why it can't be inferred safely. Stop here — do not propose a slice.

### Plan invalidated
One line: what assumption broke, and that `/plan` (optionally `/challenge` first) should run again.

### Complete
One line: all slices done, recommend final `/verify` and `/review`.
