---
name: plan
description: Create a concise implementation plan for the current feature, anchored to its acceptance criteria — mapping each criterion to the changes and verification that satisfy it.
---

# Plan

Create an implementation plan for the current task, built around its Acceptance Contract rather than around code to write.

## Workflow

Planning is lightweight and targeted, not exhaustive:

1. **Understand** the task and existing context (Task Context file, `/clarify` draft, or request itself).
2. **Identify** the smallest set of files/components likely affected by the change. If the task file's `Comprehension Tips` already cover this, use them instead of re-deriving it.
3. **Search targeted areas** for existing patterns, dependencies, and related code — but only for what `Comprehension Tips` doesn't already answer. Where they're silent or stale, search directly — Bash/Read/Grep in the main agent's context only (no background/sub-agents spawned by default). If a gap is substantial enough to be worth a dedicated pass, recommend `/research` rather than absorbing it here.
4. **Inspect only relevant code** — avoid scanning whole repository or reading large unrelated files; skip re-reading what `Comprehension Tips` already established as fact.
5. **Identify risks and acceptance criteria coverage** — trace each criterion to a change or test.
6. **Write the plan** and stop.

Sub-agents/background-agents are **off by default**: only spawn one if the user explicitly requests it, or if the task genuinely requires independent investigation the main agent cannot reasonably do inline. When spawning, state why before doing so. Prefer the minimum (typically one agent, rarely more).

## Rules

- Reuse existing patterns and abstractions when appropriate.
- Before finalizing Changes on a UI-facing task, check this conversation for an `APPROVED` `/design` prototype and use it as the primary UI source. If none exists, check whether an available external capability would materially reduce implementation uncertainty — design context (Figma), current library documentation (Context7), related PRs/issues (GitHub) — per `rules/core/capabilities.md`. Use it only if it changes what gets built; never invent access to one that isn't configured.
- Take the task's Task Context file as the starting point when one exists (reconcile first — re-read it fresh, note any human edits per `rules/core/task-context.md`) — its persisted content always overrides anything this conversation recalls, including this skill's own earlier output in the same chat. Only when no task file exists yet: take `/clarify`'s draft from this conversation, or derive criteria directly from the request using the same CONFIRMED/INFERRED/UNKNOWN classification (see `skills/clarify/SKILL.md`) — and say plainly that nothing is persisted yet (`rules/core/common-rules.md`'s Chat context is not state).
- Only promote an `INFERRED` criterion to `CONFIRMED` if the conversation actually confirmed it — never upgrade a status just because a plan is being written. Carry unresolved `INFERRED`/`UNKNOWN` criteria forward as-is.
- Every meaningful acceptance criterion must be traceable to at least one entry in Changes or Tests. Flag any criterion with no implementation or verification path instead of silently dropping it.
- If an `UNKNOWN` criterion would block safe implementation, do not plan around a guessed default — say so and stop short of "Ready to implement" instead.
- Do not modify files, except the task's Task Context file when persisting a multi-slice plan. The first time a task's plan is persisted, assign it the next sequential `TASK-NNN` id (per `rules/core/task-context.md`) and create its file with the acceptance criteria (id, description, requirement status, verification method/level, capability hint if any) plus `Technical Plan`/`Design Context`/`Test Strategy`; reuse the existing id and file, updating those same sections, when refining an already-persisted plan. See `rules/core/execution-state.md` and `rules/core/task-context.md`.
- Follow `rules/core/common-rules.md`'s Persist-before-report: the plan is not "done" until it's written to the file and re-read to confirm. Showing the Acceptance Criteria / Approach / Changes sections in chat is never a substitute for that write — if this pass ends short of "Ready to implement" (see below), the output must say explicitly that nothing new was persisted, not just show the same sections a persisted plan would show.
- Append a `TASK_CREATED` `Execution History` event only if this call is what created the file (not if `/clarify` or `/task` already did). Append `PHASE_STARTED | plan` at the start of this pass. Once the Technical Plan and finalized Acceptance Criteria are actually persisted, append `PHASE_COMPLETED | plan` and set `phase: plan` in frontmatter. If the pass stops short of that (a blocking `UNKNOWN`, an unresolved dependency), append `HUMAN_GATE` instead before ending the turn — never leave a `PHASE_STARTED` with no matching close (`rules/core/common-rules.md`'s Blocked or incomplete runs still write history).
- Do not write implementation code.
- Avoid unnecessary architecture and dependencies.
- Prefer the smallest design that satisfies the requirements.
- Call out important technical risks or trade-offs.
- Do not repeat requirements that are already obvious.

## Output

Begin with the Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>` — omit only if no task file exists yet and none was created this pass. If this pass did not persist anything (stopped short of "Ready to implement"), say so right after the header — e.g. `Not persisted — <reason>` — before showing any of the sections below, so they're never mistaken for saved state.

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
Capability: <MCP hint per rules/core/capabilities.md — omit if the built-in toolchain is sufficient>
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

**Ready to implement** — only once the plan is actually persisted per the rules above.

or list what still needs clarification — including any blocking `UNKNOWN` criterion — and state plainly that this pass persisted nothing.
