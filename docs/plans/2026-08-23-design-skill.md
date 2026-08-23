# `/design` Skill Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `/design` skill to ai-toolkit-max that produces a disposable HTML/CSS/JS prototype (reviewed in-browser, iterated in place, approved by the user) as the primary UI-context source for `/plan`, replacing Figma as the default path.

**Architecture:** One new skill file (`skills/design/SKILL.md`) following the existing skill-file convention (frontmatter `name`/`description`, `## Rules`, `## Output`). Four existing files get small, targeted edits so the rest of the toolkit knows the new skill exists: `rules/core/capabilities.md` (registry), `skills/plan/SKILL.md` (consumes `/design`'s output), `skills/classify/SKILL.md` (can recommend it), `README.md` (docs). No code, no tests in the traditional sense — this is a documentation/skill-authoring change to a Claude Code plugin. `scripts/lib.sh`'s `skill_names_in()` discovers skills by scanning `skills/*/SKILL.md`, so no install-script change is needed; the existing `tests/test_install.sh` suite verifies this dynamically.

**Tech Stack:** Markdown skill files (Claude Code plugin format), bash (`tests/test_install.sh`, `install.sh --doctor`) for verification only.

**Reference:** Full rationale in `docs/plans/2026-08-23-design-skill-design.md` (design doc, already committed).

---

### Task 1: Create `skills/design/SKILL.md`

**Files:**
- Create: `skills/design/SKILL.md`

**Step 1: Write the skill file**

```markdown
---
name: design
description: Build a disposable HTML/CSS/JS prototype for a UI-facing task and iterate on it with the user in-browser until approved — the primary UI-context source for /plan, replacing a Figma lookup when no Figma file exists.
---

# Design

Turn the current UI-facing request into a disposable, static HTML/CSS/JS prototype the user can look at in a browser, iterate on conversationally, and approve. This is the UI-context step in the workflow — `/plan` later reads the approved prototype as its primary source for Data/API and Changes, in place of a Figma lookup when no Figma file exists.

## Rules

- Do not write production code (React components, application source). The prototype is throwaway: a single self-contained HTML file with inline CSS/JS, never a build step, never a framework.
- Do not modify files outside `design/prototypes/`.
- Take `/clarify`'s Acceptance Contract as input when one exists in this conversation — what the screen must do, what data it shows, what states it has (loading/error/empty/success). Otherwise work directly from the request.
- Save the prototype to `design/prototypes/YYYY-MM-DD-<topic>.html` in the current project (not inside ai-toolkit-max). Reuse the same file across iterations — never create a new versioned file per round of feedback.
- After writing or editing the file, show it to the user: if a browser-automation MCP (Playwright, Chrome DevTools) is available in this session, open the file and screenshot it — both as a self-check and to show the user. Otherwise, tell the user the exact path to open manually. Never invent access to an MCP that isn't configured, per `rules/core/capabilities.md`.
- Iterate on explicit feedback only — do not guess at unstated preferences or add polish the user didn't ask for.
- Stay in DRAFT until the user gives explicit approval (e.g., "approved", "looks good", "ship it"). Do not infer approval from silence or from the absence of further feedback in the same turn.
- Keep the prototype itself out of scope for accessibility/production concerns (semantic HTML is still good practice, but this is not the place to chase WCAG compliance) — those apply to the real implementation, governed by `rules/frontend/react.md`.

## Output

### Prototype
File path + one line describing what it shows.

### Design notes
Short list of the UI decisions that matter for the eventual implementation: layout, component boundaries, states (loading/error/empty/success). Omit decisions that are self-evident from the file itself.

### Status
`DRAFT` (awaiting feedback) or `APPROVED` (ready to hand off to `/plan`).

If `APPROVED`, end with: **Ready for /plan.**
```

**Step 2: Verify the file is well-formed**

Run: `head -5 skills/design/SKILL.md`
Expected: valid YAML frontmatter block (`---` / `name: design` / `description: ...` / `---`), matching the shape of `skills/clarify/SKILL.md` and `skills/challenge/SKILL.md`.

**Step 3: Commit**

```bash
git add skills/design/SKILL.md
git commit -m "Add /design skill: disposable HTML prototype before /plan"
```

---

### Task 2: Update `rules/core/capabilities.md` — registry points at `/design` first

**Files:**
- Modify: `rules/core/capabilities.md:17`

**Step 1: Replace the Figma registry row**

Current line 17:
```
| Figma | design/layout context | `plan`, before implementing UI | read, unless a change is explicitly requested |
```

Replace with two lines — keep Figma available as a fallback capability, but make `/design` the primary, non-MCP path:

```
| Figma | design/layout context, when a Figma file already exists for this UI | `plan`, before implementing UI, only if no `/design` prototype exists | read, unless a change is explicitly requested |
```

Add a short note directly below the table (after the existing "Extend this list only when..." line), so the ordering is explicit without adding `design` as a fake "MCP":

```
`/design`'s disposable HTML prototype (see `skills/design/SKILL.md`) is the default UI-context source for `/plan` — reach for the Figma row above only when no approved prototype exists for the task and a Figma file already does.
```

**Step 2: Verify**

Run: `grep -n "Figma\|/design" rules/core/capabilities.md`
Expected: both the updated Figma row and the new note appear, no leftover reference implying Figma is checked unconditionally.

**Step 3: Commit**

```bash
git add rules/core/capabilities.md
git commit -m "Point capabilities registry at /design before Figma for UI context"
```

---

### Task 3: Update `skills/plan/SKILL.md` — consume the approved prototype

**Files:**
- Modify: `skills/plan/SKILL.md:14`

**Step 1: Replace the Figma-check rule**

Current line 14:
```
- Before finalizing Changes, check whether an available external capability would materially reduce implementation uncertainty — design context (Figma), current library documentation (Context7), related PRs/issues (GitHub) — per `rules/core/capabilities.md`. Use it only if it changes what gets built; never invent access to one that isn't configured.
```

Replace with:
```
- Before finalizing Changes on a UI-facing task, check this conversation for an `APPROVED` `/design` prototype and use it as the primary UI source. If none exists, check whether an available external capability would materially reduce implementation uncertainty — design context (Figma), current library documentation (Context7), related PRs/issues (GitHub) — per `rules/core/capabilities.md`. Use it only if it changes what gets built; never invent access to one that isn't configured.
```

**Step 2: Verify**

Run: `grep -n "design\|Figma" skills/plan/SKILL.md`
Expected: the updated rule line appears, referencing `/design` before Figma.

**Step 3: Commit**

```bash
git add skills/plan/SKILL.md
git commit -m "Have /plan prefer an approved /design prototype over Figma"
```

---

### Task 4: Update `skills/classify/SKILL.md` — allow recommending `design`

**Files:**
- Modify: `skills/classify/SKILL.md:18`

**Step 1: Add `design` to the valid skill-name list**

Current line 18:
```
- Reference only existing skill names in the recommended chain (`clarify`, `plan`, `impact`, `estimate`, `challenge`, `next`, `verify`, `status`, `test`, `review`, `debug`, `short`) — never invent a new one. `implement` may also appear in the chain, but it is not a toolkit skill: it denotes Claude's native code-writing behavior and has no SKILL.md.
```

Replace with:
```
- Reference only existing skill names in the recommended chain (`clarify`, `design`, `plan`, `impact`, `estimate`, `challenge`, `next`, `verify`, `status`, `test`, `review`, `debug`, `short`) — never invent a new one. `implement` may also appear in the chain, but it is not a toolkit skill: it denotes Claude's native code-writing behavior and has no SKILL.md.
- Recommend `design` only for tasks that are visibly UI/frontend-facing (a new screen, dashboard, form, or layout change) — omit it from the chain for backend-only or non-visual work.
```

**Step 2: Verify**

Run: `grep -n "design" skills/classify/SKILL.md`
Expected: both new lines present.

**Step 3: Commit**

```bash
git add skills/classify/SKILL.md
git commit -m "Let /classify recommend /design for UI-facing tasks"
```

---

### Task 5: Update `README.md` — diagram, skills table, repo layout, skill count

**Files:**
- Modify: `README.md` (diagram block ~lines 5-18, intro prose line 23, THINK table ~lines 75-84, "Fourteen skills" line 67, repo layout listing ~lines 280-294)

**Step 1: Update the top-of-file diagram**

Current (lines 5-18):
```
                    ai-toolkit-max
                          │
                      classify
                (picks workflow depth)
                          │
          ┌───────────────┴────────────────┐
          │                                 │
        RULES                            SKILLS
          │                                 │
   ┌──────┼──────┐          THINK:    clarify · plan · impact · estimate · challenge
   ↓      ↓      ↓          EXECUTE:  next · verify   (implementing itself is native)
 core  backend frontend     QUALITY:  test · review · short
```

Replace the `THINK:` line with:
```
   ↓      ↓      ↓          THINK:    clarify · design · plan · impact · estimate · challenge
 core  backend frontend     EXECUTE:  next · verify   (implementing itself is native)
                            QUALITY:  test · review · short
```
(Keep the `core`/`backend`/`frontend` row aligned under RULES as before — only the SKILLS-side lines shift down by one to fit `design` in, so re-check alignment visually against the existing three-line block rather than pasting blindly.)

**Step 2: Update the intro prose**

Line 23 currently:
```
Process depth is meant to scale with the task. `classify` is the entry point: it looks at the task and recommends the minimum chain needed — a trivial change is just `implement → verify`; a risky or ambiguous one pulls in `clarify → plan → estimate → impact/challenge → next → implement → verify → review`. See `rules/core/engineering.md`. There's no skill for "implement" — writing the code is Claude's normal behavior, not a separate mode.
```

Replace with:
```
Process depth is meant to scale with the task. `classify` is the entry point: it looks at the task and recommends the minimum chain needed — a trivial change is just `implement → verify`; a risky or ambiguous one pulls in `clarify → plan → estimate → impact/challenge → next → implement → verify → review`; a UI-facing one inserts `design` between `clarify` and `plan`. See `rules/core/engineering.md`. There's no skill for "implement" — writing the code is Claude's normal behavior, not a separate mode.
```

**Step 3: Update the skill count**

Line 67 currently:
```
Fourteen skills, each a distinct mode of work rather than a fixed pipeline stage. None of them are mandatory gates — invoke only what the task warrants.
```

Replace `Fourteen` with `Fifteen`.

**Step 4: Add a `design` row to the THINK table**

Current THINK table (lines 77-84):
```
| Skill | Use it when |
|---|---|
| `/clarify` | Before implementing anything ambiguous. Drafts an Acceptance Contract: candidate acceptance criteria classified CONFIRMED/INFERRED/UNKNOWN, their verification approach, and the questions needed to resolve what's open — the entry point for acceptance criteria in the workflow. |
| `/plan` | Once requirements are clear. Produces a concise implementation plan anchored to `/clarify`'s acceptance criteria — every meaningful criterion mapped to a change and a test, flagged if it has neither. |
| `/impact` | The change touches shared code, public interfaces, migrations, or infrastructure. Affected surfaces, breaking changes, rollout risk — deeper than `plan`'s Risks line. Skip for isolated/local changes. |
| `/estimate` | Once a plan is approved. Decomposes it into the minimum reasonable number of executable slices, each covering specific acceptance criteria (goal, scope, dependencies, criteria covered, verification criteria, story-point estimate), and initializes the task's state. After work: actual vs. estimate, recorded for future calibration. |
| `/challenge` | A plan or decision carries real weight and has no second reviewer. Stress-tests the reasoning — weakest assumptions, simpler alternative, verdict. Not a repeat of `plan`'s risks. |
```

Insert a new row directly after `/clarify` and before `/plan`:
```
| `/design` | The task is UI-facing and no design context exists yet. Builds a disposable HTML/CSS/JS prototype, iterates on it with the user in-browser, and hands off an `APPROVED` prototype as `/plan`'s primary UI source — replacing a Figma lookup when no Figma file exists. |
```

**Step 5: Add `skills/design/SKILL.md` to the repo layout listing**

Current (in the `skills/` block of the repo layout, ~lines 281-294):
```
skills/
  classify/SKILL.md
  clarify/SKILL.md
  plan/SKILL.md
  impact/SKILL.md
  estimate/SKILL.md
  challenge/SKILL.md
  next/SKILL.md
  verify/SKILL.md
  status/SKILL.md
  test/SKILL.md
  review/SKILL.md
  debug/SKILL.md
  short/SKILL.md
  audit/SKILL.md
```

Insert `design/SKILL.md` after `clarify/SKILL.md`:
```
skills/
  classify/SKILL.md
  clarify/SKILL.md
  design/SKILL.md
  plan/SKILL.md
  impact/SKILL.md
  estimate/SKILL.md
  challenge/SKILL.md
  next/SKILL.md
  verify/SKILL.md
  status/SKILL.md
  test/SKILL.md
  review/SKILL.md
  debug/SKILL.md
  short/SKILL.md
  audit/SKILL.md
```

**Step 6: Verify**

Run: `grep -n "design" README.md`
Expected: matches in the diagram, intro prose, THINK table, and repo layout listing — at least 4 occurrences.

Run: `grep -c "^| \`/" README.md`
Expected: table row count increased by 1 versus before this task (sanity check the new row was actually inserted, not just described).

**Step 7: Commit**

```bash
git add README.md
git commit -m "Document /design in README diagram, skills table, and repo layout"
```

---

### Task 6: Full verification pass

**Step 1: Run the installer test suite**

Run: `./tests/test_install.sh`
Expected: all assertions pass (exit 0). This exercises `skill_names_in()`, which now picks up `skills/design/SKILL.md` automatically — confirms the new skill doesn't break install/doctor logic.

**Step 2: Run doctor against a real install**

Run: `./install.sh --doctor`
Expected: `READY`, and the skill-count line reflects 15 skills matching between repo and installed copy (run `./install.sh` first if doctor reports a stale cache, per the toolkit's own note on this).

**Step 3: Cross-check all four edited files agree with each other**

Run: `grep -rn "design" rules/core/capabilities.md skills/plan/SKILL.md skills/classify/SKILL.md README.md skills/design/SKILL.md`
Expected: every file's mention of `/design` is consistent — same role (UI-context source before `/plan`, Figma fallback), no contradictions.

**Step 4: Read the new skill file once more end-to-end**

Run: `cat skills/design/SKILL.md`
Expected: matches the shape of `skills/clarify/SKILL.md` and `skills/challenge/SKILL.md` — frontmatter, `## Rules`, `## Output`, no stray formatting.

No commit for this task — it's a verification-only pass. If anything fails, fix it in a follow-up commit before considering the plan done.
