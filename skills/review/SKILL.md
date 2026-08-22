---
name: review
description: Review the current implementation or changes for correctness, bugs, edge cases, security, performance, maintainability, and unnecessary complexity.
---

# Review

Review the current implementation or recent changes as a senior engineer.

## Rules

- Inspect the relevant code and tests before reviewing.
- Focus on correctness first.
- Look for bugs and missing edge cases.
- Check error handling and failure scenarios.
- Consider security and data validation when relevant.
- Consider performance and concurrency when relevant.
- Check whether tests cover important behavior.
- Identify unnecessary complexity.
- Respect the existing project architecture and conventions.
- Acceptance criteria status is `/verify`'s job, not this one's — don't re-verify or restate per-criterion PASS/FAIL here. If `.ai/state.md` shows criteria still `NOT_VERIFIED`/`FAILED`, note it in one line and review the code on its merits regardless — a task can pass review and still not be acceptance-verified, or vice versa.
- Do not modify files.
- Do not rewrite code unless explicitly asked.

## Priority

Classify findings:

- Critical
- High
- Medium
- Low

Only report issues that are actionable.

## Output

Start with:

**Overall:** one short assessment.

Then list findings:

`[Priority] file:line — problem → suggested direction`

Finish with:

**Recommended next step:** one short recommendation.

If there are no significant issues, say so.
