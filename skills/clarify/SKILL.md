---
name: clarify
description: Turn a business request into a draft Acceptance Contract — candidate acceptance criteria classified CONFIRMED/INFERRED/UNKNOWN, their verification approach, and the questions needed to resolve what's still open. Entry point for acceptance criteria; `/plan` promotes this draft.
---

# Clarify

Turn the current business request into a draft Acceptance Contract: candidate acceptance criteria, their status, and the questions needed to resolve what's still open. This is the entry point for acceptance criteria in the workflow — `/plan` later promotes this draft into `.ai/plan.md`.

## Rules

- Do not modify files.
- Do not write implementation code.
- Do not invent business requirements — an inferred criterion is a hypothesis to confirm, never a decision.
- Use the existing repository context when relevant.
- For each candidate acceptance criterion, classify its requirement status:
  - `CONFIRMED` — explicitly stated by the requester.
  - `INFERRED` — a reasonable implication, not yet confirmed. Never silently treat as CONFIRMED, here or in any later step.
  - `UNKNOWN` — cannot be safely determined from what's given.
- Where a criterion's verification approach is reasonably clear, name it as a category — method (automated/manual/exploratory) and level (unit/integration/e2e/contract/performance/security/static analysis/migration/other) — not a concrete test. Leave it open if the method itself depends on an open question (e.g., a performance criterion with no stated target).
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
