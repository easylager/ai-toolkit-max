---
name: classify
description: Entry point of the adaptive workflow. Assess a task's complexity, risk, and blast radius, then recommend the minimum workflow depth needed — which existing skills to run, in what order. Does not clarify, plan, estimate, write code, test, or review.
---

# Classify

Assess the task and recommend the minimum workflow depth needed to handle it safely. This is the entry point — it decides how much process the task deserves, nothing else.

## Rules

- Do not modify files.
- Do not clarify requirements, produce a plan, estimate effort, write code, design tests, or review results — recommend the skill for that instead of doing it.
- Assess only the dimensions that materially affect workflow depth: complexity, uncertainty, risk, blast radius, architectural impact, external dependencies, data/persistence impact, security sensitivity, reversibility. Omit any dimension that isn't material to this task.
- Use qualitative levels (Trivial/Low/Medium/High), not scores or narrative.
- Base the assessment on the task description and repository context — do not assume business intent that isn't stated.
- Match process depth to task complexity: recommend the minimum defensible workflow, not the maximum available. A trivial task should recommend just `implement → verify`.
- Reference only existing skill names in the recommended chain (`clarify`, `design`, `plan`, `impact`, `estimate`, `challenge`, `next`, `verify`, `status`, `test`, `review`, `debug`, `short`) — never invent a new one. `implement` may also appear in the chain, but it is not a toolkit skill: it denotes Claude's native code-writing behavior and has no SKILL.md.
- Recommend `design` only for tasks that are visibly UI/frontend-facing (a new screen, dashboard, form, or layout change) — omit it from the chain for backend-only or non-visual work.
- Mention potential capabilities (MCP, filesystem, database, cloud, browser, external APIs) only if the task plausibly needs them. Never install, configure, or assume access to any of them.
- Keep the output short — this is a routing decision, not an analysis.

## Output

### Assessment
One line per material dimension: `<Dimension>: <Trivial/Low/Medium/High>`, with a short reason only if non-obvious. Omit dimensions that don't apply.

### Recommended workflow
A single chain, left to right in execution order, using only the skill names above and/or `implement`.

### Potential capabilities
Only if the task plausibly needs something beyond the local filesystem. Omit otherwise.
