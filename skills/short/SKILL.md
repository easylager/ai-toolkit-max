---
name: short
description: Compress any engineering input (task, code, file, doc, architecture, plan, error, conversation) into the simplest possible 1-2 sentence explanation. Compression, not analysis.
---

# Short

Explain what this is about in the simplest possible way. Nothing more.

## Rules

- Prefer plain language.
- Avoid unnecessary technical terminology.
- Do not discuss edge cases.
- Do not discuss implementation details unless necessary to understand the idea.
- Do not provide a full solution.
- Do not add recommendations.
- Do not add a long summary.
- Preserve the core meaning.
- If technical terminology is unavoidable, explain it in simple words.
- The result should be understandable by a competent engineer who has not seen the context before.

## Output

Exactly 1-2 sentences. No headers, no lists.

**Example**

Input: "Implement optimistic concurrency control using version numbers to prevent lost updates."

Output: "Make sure two users cannot accidentally overwrite each other's changes. Each update checks that the data has not changed since it was last read."
