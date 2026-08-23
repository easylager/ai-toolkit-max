# Task Context

The document contract for a task's persistent execution context — the human-editable counterpart to the state machine in `rules/core/execution-state.md`. One task = one file = one Obsidian note.

## Location

Resolved in this order:

1. `TASK_CONTEXT_ROOT` env var, if set — an external, possibly shared vault: `$TASK_CONTEXT_ROOT/<project-slug>/TASK-NNN.md`.
2. `.ai/config`'s `task_context_root` key, if present.
3. Default: `.ai/tasks/` inside the current project — git-committed, zero config.

`<project-slug>` is the project's repo directory name unless a `project:` frontmatter field overrides it. This is what lets multiple simultaneous projects share one external vault without collision, while staying git-native by default when no vault is configured. Whichever skill first needs to write a task file creates the resolved root directory if it doesn't exist yet — no separate setup step required.

`TASK-NNN` is allocated sequentially, same as before: highest existing id + 1, now counted from `.ai/tasks/TASK-*.md` filenames (or the resolved root's) instead of blocks in `.ai/state.md`. Never reused.

## Schema

```
---
task_id: TASK-NNN
title: <short title>
project: <slug — only needed once TASK_CONTEXT_ROOT is a shared external vault>
status: READY | EXECUTING | VERIFYING | BLOCKED | RECOVERABLE | REPLAN_REQUIRED | COMPLETE
phase: clarify | design | creative-explore | plan | estimate | implement | verify | design-review | review
priority: <optional, human-set>
creative_autonomy: HIGH | MEDIUM | LOW <optional, human-set, default HIGH — see rules/frontend/design.md and skills/creative-explore/SKILL.md>
created_at: <date>
updated_at: <date>
branch: <optional>
last_verified_commit: <optional — most recent commit any AC's evidence was checked against>
issue: <optional>
pr: <optional>
---

# Task

## Objective
## Business Context
## Scope
### In Scope
### Out of Scope
## Acceptance Criteria
### AC-NNN
<one-line, testable description>
Requirement: CONFIRMED | INFERRED | UNKNOWN
Verification method: <unit/integration/e2e/contract/performance/security/static analysis/migration/manual/exploratory/other>
Capability: <MCP hint per rules/core/capabilities.md — omit if none>
Result: VERIFIED | FAILED | BLOCKED | NOT_VERIFIED | STALE
Evidence: <concrete, one line — omit for NOT_VERIFIED>
Verified at: <commit SHA + date — omit for NOT_VERIFIED>

## Edge Cases
### EDGE-NNN
<description>
Severity: LOW | MEDIUM | HIGH
Status: OPEN | RESOLVED
Resolution: <omit while OPEN>
Verification: <omit while OPEN>

## Assumptions
## Constraints
## Decisions
### DEC-NNN
Decision: <what was decided>
Reason: <why>
Alternatives: <omit if none material>

## Design Context
## Technical Plan
## Test Strategy
## Slices
### S1 <name>
Goal:
Scope:
Depends on: <omit if none>
Covers: AC-NNN
Verification:
Estimate: <story points>
Status: READY | EXECUTING | VERIFYING | DONE

## Progress
## Blockers
## Human Overrides
## Open Questions
### Q-NNN
<question> — Affects: <AC/EDGE id(s)>

## Next Action
## Execution History
```

Per-criterion `Evidence`/`Verified at` is the only evidence store — there is deliberately no separate top-level "Evidence" section duplicating it. `Decisions` inside the task file replaces the old `.ai/decisions.md` "tag each entry with its task id" convention: the file itself is already scoped to one task.

`Requirement:` and `Result:` are two independently-owned axes on the same criterion, exactly as `rules/core/execution-state.md` defines — never conflate them, and never let implementation proceeding silently promote `Requirement` to `CONFIRMED`.

## Ownership

- **Human-controlled** — Claude proposes only when explicitly asked, never silently overwrites: `title`, `priority`, `creative_autonomy`, Objective, Business Context, Constraints, Human Overrides.
- **Shared** — Claude proposes, a human edit is authoritative: Acceptance Criteria, Edge Cases, Decisions, Test Strategy, Assumptions, Scope, Open Questions.
- **AI-managed** — Claude writes; a human can still hand-edit (e.g. to unblock): `status`, `phase`, Slices, Progress, Blockers, Next Action, Execution History.

Human edits always take precedence over an AI assumption or proposal. A human edit that directly contradicts something required elsewhere in the file is never silently resolved either way — surface it as an Open Question or `BLOCKED` reason instead of guessing which side wins.

## Detecting human edits

Before acting, re-read the task file fresh off disk — never rely on what the conversation last saw. Where the file is git-tracked, `git diff` against the AI's own last commit of that file is the primary signal: empty diff means nothing changed since Claude last wrote it; a non-empty diff not produced by the current turn means a human edited it. Where it isn't committed yet, compare structurally against what the current turn is about to write — a `Requirement`/`Result` that differs from what Claude is about to set, a new `Human Overrides` line, a manually-added AC/EDGE block — and treat that the same way.

## Reconciliation

Every skill that touches the task file reconciles first: re-read it fresh, compare against the current conversation's understanding, and look for new/changed Acceptance Criteria, new Edge Cases, changed Constraints, new Human Overrides, changed Test Strategy, or new Blockers. Material drift routes the task to `BLOCKED` or `REPLAN_REQUIRED` — the same states `rules/core/execution-state.md` already defines, never a new one. Do this at minimum before `/plan`, before starting a slice's implementation, before `/verify`, before `/review`, and whenever a session resumes a task without the conversation history that produced its current state.

## Staleness

A `VERIFIED` result is not permanent. `Verified at` records the commit SHA the evidence was checked against; if files relevant to that criterion changed since, the result is `STALE` — evidence exists but is no longer trustworthy, distinct from `NOT_VERIFIED` (never checked). `/reconcile` is the on-demand deep check for this; routine reconciliation (above) catches it opportunistically when a skill happens to look at the criterion anyway. A `STALE` criterion blocks `COMPLETE` the same way `NOT_VERIFIED`/`FAILED` does.

## Obsidian conventions

The task file's filename (`TASK-NNN`) is its Obsidian link target — link to it as `[[TASK-NNN]]` from a project note or another task, and back with a `## Related` section only when a link is actually useful, not for graph density. An optional `INDEX.md` at the root of the resolved location can list active/blocked/waiting/done tasks for quick discovery; it's a convenience note, not a source of truth — regenerate it from the task files' frontmatter rather than hand-maintaining it as a second copy of their state.

## Multi-project

Each project gets its own subtree under the resolved `TASK_CONTEXT_ROOT` (or its own `.ai/tasks/` when no external root is configured) — `project:` frontmatter plus the path itself is enough to disambiguate; no cross-project registry is needed.
