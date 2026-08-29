---
name: estimate
description: Decompose an approved plan into the minimum reasonable number of executable slices, each mapped to the acceptance criteria it covers, and story-point each (including verification effort) — or compare actual vs. estimate after work. Exposes assumptions and uncertainty instead of false precision.
---

# Estimate

Two modes, chosen from the input:

- **Pre-work** — an approved plan with no completed outcome yet. Decompose it into slices and range-estimate each.
- **Post-work** — a task with an actual outcome to compare against a prior estimate (or "record actual" explicitly requested). Produce a variance record.

## Rules

- Take the existing plan as primary input — the task's Task Context file if present, and only that: if the file exists but its `Technical Plan` is empty, that means `/plan` hasn't actually persisted one yet, regardless of what a plan looked like earlier in this conversation — say so and recommend `/plan` rather than reconstructing it from chat memory (`rules/core/common-rules.md`'s Chat context is not state). Only when no task file exists at all, take the plan already produced in this conversation, and say plainly that nothing is persisted yet. Read the file's acceptance criteria along with it — they drive decomposition, not just the Changes list.
- Decompose into the minimum reasonable number of slices. A slice is a meaningful, independently verifiable unit of work, not a coding step — do not list file-by-file implementation actions unless one is needed to mark a slice boundary. Prefer slices that each move one or more acceptance criteria toward verified, over slices organized by implementation layer (e.g. "models", "services", "tests" as separate slices).
- Do not create artificial micro-slices. A small, well-understood plan can be a single slice — don't force decomposition.
- Every acceptance criterion from the plan should be covered by at least one slice's `Covers:`. Flag any criterion with no covering slice instead of silently leaving it unaddressed.
- The slice map is an initial execution map, not a contract: `/next` may split, merge, reorder, or re-estimate slices as execution surfaces new information.
- Do not write implementation code.
- Estimate in story points, not time (hours/days). Use the Fibonacci-like scale 1, 2, 3, 5, 8, 13, 21 — points reflect relative effort/complexity/uncertainty, not calendar duration. Never output a time unit.
- A slice's points cover implementation and its verification together — writing/running tests, integration or E2E setup, load/performance runs where a criterion calls for them. Don't estimate coding effort only and treat verification as free. Flag when a criterion's verification method (e.g. load testing, E2E setup) materially dominates a slice's cost.
- A slice above ~8 points is a signal it's too coarse — prefer splitting it rather than reporting a single large-point estimate.
- Expose the assumptions and unknowns each estimate depends on.
- State each slice's verification criteria concretely enough for `/verify` to check against — not a restatement of the goal. Refine the plan's method/level (e.g. "integration test") into the concrete check this slice must pass where that's already knowable; leave it at method/level otherwise.
- Do not fabricate historical data. If none exists, say so instead of inventing it.
- Do not modify files, except the task's Task Context file: writing the slice map into its `Slices` section; initializing `status: READY`, current slice 1/total, and each acceptance criterion's `Result: NOT_VERIFIED` the first time a slice map is created for it; and appending the post-work Record into its `Execution History` — see `rules/core/task-context.md`'s Ownership section (AI-managed row) and `rules/core/execution-state.md`'s Execution History format section. Follow `rules/core/common-rules.md`'s Persist-before-report — the slice map isn't reportable until it's written and re-read back.
- Pre-work: append `PHASE_STARTED | estimate` at the start; when `status` is initialized to `READY` for the first time, append `STATE_CHANGED | estimate | (none) → READY`; once the slice map is written, append `PHASE_COMPLETED | estimate` and set `phase: estimate` in frontmatter. If the pass stops short of a written slice map (e.g. the plan itself is missing or a criterion has no coverable slice), append `SKILL_FAILED` instead before ending the turn (`rules/core/common-rules.md`'s Blocked or incomplete runs still write history). Post-work: no new event type applies — the existing Record itself is already the structured entry for that case (`rules/core/execution-state.md`'s Execution History format).
- Stay focused on this task's plan and criteria. Don't spawn subagents or search the repository broadly.

## Output — pre-work

Begin with the Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>`.

Keep it minimal. A small, well-understood plan can collapse to a single slice, or even one line — don't pad it.

Give each slice a short id (S1, S2, …) so `/next` and `/status` can reference it tersely.

Per slice:
```
### <slice name>
Goal: <one line>
Scope: <files/areas>
Depends on: <other slice(s) — omit if none>
Covers: <acceptance criterion id(s) this slice verifies — omit only if the slice has no directly attributable criterion>
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

Keep this structured and terse — it's meant to be reusable as historical estimation data later, not prose. When the task has a Task Context file, append this record under its `Execution History`.
