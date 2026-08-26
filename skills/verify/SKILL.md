---
name: verify
description: Prove whether the current slice's acceptance criteria actually hold — the primary mechanism for "done," not code volume or confidence. Marks each criterion VERIFIED, FAILED, BLOCKED, or NOT_VERIFIED with evidence; never claims VERIFIED without it.
---

# Verify

Establish ground truth for the current slice's acceptance criteria. This answers "does the implementation satisfy the acceptance contract?" — not whether the code is good (that's `/review`).

## Rules

- Do not modify files except the task's Task Context file — each in-scope criterion's `Result`, `Evidence`, and `Verified at`. See `rules/core/task-context.md`'s Ownership section (AI-managed row) and `rules/core/execution-state.md`'s Acceptance criteria section (for the `Result` axis).
- Do not write implementation code — fixing failures is `/debug`'s job, not this skill's.
- This is bounded to the current slice's acceptance criteria, not an open-ended investigation: no repository-wide search beyond what proves those criteria, no subagent or background-agent spawning, no invoking the Supervisor decision model directly (that's `/execute`'s) — the checks and tests this skill's own contract requires are still expected, not forbidden.
- Verify against the acceptance criteria the current slice covers — from the slice map's `Covers:` field and the task file's Acceptance Criteria section (or `/next`'s READY report) — not just whatever tests happen to run.
- Use the verification method/level assigned to each criterion (unit, integration, e2e, contract, performance, security, static analysis, migration, manual, exploratory, or other). Run it if it's automatable in this repo; inspect/reason through it if it's manual or exploratory. Don't force a unit test onto a criterion that needs a different kind of proof, and don't skip a criterion just because it isn't automatable — a manual check with a clearly stated basis is still evidence.
- If the criterion carries a capability hint (browser automation, production error data, a database check — see `rules/core/capabilities.md`) and that MCP is configured in this session, use it. If it isn't, use the best available alternative that still proves the criterion; only mark the criterion `BLOCKED` on a missing capability when no adequate alternative exists.
- Every criterion in scope gets exactly one status:
  - `VERIFIED` — evidence obtained and it confirms the criterion.
  - `FAILED` — evidence obtained and it contradicts the criterion.
  - `BLOCKED` — cannot be verified without something external (environment, access, a missing decision).
  - `NOT_VERIFIED` — not checked this pass. Distinct from FAILED — don't conflate "didn't run" with "ran and failed." A criterion `/reconcile` marked `STALE` is treated the same as `NOT_VERIFIED` here — re-check it and set one of the four statuses above.
- Never mark a criterion VERIFIED without evidence. State the evidence tersely — the concrete check run and its result (test name and outcome, load-test numbers, the manual steps taken, or the capability that produced it — a Playwright run, a Sentry event, a Postgres query) — not a restatement of the criterion. Record the commit SHA and date as `Verified at` — this is what lets `/reconcile` detect staleness later.
- Append one `AC_RESULT` `Execution History` event per criterion checked this pass (`AC-NNN <RESULT> — evidence: <short>`, same evidence as above — never "tests passed" standing in for it), then one summary `VERIFICATION` event (`<n>/<m> criteria verified`) once the pass is done (`rules/core/execution-state.md`'s Execution History format).
- Scope evidence to the current slice's actual diff — don't attribute unrelated changes to it, and flag unrelated changes if present.
- Do not decide what happens next (that's `/next`) and do not assess code quality/architecture/maintainability (that's `/review`) — acceptance status only.

## Output

Keep it concise.

```
Acceptance:
AC-<NNN> VERIFIED | FAILED | BLOCKED | NOT_VERIFIED
  Evidence: <concrete, one line — omit only for NOT_VERIFIED/BLOCKED>
(one entry per criterion this slice covers)
```

Supporting checks actually run (tests/lint/types/build), only where they aren't already stated as evidence above:
```
- <check>: PASS/FAIL/UNKNOWN
```

Overall: `<n>/<m> criteria verified for this slice`.

Potential gap: <only if real, one line — omit otherwise>
