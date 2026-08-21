---
name: estimate
description: Produce a range-based effort/complexity estimate before work, or compare actual vs. estimate after work. Exposes assumptions and uncertainty instead of false precision.
---

# Estimate

Two modes, chosen from the input:

- **Pre-work** — a task with no completed outcome yet. Produce a range.
- **Post-work** — a task with an actual outcome to compare against a prior estimate (or "record actual" explicitly requested). Produce a variance record.

## Rules

- Do not modify files, except appending the post-work Record into `.ai/state.md`'s Estimation section when `.ai/` is in use — see `rules/core/execution-state.md`.
- Do not write implementation code.
- Prefer ranges over single numbers. Avoid false precision.
- Decompose only when the task genuinely has multiple parts of different complexity.
- Expose the assumptions and unknowns the range depends on.
- Do not fabricate historical data. If none exists, say so instead of inventing it.
- For small, well-understood tasks, keep this to one line — do not force decomposition or heavy analysis.

## Output — pre-work

Keep it minimal.

### Estimate
A range, not a single number.

### Assumptions
Only what the range materially depends on. Omit if the task is small and obvious.

### Uncertainty
Only the significant variance drivers. Omit if there aren't any worth naming.

## Output — post-work

### Record
```
Task: <short description>
Estimated: <range>
Actual: <value>
Variance: <direction/magnitude>
Driver: <what caused the difference, one line>
```

Keep this structured and terse — it's meant to be reusable as historical estimation data later, not prose. When `.ai/state.md` exists, also update its Estimation section with this record.
