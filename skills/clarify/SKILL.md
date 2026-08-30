---
name: clarify
description: Turn a business request into a draft Acceptance Contract — candidate acceptance criteria classified CONFIRMED/INFERRED/UNKNOWN, their verification approach, and the questions needed to resolve what's still open. Entry point for acceptance criteria; `/plan` promotes this draft.
---

# Clarify

Turn the current business request into a draft Acceptance Contract: candidate acceptance criteria, their status, and the questions needed to resolve what's still open. This is the entry point for acceptance criteria in the workflow — `/plan` later promotes this draft into the task's Task Context file.

## Rules

- The only file this may create or update is the current task's Task Context file (`rules/core/task-context.md`) — create it (allocating `TASK-NNN`, same allocation rule `/plan` uses, `phase: new` at creation) once clarification is worth persisting, or update its `Objective`/`Scope`/`Acceptance Criteria`/`Edge Cases`/`Assumptions`/`Open Questions` if it already exists. Reconcile first: re-read the file fresh and note any human edits before adding to it. Never write implementation code or any other file.
- Follow `rules/core/common-rules.md`'s Persist-before-report: read, reason, persist the criteria/questions to the file, re-read to confirm, only then show the Output below. Anything shown before that persist happens (e.g. thinking out loud about candidate criteria) is a draft, not a result — label it as such rather than presenting it as saved.
- When creating the task file, append a `TASK_CREATED` `Execution History` event; either way, append `PHASE_STARTED` at the start of this pass. Once the criteria are actually persisted, append `PHASE_COMPLETED` and set `phase: clarify` in frontmatter. If the pass ends without reaching that point (e.g. stopped short because a blocking `UNKNOWN` needs a human answer first), append `HUMAN_GATE` instead before ending the turn — never leave a `PHASE_STARTED` with no matching close (`rules/core/common-rules.md`'s Blocked or incomplete runs still write history).
- Do not invent business requirements — an inferred criterion is a hypothesis to confirm, never a decision.
- Use the existing repository context when relevant.
- If the task file already has `Comprehension Tips` or research-sourced `Open Questions` (`rules/core/task-context.md`), treat them as established context — don't re-derive facts `/research` already found, and don't re-ask a question it already answered. Only genuinely unresolved items become clarify questions; if `/research` left an open question still relevant, carry it forward rather than duplicating it. If `Comprehension Tips` fully answers what would otherwise need research (e.g. an `UNKNOWN` criterion's ambiguity is actually a repo fact, not a business decision), resolve it from there instead of raising a question.
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
- If compressing to the highest-value items still leaves more than ~7 genuinely open questions/`UNKNOWN`s (the request itself is broad or fuzzy, not just under-specified in one spot), don't dump the full list in one message. Persist what's already been drafted as usual, then in the output recommend going through the rest one at a time instead — name `grilling` (mattpocock-skills plugin, if installed) as a good fit for that, since it's built for exactly this: interactively stress-testing a fuzzy plan down a decision tree. This is a suggestion, never a hard handoff — `/clarify` doesn't invoke it or depend on it existing; if the user doesn't have it, offer to just go one question at a time in this chat instead.
- If the request is already sufficiently clear — criteria confirmed, no material open questions — say so and skip the sections that would otherwise be empty.

## Output (in Russian)

Task: TASK-NNN — <title>

Brief summary of what's clear and what's open:

**Требования:**
- AC-001: Description — CONFIRMED
- AC-002: Description — INFERRED (need to confirm)
- AC-003: Description — UNKNOWN (blocked on answer)

**Открытые вопросы:**
- Q-001: Question? Affects: AC-002, AC-003

**Граничные случаи** (if any):
- Edge case description

If all requirements are confirmed and no questions block implementation, say so.

If too many open questions remain (see Rules), show only the highest-value 3-7 as above, then close with, e.g.:
```
Ещё N вопросов открыто — многовато для одного захода. Разберём по одному через /grilling, или прямо здесь по очереди?
```
