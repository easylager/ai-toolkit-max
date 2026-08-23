# Task Context System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a persistent, human-editable, Obsidian-friendly Task Context (`.ai/tasks/TASK-NNN.md`, one file per task) to ai-toolkit-max, replacing the shared `.ai/plan.md` + `.ai/state.md` + `.ai/decisions.md` storage while keeping the existing state machine and acceptance-criteria semantics unchanged.

**Architecture:** One new rule file (`rules/core/task-context.md`) carrying the full document contract (schema, ownership, reconciliation, staleness, `TASK_CONTEXT_ROOT` resolution). Two new skills (`skills/task/SKILL.md`, `skills/reconcile/SKILL.md`). Nine existing files get targeted edits so the rest of the toolkit reads/writes the new per-task file instead of the three shared ones. No application code, no automated tests in the traditional sense — this is a documentation/skill-authoring change to a Claude Code plugin, verified the same way `/design`'s plan was: `tests/test_install.sh`, `install.sh --doctor`, and cross-file `grep` consistency checks.

**Tech Stack:** Markdown skill/rule files (Claude Code plugin format), bash (`tests/test_install.sh`, `install.sh --doctor`) for verification only.

**Reference:** Full rationale in `docs/plans/2026-08-23-task-context-design.md` (design doc, already committed).

---

### Task 1: Create `rules/core/task-context.md`

**Files:**
- Create: `rules/core/task-context.md`

**Step 1: Write the file**

```markdown
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

- **Human-controlled** — Claude proposes only when explicitly asked, never silently overwrites: `title`, `priority`, Objective, Business Context, Constraints, Human Overrides.
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
```

**Step 2: Verify the file is well-formed**

Run: `head -5 rules/core/task-context.md`
Expected: `# Task Context` as the top heading, matching the plain-markdown (no frontmatter) shape of the other `rules/core/*.md` files.

**Step 3: Commit**

```bash
git add rules/core/task-context.md
git commit -m "Add rules/core/task-context.md: schema, ownership, reconciliation, staleness contract"
```

---

### Task 2: Update `rules/core/execution-state.md` for the new file layout

**Files:**
- Modify: `rules/core/execution-state.md`

**Step 1: Replace the intro (lines 1-3)**

Current:
```
# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, keep it in `.ai/` at the project root.
```

Replace with:
```
# Execution State

Some tasks are large enough to need a persisted execution state across sessions and slices. When that's the case, each task gets one file — `.ai/tasks/TASK-NNN.md` by default, or wherever `TASK_CONTEXT_ROOT` resolves to (see `rules/core/task-context.md` for the full document contract: schema, human/AI ownership, reconciliation, staleness). This file is that state — human-editable in Obsidian or any text editor, git-diffable, and the single source of truth for the task's position.
```

**Step 2: Replace the "Files" section (the `.ai/plan.md` / `.ai/state.md` / `.ai/decisions.md` subsections)**

Current heading and three subsections describing `.ai/plan.md`, `.ai/state.md`, `.ai/decisions.md` individually — replace the whole `## Files` section with:

```
## The task file

`.ai/tasks/TASK-NNN.md` (or the resolved `TASK_CONTEXT_ROOT` location) holds everything for one task: acceptance criteria (id, description, requirement status, verification method/level, capability hint, result, evidence — see `rules/core/task-context.md`), the slice map, current state, blockers, decisions, and human-authored context. Nothing about a task lives in a second, separately-synced file — `/plan`, `/estimate`, `/next`, and `/verify` all read and write the same file, each owning a different section of it (see the ownership matrix in `rules/core/task-context.md`).

Overwritten in place per section, not appended — except `Execution History`, which accumulates terse checkpoints (not a prose log) and should be trimmed/archived rather than left to grow unbounded.
```

**Step 3: Update remaining `.ai/plan.md`/`.ai/state.md`/`.ai/decisions.md` references**

Run: `grep -n '\.ai/plan\.md\|\.ai/state\.md\|\.ai/decisions\.md' rules/core/execution-state.md`

