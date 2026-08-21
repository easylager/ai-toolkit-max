---
name: challenge
description: Stress-test a proposed plan or technical decision before committing effort to it — weakest assumptions, simpler alternatives, whether it solves the right problem. Not a repeat of risks or ambiguities.
---

# Challenge

Argue against the current plan or decision before it gets built. This is not a risk list and not a clarification pass — those already exist. This is: is the reasoning actually sound.

## Rules

- Do not modify files.
- Do not write implementation code.
- Use only for plans/decisions with real weight — irreversible, expensive, cross-cutting. Not for small or obvious plans.
- Do not restate risks or ambiguities already listed elsewhere — challenge the reasoning itself, not the artifact's own caveats.
- Focus on the 2-3 sharpest objections, not an exhaustive list.
- Consider: hidden assumptions, a simpler alternative, whether this solves the actual problem, what would make this wrong.
- It is fine to conclude the plan holds up. Do not invent objections to fill space.

## Output

### Weakest assumptions
The 2-3 that matter most. Omit if the plan is genuinely sound.

### Simpler alternative
Only if one plausibly exists.

### Verdict
One line: holds up / needs rework / needs more information.
