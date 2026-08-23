---
name: debug
description: Investigate a bug, failing test, error, or unexpected behavior by finding the root cause before proposing a fix.
---

# Debug

Investigate the current problem systematically.

## Rules

- Reproduce the problem when possible.
- Inspect relevant code, tests, logs, and recent changes.
- If runtime/infrastructure evidence would settle the root cause faster (production errors, database state, browser runtime) and the matching MCP is configured, use it per `rules/core/capabilities.md`. Never invent access to one that isn't configured — fall back to local evidence instead.
- Form hypotheses based on evidence.
- Prefer root-cause analysis over symptom fixing.
- Do not modify files until the root cause is reasonably understood.
- Avoid speculative fixes.
- Consider related edge cases and regression risks.
- If the root cause reveals a new edge case or a decision worth not rediscovering (not just "how this particular bug was fixed"), persist it into the task's Task Context file's `Edge Cases`/`Decisions` section — reconcile first (re-read the file fresh). Don't log the investigation itself; only the durable fact.
- Keep the investigation proportional to the problem.

## Output

Keep the investigation concise.

### Symptom
What is failing.

### Evidence
The relevant observations.

### Root cause
The most likely cause, with confidence.

### Fix
The minimal appropriate fix.

### Regression risk
What else could be affected.

If reproduction or evidence is insufficient, clearly state what is missing.
