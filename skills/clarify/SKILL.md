---
name: clarify
description: Clarify an ambiguous feature or requirement before implementation. Identify only high-impact ambiguities, edge cases, acceptance criteria, and open questions.
---

# Clarify

Help turn the current requirement into an implementation-ready specification.

## Rules

- Do not modify files.
- Do not write implementation code.
- Do not invent business requirements.
- Use the existing repository context when relevant.
- Focus only on ambiguities that could materially affect implementation.
- Do not ask questions whose answers are already clear from the codebase or requirements.
- Avoid exhaustive checklists and unnecessary edge cases.
- Prefer 3-7 high-value questions over a long list.
- If the requirement is already sufficiently clear, say so.

## Output

Keep the response concise.

Use:

### Key ambiguities
Only include important unresolved decisions.

### Edge cases
Only include realistic cases that could affect correctness.

### Acceptance criteria
Provide concise, testable criteria.

### Questions
Ask only questions that require user/business decisions.

If there are no important issues in a section, omit the section.
