# Task Context system — design doc

Date: 2026-08-23

## Problem

`rules/core/execution-state.md` already has almost everything a stateful task needs — a stable `TASK-NNN` id, acceptance criteria with two independently-owned axes (`CONFIRMED`/`INFERRED`/`UNKNOWN` requirement status, `VERIFIED`/`FAILED`/`BLOCKED`/`NOT_VERIFIED` verification status), a canonical state machine (`READY`/`EXECUTING`/`VERIFYING`/`BLOCKED`/`RECOVERABLE`/`REPLAN_REQUIRED`/`COMPLETE`), a slice map, checkpoints, and an explicit "state is advisory, repo is ground truth" principle.

What it doesn't have: a document a human can actually open and edit. State is split across three *shared* files — `.ai/plan.md`, `.ai/state.md`, `.ai/decisions.md` — each holding a block per task. That's fine for Claude but bad for a human: no single file to open in Obsidian, no natural place for free-text business context or an explicit override, and editing one task's block risks touching a shared file other tasks also depend on (merge conflicts, accidental cross-task edits).

## Solution

Consolidate the three shared files into **one file per task**: `.ai/tasks/TASK-NNN.md` (location configurable, see below). Same state machine, same acceptance-criteria axes, same slice/evidence/autonomy rules from `execution-state.md` — this is a storage-layout change, not a new architecture. `execution-state.md` already forbids inventing a parallel status field "that would duplicate state that already exists"; the same principle rules out running two vocabularies (the toolkit's `VERIFIED/FAILED/BLOCKED/NOT_VERIFIED` and a second `TODO/IN_PROGRESS/PASS/FAIL` style) for the same concept, so the task file reuses the toolkit's existing terms throughout.

```
classify → clarify → design → plan → estimate → next → verify → review
              │         │       │       │          │       │
              └─────────┴───────┴───────┴──────────┴───────┴──▶ .ai/tasks/TASK-NNN.md
                                                                  (read + reconcile before
                                                                   each step, written after)
```

### File location — `TASK_CONTEXT_ROOT`

Resolved in order, documented in the new `rules/core/task-context.md`:

1. `TASK_CONTEXT_ROOT` env var, if set — an external, possibly shared Obsidian vault: `$TASK_CONTEXT_ROOT/<project-slug>/TASK-NNN.md`.
2. `.ai/config`'s `task_context_root` key, if present — same idea, pinned per-project without needing an env var.
3. Default: `.ai/tasks/` inside the current project (git-committed, zero config, works today with no setup).

`<project-slug>` is the project's repo directory name unless a `project:` frontmatter field says otherwise. This is what makes multiple simultaneous projects share one vault without collision (`Tasks/careeros/TASK-003.md`, `Tasks/toolkit/TASK-001.md`, …) while staying git-native by default for anyone who hasn't set up an external vault. No install-time setup: whichever skill first needs to write a task file creates the resolved root directory if missing (`mkdir -p`) — the "safe setup mechanism" the root config needs.

Task id stays `TASK-NNN`, sequential, allocated the same way it is today (highest existing id + 1) — now counted from `.ai/tasks/TASK-*.md` filenames instead of blocks in `.ai/state.md`.

### Schema

Markdown + YAML frontmatter, one file = one task = one Obsidian note.

```
---
task_id: TASK-NNN
title: <short title>
project: <slug — only needed once TASK_CONTEXT_ROOT is a shared external vault>
status: READY | EXECUTING | VERIFYING | BLOCKED | RECOVERABLE | REPLAN_REQUIRED | COMPLETE
phase: clarify | design | plan | estimate | implement | verify | review
priority: <optional, human-set>
created_at: <date>
updated_at: <date>
branch: <optional>
last_verified_commit: <optional — most recent commit any AC's evidence was checked against>
issue: <optional>
pr: <optional>
---

# Task

## Objective            — human-controlled
## Business Context      — human-controlled
## Scope
### In Scope / Out of Scope   — shared
## Acceptance Criteria   — shared
### AC-NNN
<one-line, testable description>
Requirement: CONFIRMED | INFERRED | UNKNOWN
Verification method: <unit/integration/e2e/contract/performance/security/static analysis/migration/manual/exploratory/other>
Capability: <MCP hint — omit if none>
Result: VERIFIED | FAILED | BLOCKED | NOT_VERIFIED | STALE
Evidence: <concrete, one line — omit for NOT_VERIFIED>
Verified at: <commit SHA + date — omit for NOT_VERIFIED>

## Edge Cases            — shared
### EDGE-NNN
<description>
Severity: LOW | MEDIUM | HIGH
Status: OPEN | RESOLVED
Resolution / Verification: <omit while OPEN>

## Assumptions           — shared (AI proposes, human edits win)
## Constraints           — human-controlled
## Decisions             — shared
### DEC-NNN
Decision: … / Reason: … / Alternatives: <omit if none material>

## Design Context        — shared (link to an approved /design prototype path, Figma ref, etc.)
## Technical Plan        — AI-authored, human-annotatable
## Test Strategy         — shared
## Slices                — AI-managed (written by /estimate, updated by /next)
### S1 <name>
Goal / Scope / Depends on / Covers: AC-NNN / Verification / Estimate / Status

## Progress              — AI-managed, terse (e.g. "3/5 slices done, 4/6 AC verified")
## Blockers              — AI-managed
## Human Overrides       — human-controlled, highest priority
## Open Questions        — shared
### Q-NNN
<question> — Affects: <AC/EDGE id(s)>

## Next Action           — AI-managed, one line, written by /next
## Execution History     — AI-managed, terse checkpoints only, not a chat log
```

Per-AC `Evidence`/`Verified at` is the only evidence store — no separate top-level "Evidence" section, to avoid keeping the same fact in two places. `Decisions` living inside the task file replaces `.ai/decisions.md`'s "tag each entry with its task id" convention — the file itself is already scoped to one task, so no tag is needed.

`Requirement:` and `Result:` are kept as two separately-labeled fields on the same AC — same two independently-owned axes `execution-state.md` already documents, just co-located now that both live in one file instead of two.

### Ownership

Documented explicitly in `rules/core/task-context.md`:

- **Human-controlled** (Claude proposes only when explicitly asked; never silently overwrites): `title`, `priority`, Objective, Business Context, Constraints, Human Overrides.
- **Shared** (Claude proposes, human edits are authoritative): Acceptance Criteria, Edge Cases, Decisions, Test Strategy, Assumptions, Scope, Open Questions.
- **AI-managed** (Claude writes; a human can still hand-edit, e.g. to unblock): `status`, `phase`, Slices, Progress, Blockers, Next Action, Execution History.

Human-edit detection: before any reconciliation point (see below), re-read the task file fresh off disk — never trust what the conversation last saw. Where the file is git-tracked, `git diff` against the AI's own last commit of that file is the primary signal (empty diff ⇒ nothing changed since Claude last wrote it; a non-empty diff not caused by Claude's own current turn ⇒ a human edit). Where it isn't (uncommitted or git unavailable), a structural comparison against what the current turn is about to write — an AC whose `Requirement`/`Result` differs from what Claude is about to set, a new `Human Overrides` line, a new manually-added AC/EDGE block — is treated the same way: authoritative, never silently reverted. A contradiction between a human edit and something Claude is confident is required (e.g. an override that would violate a hard constraint) is not silently accepted either — it's surfaced as an Open Question / `BLOCKED`, not resolved by guessing which side wins.

