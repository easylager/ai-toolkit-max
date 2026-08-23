---
name: clarify
description: Turn a business request into a draft Acceptance Contract — candidate acceptance criteria classified CONFIRMED/INFERRED/UNKNOWN, their verification approach, and the questions needed to resolve what's still open. Entry point for acceptance criteria; `/plan` promotes this draft.
---

# Clarify

Turn the current business request into a draft Acceptance Contract: candidate acceptance criteria, their status, and the questions needed to resolve what's still open. This is the entry point for acceptance criteria in the workflow — `/plan` later promotes this draft into the task's Task Context file.

## Rules

- The only file this may create or update is the current task's Task Context file (`rules/core/task-context.md`) — create it (allocating `TASK-NNN`, same allocation rule `/plan` uses) once clarification is worth persisting, or update its `Objective`/`Scope`/`Acceptance Criteria`/`Edge Cases`/`Assumptions`/`Open Questions` if it already exists. Reconcile first: re-read the file fresh and note any human edits before adding to it. Never write implementation code or any other file.
- Do not invent business requirements — an inferred criterion is a hypothesis to confirm, never a decision.
- Use the existing repository context when relevant.
- If an external system plausibly holds the authoritative requirement (a Linear/Jira/GitHub issue, a Notion spec) and is available in this session, retrieve it before drafting criteria or questions — see `rules/core/capabilities.md`. Never invent access to a system that isn't configured; if the likely source is unavailable, say so only if it materially affects confidence in the draft.
- For each candidate acceptance criterion, classify its requirement status:
  - `CONFIRMED` — explicitly stated by the requester.
  - `INFERRED` — a reasonable implication, not yet confirmed. Never silently treat as CONFIRMED, here or in any later step.
  - `UNKNOWN` — cannot be safely determined from what's given.
- Where a criterion's verification approach is reasonably clear, name it as a category — method (automated/manual/exploratory) and level (unit/integration/e2e/contract/performance/security/static analysis/migration/other) — not a concrete test. Leave it open if the method itself depends on an open question (e.g., a performance criterion with no stated target).
- If the method points to a specific external capability (browser automation, production error data, a database check), name it per `rules/core/capabilities.md` — a hint for later verification, never a requirement. Omit if the built-in toolchain is sufficient.
- Turn each `UNKNOWN` and each open decision into a targeted question aimed at the inference, not a blank prompt — "I inferred X, is that right?" rather than "what should happen?". Reference which criterion(s) or missing criterion each question affects.
- If an `UNKNOWN` criterion would block safe implementation (behavior materially diverges depending on the answer), say so plainly rather than guessing or picking a default.
- Avoid exhaustive checklists. Prefer 3-7 high-value criteria and questions over a long list.
- If the request is already sufficiently clear — criteria confirmed, no material open questions — say so and skip the sections that would otherwise be empty.

## Output

Keep the response concise.

### Acceptance criteria
Per criterion:
```
AC-<NNN>
<one-line, testable description>
Status: CONFIRMED | INFERRED | UNKNOWN
Verification: <method/level — omit if it depends on an open question>
Capability: <MCP hint per rules/core/capabilities.md — omit if the built-in toolchain is sufficient>
```

### Open questions
Only unresolved decisions that materially affect implementation or verification.
```
Q-<NNN>
<question, phrased against an inferred criterion or gap where possible>
Affects: <AC id(s) and/or "missing criterion">
```

### Edge cases
Only realistic cases that could affect correctness. Omit if none.

If nothing important is unresolved, say so instead of producing empty sections.
