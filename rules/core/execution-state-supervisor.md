# Supervisor Decision Model

Canonical model for `/execute` only. Other skills cite specific sections of `rules/core/execution-state.md` — never this file unless orchestrating.

Referenced by: `skills/execute/SKILL.md`

## Inputs

At every boundary, read — never assume — from task file + repo:

1. Current phase and status (frontmatter).
2. Business requirements (Objective, Business Context).
3. Acceptance Criteria — both axes per criterion.
4. What's persisted for current phase vs. conversation-only.
5. Test strategy (if set).
6. Evidence (`Evidence:`/`Verified at:`, Execution History).
7. Human context since last decision (Overrides, conversation corrections).
8. Blockers.
9. Repository state (git diff, tests — ground truth).
10. Execution History (loop detection).
11. Slice map (EXECUTE loop).

Load via `rules/core/context-pack.md` — not the full task file unless a specific input requires a deferred section.

## Decision

Given current state, what is the **smallest correct next action** toward `COMPLETE`?

| Decision | When | Action |
|---|---|---|
| **EXECUTE** | Next action obvious, low-risk, ACs unchanged | One phase/skill, then re-decide |
| **ASK_HUMAN** | Human Gate trips | Stop, present gate format, wait |
| **RETRY** | RECOVERABLE failure | `/debug` or fix → re-verify |
| **REPLAN** | REPLAN_REQUIRED | Stop → `/plan` → `/estimate` |
| **STOP** | BLOCKED or loop limit | Persist blocker, ask human |
| **COMPLETE** | All AC VERIFIED, review clean, design-review clean if applicable | Report COMPLETE |

No precomputed phase list. `EXECUTE` names exactly one action.

## Phase completion

A phase is complete only when output is **persisted** in the task file:

| Phase | Persisted as | Owner |
|---|---|---|
| `clarify` | AC, Edge Cases, Assumptions, Open Questions | `/clarify` |
| `design` | Design Context, Decisions | `/design` |
| `creative-explore` | Decisions | `/creative-explore` |
| `plan` | Technical Plan, finalized AC | `/plan` |
| `estimate` | Slices | `/estimate` |
| `implement` | Code + Progress/History entry | normal work |
| `verify` | Result/Evidence/Verified at | `/verify` |
| `design-review` | History entry (pass/fail) | `/execute` on behalf |
| `review` | REVIEW History event | `/review` |

## Visual loop

```
implement → design-review → PASS → continue
                          → FAIL → fix → design-review
```

## Execution mode

From `execution_mode` frontmatter — pacing only, never changes gates or COMPLETE requirements:

- **MANUAL** — skills invoked directly, not `/execute`.
- **AUTONOMOUS** (default) — continues through EXECUTE until gate/blocker/COMPLETE.
- **SUPERVISED** — stops after every persisted phase; resume via next `/execute`.

## Execution History format

One line per entry, pipe-delimited:

```
<timestamp> | <EVENT_TYPE> | <phase> | <detail>
```

Event types (closed vocabulary): `TASK_CREATED`, `STATE_CHANGED`, `PHASE_STARTED`, `PHASE_COMPLETED`, `SKILL_STARTED`, `SKILL_COMPLETED`, `SKILL_FAILED`, `HUMAN_GATE`, `HUMAN_DECISION`, `CHECKPOINT`, `AC_RESULT`, `VERIFICATION`, `REVIEW`, `RECOVERY`.

## Event ownership

| Event | Written by |
|---|---|
| `TASK_CREATED` | `/task`, `/clarify`, or `/plan` (whichever creates file) |
| `STATE_CHANGED` | `/estimate`, `/reconcile`, `/execute` |
| `PHASE_*` | phase owner or `/execute` orchestrating |
| `HUMAN_GATE` / `HUMAN_DECISION` | `/execute` while orchestrating |
| `CHECKPOINT` | `/execute` |
| `AC_RESULT` / `VERIFICATION` | `/verify`; `/reconcile` for STALE only |
| `REVIEW` | `/review` |
| `RECOVERY` | `/debug` |

Full event conditions: see archived reference in git history if needed — this compact version is authoritative for runtime.