### Reconciliation and staleness

Every skill that touches the task file re-reads it fresh before acting — this alone covers most "did a human change something" cases without a dedicated step. `/reconcile` (new skill) is the explicit, on-demand deep version: additionally cross-checks each `VERIFIED` AC's `Verified at` commit SHA against the current repo state; if files relevant to that AC changed since, flips `Result` to `STALE` (evidence exists but is no longer trustworthy — distinct from `NOT_VERIFIED`, which means never checked). Material drift (new/changed AC, new blocker, a Human Override that contradicts the current plan, a stale AC blocking completion) routes the task to `BLOCKED` or `REPLAN_REQUIRED` — the same two states `execution-state.md` already defines, no new state invented.

### State machine mapping

The user-facing lifecycle (intake/clarify/design/plan/ready/implement/verify/review/done/blocked) is descriptive, tracked in the `phase` field, and never a second state machine — `status` stays exactly `execution-state.md`'s existing seven values (`DONE` in the informal sense is `COMPLETE`). `phase` says *what kind of work last happened*; `status` says *the canonical execution position*. Both live in one frontmatter block instead of being scattered.

### Skill integration

- **`/clarify`** — may now create the task file (assigning `TASK-NNN` the same way `/plan` does today, the first time clarification is worth persisting) with `Objective`/`Scope`/draft `Acceptance Criteria` (`INFERRED`/`UNKNOWN`, never silently `CONFIRMED`)/`Edge Cases`/`Assumptions`/`Open Questions`. Still never writes source code.
- **`/plan`** — reads + reconciles the task file if one exists (creating it, with the existing id-allocation rule, if not); writes `Technical Plan`, finalized/promoted Acceptance Criteria, `Design Context`, `Test Strategy`.
- **`/estimate`** — writes `Slices` and initializes `Progress`/`Result: NOT_VERIFIED` into the task file instead of `.ai/plan.md` + `.ai/state.md`.
- **`/next`** — reconciles first (re-reads for human edits/new blockers), then reads/writes `status`, current slice, `Next Action`, `Blockers` in the task file. This generalizes today's "don't trust a stale `EXECUTING` marker, re-derive from the repo" rule to "don't trust a stale task file either, re-read it" — covering session-interruption recovery without a separate `/recover` skill.
- **`/verify`** — writes each in-scope AC's `Result`/`Evidence`/`Verified at`.
- **`/review`** — reads the task file for context (replacing its current `.ai/state.md` reference); unchanged read-only behavior otherwise.
- **`/debug`** — when a bug reveals a new edge case or a decision worth not rediscovering, persists it into the task file's `Edge Cases`/`Decisions` — never a play-by-play log.
- **`/status`** — reads task file(s) instead of `.ai/state.md`; "all active tasks" = glob `.ai/tasks/*.md` (or the resolved root) and read each frontmatter.
- **`/classify`** — gains `task`/`reconcile` as valid names it may reference in a recommended chain.
- **New `/task`** — thin create-or-open entry point for a task file outside the clarify/plan flow (e.g. starting from an existing note or a bare idea); opens an existing task covering the same request instead of duplicating it.
- **New `/reconcile`** — the drift/staleness check described above, callable any time, and implicitly what a fresh session should run first when resuming a task it doesn't have conversation context for.

