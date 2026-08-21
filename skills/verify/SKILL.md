---
name: verify
description: Verify the current implementation slice with objective evidence — tests, lint, types, build — before moving forward. Distinguishes PASS, FAIL, and UNKNOWN; never claims success without evidence.
---

# Verify

Establish ground truth for the current slice. Objective evidence only.

## Rules

- Do not modify files except `.ai/state.md`. See `rules/core/execution-state.md`.
- Do not write implementation code — fixing failures is `/debug`'s job, not this skill's.
- Run whatever the repo actually has: tests, lint, type checking, build, or other relevant commands. Don't assume tooling that isn't there.
- Every result is PASS, FAIL, or UNKNOWN. Never claim something works without having run it. Mark UNKNOWN rather than guessing when a check isn't feasible.
- Scope evidence to the current slice's actual diff — don't attribute unrelated changes to it, and flag unrelated changes if present.
- Note real coverage gaps briefly; don't pad the report with obvious ones.
- Do not decide what happens next — that's `/next`.

## Output

Keep it concise.

```
Verification:
- tests: PASS/FAIL/UNKNOWN
- lint: PASS/FAIL/UNKNOWN
- types: PASS/FAIL/UNKNOWN
(only the checks that apply)
```

Potential gap: <only if real, one line — omit otherwise>
