---
name: audit
description: Inspect the current repository and recommend a small number of high-value, evidence-based Claude Code customizations — rules, skills, hooks, subagents, MCP, tooling. Conservative by design; advisory only, never installs or modifies anything.
---

# Audit

Inspect this repository and recommend the minimum set of project-specific Claude Code customizations actually justified by its structure and recurring friction. This is not a "recommend everything possible" checklist — most repos should get few or zero recommendations.

## Rules

- Advisory only. Never install, configure, or modify anything — no files, no `CLAUDE.md`, no settings, no plugins, no hooks, no MCP servers, no skills, no subagents.
- Inspect before recommending: repo structure, languages/frameworks, package/dependency files, test setup, linting/type checking, CI configuration, Docker/container configuration, database usage, API boundaries, frontend/backend separation, monorepo structure, scripts/Makefiles, and any existing Claude configuration (skills, rules, hooks, MCP, agents). Inspect only enough to justify recommendations, not exhaustively.
- Every recommendation must cite concrete evidence from the repository. Never invent project requirements or recommend infrastructure the repo gives no evidence for.
- Do not recommend automation just because it's technically possible — only for actual recurring friction or a real capability gap.
- Do not duplicate an existing ai-toolkit-max rule, skill, or capability.
- Prefer existing capabilities over new ones — check what's already configured before recommending something that overlaps it.
- Prefer rules for stable principles, skills for explicit reusable workflows, hooks only for deterministic checks or repeated automatic actions, MCP only when Claude genuinely needs external system access, subagents only when isolation or parallel work gives a real benefit.
- Maximum 5 recommendations. Fewer is fine — say so plainly when nothing meaningful is missing.

## Output

### Project profile
2-4 very short bullets on what materially matters for Claude Code usage here — not a general repo summary.

### Recommendations
Only recommendations with clear value, most valuable first. Max 5.

For each:
```
### <recommendation>
Type: rule | skill | hook | subagent | MCP | LSP | plugin | tooling
Why: <one short line>
Evidence: <what in the repo justifies it>
Priority: High | Medium
Action: <what should be added or changed>
```

If nothing meaningful is missing: "No project-specific automation is justified yet."

### Not recommended
Only things that might look tempting but would add unnecessary complexity. Keep very short — omit if nothing worth flagging.
