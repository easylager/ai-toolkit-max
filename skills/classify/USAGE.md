# Using Classify

## Overview

`classify` is the workflow entry point. It analyzes a task description and recommends the minimum-necessary strategy — then, if that strategy needs persistent state, creates or updates the task's Task Context file (`.ai/tasks/TASK-NNN.md`, per `rules/core/task-context.md`) and writes the strategy into its `Strategy` section.

## Strategy fields

### `state_required`
- `false`: trivial task — no task file is created at all (`rules/core/execution-state.md`: "Create `.ai/` lazily").
- `true`: task needs a persisted Task Context file — `classify` creates/updates it and writes `Strategy`.

### `research_required`
- `false`: task description is complete; proceed directly to planning or implementation.
- `true`: repository structure/patterns/implementation details are uncertain — `/research` runs next.

### `research_areas` (only if `research_required: true`)
Conceptual hints about what's uncertain, never a file/class/technology list — `/research` discovers those:
- Topic types (e.g., "error handling patterns")
- Architectural aspects (e.g., "dependency graph")
- Implementation concerns (e.g., "migration strategy")

`/research` itself decides whether an area is investigated directly or delegated to a subagent — classify never predicts this.

### `clarification_required`
- `false`: task is clear; skip `/clarify`.
- `true`: task has ambiguities; run `/clarify` before planning/implementation.

### `planning_required`
- `false`: go directly from clarification (if any) to implementation.
- `true`: task warrants a structured plan via `/plan`.

### `verification_level`
- `standard`: normal `/verify` (functional testing, smoke tests).
- `elevated`: extra scrutiny — security-sensitive code, refactors, payment systems, migrations.

## Examples

### Trivial task — no task file
```
/classify "fix typo in README"
→ state_required: false — nothing persisted
→ Chain: implement → verify
```

### Medium task
```
/classify "add email notifications to alert system"
→ Creates TASK-001, writes Strategy:
    research_required: true, research_areas: [alert dispatch mechanism, email service integration patterns]
    clarification_required: true, planning_required: true
→ Chain: research → clarify → plan → implement → verify
→ Run with: /execute TASK-001
```

### Complex task
```
/classify "refactor auth middleware to comply with new token storage requirements"
→ Creates TASK-002, verification_level: elevated
→ Chain: research → clarify → plan → implement → review → verify
→ Run with: /execute TASK-002
```

## How later phases use it

- `/research` reads `Strategy`'s `research_areas`, investigates, writes `Comprehension Tips`.
- `/clarify` reads `Comprehension Tips` before asking questions — doesn't re-ask what's already answered.
- `/plan` reads `Comprehension Tips` before searching the repo — doesn't re-derive what's already known.
- `/execute TASK-NNN` reads `Strategy`'s chain to decide which skill runs next, phase by phase.