For each remaining match (in the "Execution loop", "Autonomy", and "Principles" sections), replace the specific filename with `the task file` (e.g. "If `state.md` claims something the repo contradicts" → "If the task file claims something the repo contradicts"; "`/next`, `/verify`, `/plan`, and `/estimate` may write only inside `.ai/`" stays as-is, it's still true). Keep every rule's meaning identical — this is a rename pass, not a rewrite of the rules themselves.

**Step 4: Verify**

Run: `grep -n '\.ai/plan\.md\|\.ai/state\.md\|\.ai/decisions\.md' rules/core/execution-state.md`
Expected: no matches left.

Run: `grep -n 'task-context.md' rules/core/execution-state.md`
Expected: at least one cross-reference.

**Step 5: Commit**

```bash
git add rules/core/execution-state.md
git commit -m "Point execution-state.md at the per-task .ai/tasks/TASK-NNN.md file"
```

---

### Task 3: Create `skills/task/SKILL.md`

**Files:**
- Create: `skills/task/SKILL.md`

**Step 1: Write the skill file**

```markdown
---
name: task
description: Create or open a task's persistent Task Context file (`.ai/tasks/TASK-NNN.md` by default, or the configured Obsidian vault) — the entry point when starting from a bare idea or an existing note rather than through /clarify or /plan.
---

# Task

Create or open the Task Context file for a task, outside the `/clarify`/`/plan` flow. Most tasks get a Task Context automatically the first time `/clarify` or `/plan` needs to persist something — this skill is for starting one directly, or resuming one you already have an id or title for.

## Rules

- Resolve the task root per `rules/core/task-context.md` (`TASK_CONTEXT_ROOT` → `.ai/config` → default `.ai/tasks/`), creating the directory if it doesn't exist yet.
- Before creating a new task, check for an existing one covering the same request (by title/objective similarity) and open that instead of creating a duplicate — list it and ask if genuinely ambiguous.
- Creating a task: allocate the next sequential `TASK-NNN` id, write the frontmatter and `## Objective`/`## Scope` from what's given, leave every other section empty rather than inventing content — this is a skeleton, not a substitute for `/clarify`.
- Opening a task: read it fresh off disk and summarize its current `status`, `phase`, and any `Blockers`/`Human Overrides` — don't restate the whole file.
- Do not modify any file other than the task file being created/opened.
- Do not write implementation code.

## Output

### Created
```
Task: TASK-NNN — <title>
File: <path>
Status: READY
```
Recommend `/clarify` or `/plan` as the next step.

### Opened
```
Task: TASK-NNN — <title>
File: <path>
Status: <status>
Phase: <phase>
```
One line each for `Blockers` and `Human Overrides` if either is non-empty; otherwise omit.
```

**Step 2: Verify**

Run: `head -5 skills/task/SKILL.md`
Expected: valid YAML frontmatter (`name: task`), matching the shape of `skills/clarify/SKILL.md`.

**Step 3: Commit**

```bash
git add skills/task/SKILL.md
git commit -m "Add /task skill: create or open a Task Context file directly"
```

---

### Task 4: Create `skills/reconcile/SKILL.md`

**Files:**
- Create: `skills/reconcile/SKILL.md`

**Step 1: Write the skill file**

```markdown
---
name: reconcile
description: Detect drift between a task's persisted Task Context and the current code/git/conversation state — new requirements, changed acceptance criteria, human overrides, or stale verification evidence — and flip status to BLOCKED/REPLAN_REQUIRED or mark evidence STALE when material.
---

# Reconcile

Compare the task's persisted Task Context against ground truth — the repo, git history, and this conversation — and surface drift before it causes silent staleness. This is the explicit, on-demand version of the reconciliation every other skill already does opportunistically before acting (see `rules/core/task-context.md`).

## Rules

- Read the task file fresh off disk — never rely on what the conversation last saw.
- Detect, per `rules/core/task-context.md`'s "Detecting human edits": new or reworded Acceptance Criteria, changed `Requirement`/`Result` values, new Edge Cases, changed Constraints, new `Human Overrides` content, changed Test Strategy, new Blockers.
- For each Acceptance Criterion currently `VERIFIED`, compare its `Verified at` commit SHA against the repo's current state (`git diff <sha>..HEAD -- <relevant files>` or equivalent). If relevant files changed since, mark it `STALE` — do not leave a falsely-current `VERIFIED` in place.
- Human edits are authoritative — never revert one to match a prior AI assumption. If a human edit directly contradicts something else required in the file, surface it as an Open Question or a Blocker instead of picking a side.
- Material drift (a changed/new Acceptance Criterion, a Human Override that invalidates the current plan or an in-progress slice, a Blocker with no clear resolution) sets `status: BLOCKED` or `status: REPLAN_REQUIRED` — the same states `rules/core/execution-state.md` defines, never a new one. Non-material drift (an edge case added for later, a note in Business Context) doesn't change `status`.
- Do not modify files other than the task file, and only the sections drift actually requires updating (`Result` → `STALE`, `Blockers`, `status`, `Open Questions`) — never rewrite sections that didn't drift.
- Do not write implementation code and do not decide the next action (that's `/next`) — reconcile reports drift and updates status; `/next` acts on it.

## Output

Keep it concise.

### Drift found
Per item: `<field> — was: <old> → now: <new> — <source: human edit | repo state | conversation>`.
Omit this section entirely if nothing drifted.

### Staleness
`AC-<NNN>: STALE — <files changed since <sha>>` per newly-stale criterion. Omit if none.

### Status
`<unchanged>` or `<old status> → <new status>` with a one-line reason.

Recommend `/next` if status changed, `/plan` if REPLAN_REQUIRED, or say nothing further needs to happen if nothing drifted.
```

**Step 2: Verify**

Run: `head -5 skills/reconcile/SKILL.md`
Expected: valid YAML frontmatter (`name: reconcile`).

**Step 3: Commit**

```bash
git add skills/reconcile/SKILL.md
git commit -m "Add /reconcile skill: drift and stale-verification detection"
```

---

### Task 5: Update `skills/clarify/SKILL.md`

**Files:**
- Modify: `skills/clarify/SKILL.md:8,12`

**Step 1: Update the intro (line 8)**

Current:
```
Turn the current business request into a draft Acceptance Contract: candidate acceptance criteria, their status, and the questions needed to resolve what's still open. This is the entry point for acceptance criteria in the workflow — `/plan` later promotes this draft into `.ai/plan.md`.
```

Replace with:
```
Turn the current business request into a draft Acceptance Contract: candidate acceptance criteria, their status, and the questions needed to resolve what's still open. This is the entry point for acceptance criteria in the workflow — `/plan` later promotes this draft into the task's Task Context file.
```

**Step 2: Replace the "Do not modify files" rule (line 12)**

Current:
```
- Do not modify files.
```

Replace with:
```
- The only file this may create or update is the current task's Task Context file (`rules/core/task-context.md`) — create it (allocating `TASK-NNN`, same allocation rule `/plan` uses) once clarification is worth persisting, or update its `Objective`/`Scope`/`Acceptance Criteria`/`Edge Cases`/`Assumptions`/`Open Questions` if it already exists. Reconcile first: re-read the file fresh and note any human edits before adding to it. Never write implementation code or any other file.
```

Remove the now-redundant separate "Do not write implementation code" line if it duplicates the above (check line ~13) — keep only one statement of that rule.

**Step 3: Verify**

Run: `grep -n 'Task Context\|task-context' skills/clarify/SKILL.md`
Expected: matches in the intro and rules.

**Step 4: Commit**

```bash
git add skills/clarify/SKILL.md
git commit -m "Have /clarify create or update the task's Task Context file"
```

---

### Task 6: Update `skills/plan/SKILL.md`

**Files:**
- Modify: `skills/plan/SKILL.md:15,19`

**Step 1: Update the acceptance-criteria-source rule (line 15)**

Current:
```
- Take `/clarify`'s draft acceptance criteria as the starting point when one exists in this conversation; otherwise derive criteria directly from the request using the same CONFIRMED/INFERRED/UNKNOWN classification (see `skills/clarify/SKILL.md`).
```

Replace with:
```
- Take the task's Task Context file as the starting point when one exists (reconcile first — re-read it fresh, note any human edits per `rules/core/task-context.md`); otherwise take `/clarify`'s draft from this conversation; otherwise derive criteria directly from the request using the same CONFIRMED/INFERRED/UNKNOWN classification (see `skills/clarify/SKILL.md`).
```

**Step 2: Replace the file-modification rule (line 19)**

Current:
```
- Do not modify files, except `.ai/plan.md` when persisting a multi-slice plan. The first time a task's plan is persisted, assign it the next sequential `TASK-NNN` id and record it at the top of `.ai/plan.md` together with its acceptance criteria (id, description, requirement status, verification method/level, capability hint if any); reuse the existing id and update the existing criteria list when refining an already-persisted plan. See `rules/core/execution-state.md`.
```

Replace with:
```
- Do not modify files, except the task's Task Context file when persisting a multi-slice plan. The first time a task's plan is persisted, assign it the next sequential `TASK-NNN` id (per `rules/core/task-context.md`) and create its file with the acceptance criteria (id, description, requirement status, verification method/level, capability hint if any) plus `Technical Plan`/`Design Context`/`Test Strategy`; reuse the existing id and file, updating those same sections, when refining an already-persisted plan. See `rules/core/execution-state.md` and `rules/core/task-context.md`.
```

**Step 3: Verify**

Run: `grep -n 'Task Context\|\.ai/plan\.md' skills/plan/SKILL.md`
Expected: `Task Context` references present, no remaining `.ai/plan.md` mentions.

**Step 4: Commit**

```bash
git add skills/plan/SKILL.md
git commit -m "Have /plan read and persist to the task's Task Context file"
```

---

### Task 7: Update `skills/estimate/SKILL.md`

**Files:**
- Modify: `skills/estimate/SKILL.md:15,27`

**Step 1: Update the plan-source rule (line 15)**

Current:
```
- Take the existing plan as primary input — `.ai/plan.md` if present, otherwise the plan already produced in this conversation. Don't re-derive requirements or approach `/plan` already settled. Read the plan's acceptance criteria along with it — they drive decomposition, not just the Changes list.
```

Replace with:
```
- Take the existing plan as primary input — the task's Task Context file if present, otherwise the plan already produced in this conversation. Don't re-derive requirements or approach `/plan` already settled. Read the file's acceptance criteria along with it — they drive decomposition, not just the Changes list.
```

**Step 2: Replace the file-modification rule (line 27)**

Current:
```
- Do not modify files, except: writing the slice map into `.ai/plan.md`'s Slices section when `.ai/` is in use; initializing the task's block in `.ai/state.md` (state `READY`, current slice 1/total, each of the plan's acceptance criteria set to `NOT_VERIFIED`) the first time a slice map is created for it; and appending the post-work Record into that task's block in `.ai/state.md` — see `rules/core/execution-state.md`.
```

Replace with:
```
- Do not modify files, except the task's Task Context file: writing the slice map into its `Slices` section; initializing `status: READY`, current slice 1/total, and each acceptance criterion's `Result: NOT_VERIFIED` the first time a slice map is created for it; and appending the post-work Record into its `Execution History` — see `rules/core/execution-state.md` and `rules/core/task-context.md`.
```

**Step 3: Verify**

Run: `grep -n 'Task Context\|\.ai/plan\.md\|\.ai/state\.md' skills/estimate/SKILL.md`
Expected: `Task Context` references present, no remaining `.ai/plan.md`/`.ai/state.md` mentions.

**Step 4: Commit**

```bash
git add skills/estimate/SKILL.md
git commit -m "Have /estimate write the slice map into the task's Task Context file"
```

---

### Task 8: Update `skills/next/SKILL.md`

**Files:**
- Modify: `skills/next/SKILL.md:14,18,29,33,35`

**Step 1: Update the "which task" section (lines 14, 18)**

Current:
```
- Exactly one active task (state not `COMPLETE`) in `.ai/state.md` → use it.
- More than one active task → list them briefly (id, title, state) and ask which one, rather than guessing.
- No tasks at all → say so plainly and recommend `/plan`.

Given `/next TASK-NNN` for an id that doesn't exist in `.ai/state.md`, say so — don't invent one.
```

Replace with:
```
- Exactly one active task (status not `COMPLETE`) among the task files in the resolved `TASK_CONTEXT_ROOT` (per `rules/core/task-context.md`) → use it.
- More than one active task → list them briefly (id, title, status) and ask which one, rather than guessing.
- No tasks at all → say so plainly and recommend `/plan`.

Given `/next TASK-NNN` for an id with no matching task file, say so — don't invent one.
```

**Step 2: Update the EXECUTING note (line 29)**

Current:
```
EXECUTING (actually implementing a slice) is not a state `next` reports — it's the runtime interval between a READY dispatch and its checkpoint. If `.ai/state.md` shows a slice still EXECUTING (e.g., resumed after an interrupted session), don't trust it — re-derive status from the repo.
```

Replace with:
```
EXECUTING (actually implementing a slice) is not a state `next` reports — it's the runtime interval between a READY dispatch and its checkpoint. If the task file shows a slice still EXECUTING (e.g., resumed after an interrupted session), don't trust it — reconcile first (re-read the file fresh, per `rules/core/task-context.md`) and re-derive status from the repo. This is also how `/next` recovers a task after an interruption — there is no separate recovery command.
```

**Step 3: Update the file-modification and inspection rules (lines 33, 35)**

Current:
```
- Do not modify files except `.ai/state.md` (and `.ai/plan.md`, only to annotate or reorder slices during execution — the initial slice map itself comes from `/estimate`). See `rules/core/execution-state.md`.
```
```
- Inspect `.ai/plan.md`, `.ai/state.md`, `.ai/decisions.md` if present, plus the actual repo: git diff, current implementation, tests, known failures. Trust the repo over stale state. Scope everything to the selected task — other tasks' blocks in `.ai/state.md` are context, not input.
```

Replace with:
```
- Do not modify files except the task's Task Context file — its `status`, current slice, `Next Action`, `Blockers`, and (only to annotate or reorder slices during execution — the initial slice map itself comes from `/estimate`) `Slices`. See `rules/core/execution-state.md`.
```
```
- Reconcile first (re-read the task file fresh, per `rules/core/task-context.md`), then inspect the actual repo: git diff, current implementation, tests, known failures. Trust the repo over a stale file. Scope everything to the selected task — other tasks' files are context, not input.
```

**Step 4: Verify**

Run: `grep -n 'Task Context\|\.ai/plan\.md\|\.ai/state\.md\|\.ai/decisions\.md' skills/next/SKILL.md`
Expected: `Task Context` references present, no remaining `.ai/*.md` mentions.

**Step 5: Commit**

```bash
git add skills/next/SKILL.md
git commit -m "Have /next reconcile and dispatch from the task's Task Context file"
```

---

### Task 9: Update `skills/verify/SKILL.md`

**Files:**
- Modify: `skills/verify/SKILL.md:12,14`

**Step 1: Update the file-modification rule (line 12)**

Current:
```
- Do not modify files except `.ai/state.md`. See `rules/core/execution-state.md`.
```

Replace with:
```
- Do not modify files except the task's Task Context file — each in-scope criterion's `Result`, `Evidence`, and `Verified at`. See `rules/core/execution-state.md` and `rules/core/task-context.md`.
```

**Step 2: Update the criteria-source rule (line 14)**

Current:
```
- Verify against the acceptance criteria the current slice covers — from the slice map's `Covers:` field and `.ai/plan.md`'s Acceptance criteria section (or `/next`'s READY report) — not just whatever tests happen to run.
```

Replace with:
```
- Verify against the acceptance criteria the current slice covers — from the slice map's `Covers:` field and the task file's Acceptance Criteria section (or `/next`'s READY report) — not just whatever tests happen to run.
```

**Step 3: Add `Verified at` to the evidence rule**

In the "Never mark a criterion VERIFIED without evidence" bullet, append one sentence: `Record the commit SHA and date as Verified at — this is what lets /reconcile detect staleness later.`

**Step 4: Verify**

Run: `grep -n 'Task Context\|\.ai/state\.md\|\.ai/plan\.md\|Verified at' skills/verify/SKILL.md`
Expected: `Task Context` and `Verified at` references present, no remaining `.ai/*.md` mentions.

**Step 5: Commit**

```bash
git add skills/verify/SKILL.md
git commit -m "Have /verify write Result/Evidence/Verified-at into the Task Context file"
```

---

### Task 10: Update `skills/review/SKILL.md`

**Files:**
- Modify: `skills/review/SKILL.md:21`

**Step 1: Replace the `.ai/state.md` reference**

Current:
```
- Acceptance criteria status is `/verify`'s job, not this one's — don't re-verify or restate per-criterion PASS/FAIL here. If `.ai/state.md` shows criteria still `NOT_VERIFIED`/`FAILED`, note it in one line and review the code on its merits regardless — a task can pass review and still not be acceptance-verified, or vice versa.
```

Replace with:
```
- Acceptance criteria status is `/verify`'s job, not this one's — don't re-verify or restate per-criterion PASS/FAIL here. If the task's Task Context file shows criteria still `NOT_VERIFIED`/`FAILED`/`STALE`, note it in one line and review the code on its merits regardless — a task can pass review and still not be acceptance-verified, or vice versa.
- If a finding reveals a new edge case or a decision worth not rediscovering, say so — persisting it into the task file's Edge Cases/Decisions is `/debug`'s or a follow-up `/plan`'s job, not written directly here.
```

**Step 2: Verify**

Run: `grep -n 'Task Context\|\.ai/state\.md' skills/review/SKILL.md`
Expected: `Task Context` reference present, no `.ai/state.md` mention.

**Step 3: Commit**

```bash
git add skills/review/SKILL.md
git commit -m "Point /review at the task's Task Context file instead of .ai/state.md"
```

---

### Task 11: Update `skills/debug/SKILL.md`

**Files:**
- Modify: `skills/debug/SKILL.md:19`

**Step 1: Add a persistence rule after "Consider related edge cases and regression risks."**

Current (line 19):
```
- Consider related edge cases and regression risks.
```

Replace with:
```
- Consider related edge cases and regression risks.
- If the root cause reveals a new edge case or a decision worth not rediscovering (not just "how this particular bug was fixed"), persist it into the task's Task Context file's `Edge Cases`/`Decisions` section — reconcile first (re-read the file fresh). Don't log the investigation itself; only the durable fact.
```

**Step 2: Verify**

Run: `grep -n 'Task Context' skills/debug/SKILL.md`
Expected: one match.

**Step 3: Commit**

```bash
git add skills/debug/SKILL.md
git commit -m "Have /debug persist durable edge cases and decisions into the Task Context file"
```

---

### Task 12: Update `skills/status/SKILL.md`

**Files:**
- Modify: `skills/status/SKILL.md:8,13,15,16`

**Step 1: Update the intro (line 8)**

Current:
```
Report execution state exactly as recorded in `.ai/state.md`. Never modify anything, never invent state.
```

Replace with:
```
Report execution state exactly as recorded in each task's Task Context file. Never modify anything, never invent state.
```

**Step 2: Update the read-source rule (line 13)**

Current:
```
- Read from `.ai/state.md` (and `.ai/plan.md` only for a title/slice name it doesn't already have). See `rules/core/execution-state.md`.
```

Replace with:
```
- Read from the task file(s) under the resolved `TASK_CONTEXT_ROOT` (per `rules/core/task-context.md`) — one task with `/status TASK-NNN`, all of them for a bare `/status` (glob for `TASK-*.md`, read each frontmatter). See `rules/core/execution-state.md`.
```

**Step 3: Update the remaining rules (lines 15-16)**

Current:
```
- If `.ai/` doesn't exist, or has no tasks, say so plainly — don't infer or fabricate a task.
- Report only what's actually recorded. Never guess at a blocker, slice count, or next action that isn't in state.
- Given `/status TASK-NNN` for an id that isn't in `.ai/state.md`, say so — don't invent one.
```

Replace with:
```
- If the resolved task root doesn't exist, or has no tasks, say so plainly — don't infer or fabricate a task.
- Report only what's actually recorded. Never guess at a blocker, slice count, or next action that isn't in the file.
- Given `/status TASK-NNN` for an id with no matching task file, say so — don't invent one.
```

**Step 4: Verify**

Run: `grep -n '\.ai/state\.md\|\.ai/plan\.md' skills/status/SKILL.md`
Expected: no matches.

**Step 5: Commit**

```bash
git add skills/status/SKILL.md
git commit -m "Have /status read from per-task Task Context files"
```

---

### Task 13: Update `skills/classify/SKILL.md`

**Files:**
- Modify: `skills/classify/SKILL.md:18`

**Step 1: Add `task`/`reconcile` to the valid skill-name list**

Current:
```
- Reference only existing skill names in the recommended chain (`clarify`, `design`, `plan`, `impact`, `estimate`, `challenge`, `next`, `verify`, `status`, `test`, `review`, `debug`, `short`) — never invent a new one. `implement` may also appear in the chain, but it is not a toolkit skill: it denotes Claude's native code-writing behavior and has no SKILL.md.
```

Replace with:
```
- Reference only existing skill names in the recommended chain (`task`, `clarify`, `design`, `plan`, `impact`, `estimate`, `challenge`, `next`, `verify`, `status`, `reconcile`, `test`, `review`, `debug`, `short`) — never invent a new one. `implement` may also appear in the chain, but it is not a toolkit skill: it denotes Claude's native code-writing behavior and has no SKILL.md.
- Recommend `task` only when the request has no natural entry through `clarify`/`plan` (e.g. resuming from a bare id or an external note). Recommend `reconcile` only when resuming a task without the conversation context that produced its current state, or when there's concrete reason to suspect drift — not as a routine step in every chain.
```

**Step 2: Verify**

Run: `grep -n 'task\|reconcile' skills/classify/SKILL.md`
Expected: both new skill names present in the valid list and the added guidance line.

**Step 3: Commit**

```bash
git add skills/classify/SKILL.md
git commit -m "Let /classify recommend /task and /reconcile"
```

---

### Task 14: Update `README.md`

**Files:**
- Modify: `README.md` (diagram ~lines 5-18, intro prose ~line 23, skill count ~line 67, THINK/EXECUTE tables, "Execution state" section ~lines 126-191, repo layout ~lines 268-309)

**Step 1: Update the top-of-file diagram**

Add `task` and `reconcile` to the SKILLS lines, e.g.:
```
   ↓      ↓      ↓          THINK:    task · clarify · design · plan · impact · estimate · challenge
 core  backend frontend     EXECUTE:  next · verify · reconcile   (implementing itself is native)
                            QUALITY:  test · review · short
```
Re-check alignment visually against the existing block rather than pasting blindly.

**Step 2: Update the skill count**

Change `Fifteen skills` (or whatever the current count says after `/design` was added) to `Seventeen skills`.

**Step 3: Add `/task` row to the THINK table**

Insert before the `/clarify` row:
```
| `/task` | Starting a task outside `/clarify`/`/plan` — from a bare idea or an existing note. Creates or opens the task's Task Context file (`.ai/tasks/TASK-NNN.md` by default). |
```

**Step 4: Add `/reconcile` row to the EXECUTE table**

Insert after the `/status` row:
```
| `/reconcile` | Resuming a task without the conversation context that produced its current state, or suspecting drift. Compares the persisted Task Context against the repo/git/conversation — new or changed acceptance criteria, human overrides, stale verification evidence — and flips status or marks evidence `STALE` when material. |
```

**Step 5: Rewrite the "Execution state" section**

Replace the `.ai/` file-tree block and its explanation (currently describing `plan.md`/`state.md`/`decisions.md`) with the per-task-file model:

```
For tasks big enough to need multi-slice tracking across sessions, a task gets a stable id (`TASK-001`, `TASK-002`, …) and a persistent Task Context file — `.ai/tasks/TASK-NNN.md` at the root of the project you're working in by default, or wherever `TASK_CONTEXT_ROOT` resolves to (an external, possibly shared Obsidian vault — see `rules/core/task-context.md`):

\`\`\`
.ai/
└── tasks/
    ├── TASK-001.md   # everything for this task: acceptance criteria, slices, state, decisions, human context
    └── TASK-002.md
\`\`\`

\`\`\`
TASK ──▶ classify ──▶ clarify ──▶ plan+estimate ──▶ task file ──▶ next ──▶ slice ──▶ verify ──▶ task file ──▶ next ──▶ …
\`\`\`

Created lazily — a task that doesn't need it never gets a task file or a `TASK-NNN` id. Full contract in `rules/core/execution-state.md` and `rules/core/task-context.md`, in short:

- **Acceptance criteria drive everything**, same as before — `CONFIRMED`/`INFERRED`/`UNKNOWN` requirement status, `VERIFIED`/`FAILED`/`BLOCKED`/`NOT_VERIFIED`/`STALE` verification result, both tracked per criterion in the task file.
- **One file per task is the single source of truth** for its position: `status` (`READY`/`EXECUTING`/`VERIFYING`/`BLOCKED`/`RECOVERABLE`/`REPLAN_REQUIRED`/`COMPLETE`), current slice, acceptance criteria, blockers, decisions, and human-authored context (Objective, Business Context, Constraints, Human Overrides) — all in one Obsidian-editable note.
- **Human edits always win.** A human can open the file directly, change an acceptance criterion, add an edge case, or write a `Human Overrides` note — Claude reconciles against the file fresh before every major step and treats those edits as authoritative, never silently reverting them.
- **Verification goes stale.** A `VERIFIED` result records the commit it was checked against; if relevant code changes afterward, `/reconcile` (or routine reconciliation) marks it `STALE` rather than leaving a falsely-current result in place.
- Only `/task`, `/clarify`, `/plan`, `/estimate`, `/next`, `/verify`, and `/reconcile` write inside a task file, and nowhere else — never source code, configs, or other project files.
- Commit `.ai/tasks/` to the project's own repo by default (or to the external vault's own repo, if `TASK_CONTEXT_ROOT` points at one) — so a new session or a teammate can resume without replaying the conversation.
```

Update the worked examples below (`/next`, `/verify`, `/status` sample output blocks) only if they reference file names directly — otherwise leave their console-output shape as-is, since the skill *output* format is unchanged, only where it's persisted.

**Step 6: Add rows to the Rules table**

Add a row for the new rule file:
```
| `rules/core/task-context.md` | The Task Context document contract — schema, human/AI ownership, reconciliation, staleness, `TASK_CONTEXT_ROOT` resolution. |
```

**Step 7: Add `task-context.md` to the always-included rules list**

In the "Install rules" section, add `rules/core/task-context.md` to the seven always-imported `@` lines and the surrounding prose (`The six core/ rules` → `The seven core/ rules`).

**Step 8: Update the repo layout listing**

Add `task/SKILL.md` after `status/SKILL.md`, `reconcile/SKILL.md` after `debug/SKILL.md` (or wherever alphabetically/logically consistent with the existing list), and `task-context.md` after `execution-state.md` in the `rules/core/` listing.

**Step 9: Verify**

Run: `grep -c '^| \`/' README.md`
Expected: table row count increased by 2 versus before this task.

Run: `grep -n 'task-context\|TASK_CONTEXT_ROOT\|/reconcile\|/task' README.md`
Expected: matches across the diagram, tables, execution-state section, rules table, and repo layout.

**Step 10: Commit**

```bash
git add README.md
git commit -m "Document the Task Context system in README: skills, execution state, repo layout"
```

---

### Task 15: Bump plugin version

**Files:**
- Modify: `.claude-plugin/plugin.json`

**Step 1: Bump the version and description**

Change `"version": "3.1.0"` to `"version": "3.2.0"`. Update `"description"` to mention the new skills, e.g. append `, task, reconcile` in the appropriate category list within the existing description string.

**Step 2: Verify**

Run: `cat .claude-plugin/plugin.json`
Expected: valid JSON, version `3.2.0`.

**Step 3: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "Bump plugin version to 3.2.0 for the Task Context system"
```

---

### Task 16: Full verification pass

**Step 1: Run the installer test suite**

Run: `./tests/test_install.sh`
Expected: all assertions pass (exit 0) — confirms `skill_names_in()` picks up `skills/task/SKILL.md` and `skills/reconcile/SKILL.md` automatically and nothing else broke.

**Step 2: Run doctor against a real install**

Run: `./install.sh --doctor`
Expected: `READY`, skill count matches 17 between repo and installed copy (re-run `./install.sh` first if it reports a stale cache).

**Step 3: Validate the plugin manifest**

Run: `claude plugin validate .`
Expected: no errors.

**Step 4: Cross-check every changed file agrees**

Run: `grep -rln '\.ai/plan\.md\|\.ai/state\.md\|\.ai/decisions\.md' rules/ skills/ README.md`
Expected: no output — no stale references to the old three-file layout remain anywhere.

Run: `grep -rl 'Task Context\|task-context' rules/ skills/ README.md`
Expected: every skill listed in the design doc's "Skill integration" section appears.

**Step 5: Demonstrate one example task lifecycle**

In a scratch directory (not this repo), simulate: `/clarify` a small fictitious feature → confirm it would create `.ai/tasks/TASK-001.md` with draft ACs → `/plan` promotes and finalizes → `/estimate` adds a slice → `/next` reports READY → (implement) → `/verify` marks the criterion `VERIFIED` with `Verified at` → `/next` reports COMPLETE. This is a read-through of the skill files confirming the described behavior is internally consistent end-to-end — not a live run, since there's no real target project in this repo to execute against.

No commit for this task — verification-only. Fix and re-commit in the relevant task's file if anything fails.
