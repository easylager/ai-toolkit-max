# Context Pack

Stage-aware, lazy-loaded reading contract for Task Context files. Replaces loading the full task file on every skill invocation with the minimum sections the current stage actually needs.

Full schema and ownership remain in `rules/core/task-context.md`. Nothing is deleted — sections not listed for a stage are **deferred**, not omitted.

## Always read (every stage)

Frontmatter fields: `task_id`, `title`, `status`, `phase`, `execution_mode` (if set).

Sections:
- `# Task` → `## Objective` (first paragraph only)
- `## Next Action`
- `## Blockers` (if non-empty)
- `## Human Overrides` (if non-empty since last read)
- Last **5** lines of `## Execution History` (not the full history)

## Stage-specific (load only when entering this stage)

| Stage | Additional sections |
|---|---|
| `clarify` | Scope (In/Out), Open Questions, Acceptance Criteria (Requirement axis only) |
| `plan` | Acceptance Criteria (full), Design Context, Assumptions, Constraints |
| `estimate` | Technical Plan, Acceptance Criteria, Test Strategy |
| `implement` / `next` | Current slice from Slices, Covers AC ids, Progress |
| `verify` | Acceptance Criteria for slice's Covers ids only, Test Strategy |
| `review` | Acceptance Criteria (Result axis), Progress summary |
| `design` / `creative-explore` | Design Context, Decisions, `creative_autonomy` |
| `design-review` | Design Context pointer, latest DESIGN artifact status |
| `reconcile` | Acceptance Criteria (Result + Verified at), git diff vs last_verified_commit |
| `execute` (Supervisor) | Compact pack above + whatever the next single phase requires per Phase completion table in `rules/core/execution-state-supervisor.md` |

## Lazy-load on demand

Load these only when the stage's decision actually requires them — never preemptively:

- Full `## Execution History` (beyond last 5 lines)
- Full `## Technical Plan`
- Full `## Design Context`
- Full `## Progress`
- All `## Slices` (when not in implement/next)
- `## Edge Cases`, `## Assumptions`, `## Decisions` (unless clarify/plan/design stage)

When a skill needs a deferred section, read it then — one targeted Read call, not upfront.

## Archive trigger

If `## Execution History` exceeds **50 lines**, archive older entries to `.ai/tasks/archive/TASK-NNN-history.md` (keep last 20 lines in the main file). `/execute` and `/reconcile` perform this check; other skills may recommend it.

## Reconciliation still applies

Lazy loading does not skip reconciliation. Re-read frontmatter + Always-read sections fresh off disk before acting — per `rules/core/task-context.md`'s Detecting human edits section.
