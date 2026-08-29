# Using the Updated Classify Skill

## Overview

The updated `classify` skill now provides:

1. **Task Profile** — qualitative assessment of task characteristics (complexity, uncertainty, risk, etc.)
2. **Recommended Strategy** — YAML structure with flags for `state_required`, `research_required`, `research_areas`, etc.
3. **Workflow Chain** — the minimum-necessary sequence of skills/implement to solve the task

## Key Insights from Strategy Output

### `state_required`
- `false`: Task is simple and self-contained; no need to create `.ai/task-*.md` context file
- `true`: Task needs persistent state to track research findings, decisions, or complex workflow steps

### `research_required`
- `false`: Task description is complete; can proceed directly to planning or implementation
- `true`: Need to study repository structure, patterns, or implementation details — `/research` runs next

### `research_areas` (only if `research_required: true`)
Conceptual hints about what's uncertain, not a file/class/technology list — `/research` is what discovers those:
- Topic types (e.g., "error handling patterns")
- Architectural aspects (e.g., "dependency graph")
- Implementation concerns (e.g., "migration strategy")

`/research` itself decides whether an area is investigated directly or delegated to a subagent — classify never predicts this.

### `planning_required`
- `false`: Can go directly from clarification (if needed) to implementation
- `true`: Task warrants structured planning via `/plan` skill

### `clarification_required`
- `false`: Task description is clear; skip `/clarify`
- `true`: Task has ambiguities; run `/clarify` before planning/implementation

### `verification_level`
- `"standard"`: Normal verification via `/verify` (functional testing, smoke tests)
- `"elevated"`: Extra scrutiny needed due to risk, complexity, or impact (security-sensitive code, refactors, payment systems, migration, etc.)

## Workflow Example

For a **medium-complexity logging task**:
- Classify recommends: `research → clarify → plan → implement → verify`
- `state_required: true` means we create `.ai/task-*.md` and track research findings there
- `research_required: true` with `research_areas: [error handler implementation, logging patterns]` means `/research` investigates those areas and persists a compact summary to `Research Notes`
- `planning_required: true` means `/plan` structures the approach before implementation, reusing what `/research` already found

## Next Steps

1. Test classify on real tasks (see `test-cases.md` for examples)
2. Verify that strategy recommendations align with actual task difficulty
3. Once confident, integrate strategy output into task creation workflow (`.ai/task-*.md` header)
