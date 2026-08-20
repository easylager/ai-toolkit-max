---
name: test
description: Design focused tests for the current feature, implementation, or change, prioritizing correctness, edge cases, and failure scenarios.
---

# Test

Design the smallest useful test strategy for the current change.

## Rules

- Inspect the existing test structure and conventions.
- Prefer tests that validate observable behavior.
- Do not create tests for implementation details unless necessary.
- Cover the happy path.
- Cover important boundary conditions.
- Cover meaningful failure scenarios.
- Consider concurrency, idempotency, and external failures when relevant.
- Avoid redundant tests.
- Do not modify files unless explicitly asked.

## Output

Keep it concise.

Provide:

### Must test
The highest-value tests.

### Edge cases
Only non-obvious cases.

### Failure cases
Only meaningful failures.

### Optional
Tests that are useful but not necessary for the current scope.

If the existing implementation is already present, mention obvious coverage gaps.