No `/recover` skill — folded into `/next` as described, per "do not create commands that duplicate existing capabilities."

## Changes to existing files

- `rules/core/execution-state.md` — file-location section rewritten for `.ai/tasks/TASK-NNN.md`; state machine, AC axes, slice loop, autonomy, and principles sections stay conceptually the same, cross-referencing the new file for the document contract.
- `rules/core/task-context.md` (**new**) — schema, ownership matrix, reconciliation triggers, staleness rule, `TASK_CONTEXT_ROOT` resolution, Obsidian conventions (note = task, `[[TASK-NNN]]` linking, optional `INDEX.md`), multi-project layout.
- `skills/clarify/SKILL.md`, `skills/plan/SKILL.md`, `skills/estimate/SKILL.md`, `skills/next/SKILL.md`, `skills/verify/SKILL.md`, `skills/review/SKILL.md`, `skills/debug/SKILL.md`, `skills/status/SKILL.md`, `skills/classify/SKILL.md` — updated per Skill integration above.
- `skills/task/SKILL.md`, `skills/reconcile/SKILL.md` (**new**).
- `README.md` — execution-state section rewritten for the new layout, two new skill-table rows, diagram, repo layout, skill count.
- `.claude-plugin/plugin.json` — version bump.

## Out of scope

- No changes to `rules/core/capabilities.md` — Obsidian access is plain local filesystem, already covered by the existing "local filesystem/CLI" capability category; no MCP involved.
- No changes to `install.sh`/`scripts/*` — `TASK_CONTEXT_ROOT` resolution is a runtime, per-invocation concern read by a skill, not an install-time one; new skills are auto-discovered by the existing `skill_names_in()` scan the same way `/design` was.
- No automated migration script for existing `.ai/plan.md`/`.ai/state.md`/`.ai/decisions.md` users — not requested, and YAGNI for a toolkit with no in-flight multi-slice tasks of its own; README notes the layout changed for anyone who already has one.
- `skills/design/SKILL.md`, `skills/impact/SKILL.md`, `skills/challenge/SKILL.md`, `skills/test/SKILL.md`, `skills/audit/SKILL.md`, `skills/short/SKILL.md`, and the non-core rule files are untouched — they don't reference `.ai/` state today and don't need to.
