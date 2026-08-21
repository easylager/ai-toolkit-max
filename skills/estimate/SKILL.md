---
name: estimate
description: Decompose an approved plan into the minimum reasonable number of executable slices and range-estimate each, or compare actual vs. estimate after work. Exposes assumptions and uncertainty instead of false precision.
---

# Estimate

Two modes, chosen from the input:

- **Pre-work** — an approved plan with no completed outcome yet. Decompose it into slices and range-estimate each.
- **Post-work** — a task with an actual outcome to compare against a prior estimate (or "record actual" explicitly requested). Produce a variance record.

## Rules

- Take the existing plan as primary input — `.ai/plan.md` if present, otherwise the plan already produced in this conversation. Don't re-derive requirements or approach `/plan` already settled.
- Decompose into the minimum reasonable number of slices. A slice is a meaningful, independently verifiable unit of work, not a coding step — do not list file-by-file implementation actions unless one is needed to mark a slice boundary.
- Do not create artificial micro-slices. A small, well-understood plan can be a single slice — don't force decomposition.
- The slice map is an initial execution map, not a contract: `/next` may split, merge, reorder, or re-estimate slices as execution surfaces new information.
- Do not write implementation code.
- Estimate in story points, not time (hours/days). Use the Fibonacci-like scale 1, 2, 3, 5, 8, 13, 21 — points reflect relative effort/complexity/uncertainty, not calendar duration. Never output a time unit.
- A slice above ~8 points is a signal it's too coarse — prefer splitting it rather than reporting a single large-point estimate.
- Expose the assumptions and unknowns each estimate depends on.
- State each slice's verification criteria concretely enough for `/verify` to check against — not a restatement of the goal.
- Do not fabricate historical data. If none exists, say so instead of inventing it.
- Do not modify files, except: writing the slice map into `.ai/plan.md`'s Slices section when `.ai/` is in use; initializing the task's block in `.ai/state.md` (state `READY`, current slice 1/total) the first time a slice map is created for it; and appending the post-work Record into that task's block in `.ai/state.md` — see `rules/core/execution-state.md`.

## Output — pre-work

Keep it minimal. A small, well-understood plan can collapse to a single slice, or even one line — don't pad it.

Give each slice a short id (S1, S2, …) so `/next` and `/status` can reference it tersely.

Per slice:
```
### <slice name>
Goal: <one line>
Scope: <files/areas>
Depends on: <other slice(s) — omit if none>
Verification: <criteria this slice must satisfy — tests, behavior, checks>
Estimate: <story points — single value from 1, 2, 3, 5, 8, 13, 21, or a range across two adjacent values if genuinely uncertain>
Risk: <main uncertainty — omit if not material>
Profile: <suggested execution depth/model — omit if not useful>
```

### Total
Sum of the slice points (use the low end of any ranges for a low total and the high end for a high total). Add a confidence/main-uncertainty line only if it adds information beyond the per-slice risks.

Close with one line noting this is an initial execution map, not a fixed plan — `/next` may split, merge, reorder, or re-estimate as work proceeds.

## Output — post-work

### Record
```
Task: <short description>
Estimated: <story points>
Actual: <story points>
Variance: <direction/magnitude>
Driver: <what caused the difference, one line>
```

Keep this structured and terse — it's meant to be reusable as historical estimation data later, not prose. When `.ai/state.md` exists, append this record under the task's block.
