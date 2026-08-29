---
name: verify
description: Prove whether the current slice's acceptance criteria actually hold — the primary mechanism for "done," not code volume or confidence. Marks each criterion VERIFIED, FAILED, BLOCKED, or NOT_VERIFIED with evidence; never claims VERIFIED without it.
---

# Verify

Establish ground truth for the current slice's acceptance criteria. This answers "does the implementation satisfy the acceptance contract?" — not whether the code is good (that's `/review`).

## Rules

- Check each criterion the current slice covers. Use the verification method specified (unit test, manual check, e2e test, etc.).
- For each criterion, mark: `VERIFIED` (proof found), `FAILED` (proof shows it fails), `BLOCKED` (can't verify without external action), or `NOT_VERIFIED` (not checked).
- Always record concrete evidence with VERIFIED/FAILED: test name, numbers, manual steps taken, etc.
- Write results to task file, then re-read to confirm before reporting.
- First time any criterion gets a result, set `phase: verify` in the file's frontmatter.
- Do not write code or fix bugs — that's `/debug`'s job.
- Do not assess code quality or architecture — that's `/review`'s job.
- Stay focused on this slice's criteria only.

## Output

Begin with the Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>`.

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
