# ai-toolkit-max

A small, stateful toolkit for Claude Code. One persistent task file. Simple workflow. Principles and skills.

**How it works:**

```
.ai/project.md         (project dashboard — optional, for multi-task work)
    ↓ one node = one task
.ai/tasks/TASK-NNN.md  (source of truth for a task)
    ↑
    │ read/write
    │
  skills (project · decide | task · clarify · research · plan · estimate · execute · verify · review)
    ↑
    │ use to manage work
    │
  Claude Code (the execution engine)
```

- **Project file** — one-screen dashboard: stage, goal, next, blockers, task graph. Only when a project spans several tasks.
- **Task file** — persistent record of requirements, plan, progress, decisions.
- **Skills** — `/project`, `/decide`, `/research`, `/clarify`, `/plan`, `/estimate`, `/execute`, `/verify`, `/review` — read state, do work, update state, report result.
- **Rules** — engineering principles pulled into your project's `CLAUDE.md`.

Two levels, same idea. A single task: `/classify` → `/clarify` → `/plan` → `/estimate` → `/execute`. A whole project: `/project` walks five questions — *что строим → как должно работать → как построим → как убедимся, что работает → что дальше* — and hands each node of its task graph to that same task workflow.

Typical workflow: `/research` (if needed) → `/clarify` → `/plan` → `/estimate` → `/execute` (which chains phases until done, or you invoke skills individually). `/research` can repeat later for one targeted follow-up question — see [Skills](#skills).
Minimal, human-readable, easy to resume after an interruption.

## Installation

Prerequisites: Git and Claude Code installed.

### Global installation

```bash
git clone https://github.com/easylager/ai-toolkit-max.git
cd ai-toolkit-max
./install.sh
```

Installs, for this user: the ai-toolkit-max skills, the Claude Code plugin (registered from this checkout), and whatever global toolkit configuration the installer itself needs. No project-specific rules or config are touched.

### Project installation

```bash
cd <project>
~/ai-toolkit-max/install.sh --project
```

Adds, to the current project only: a managed block in its `CLAUDE.md` and `@import` lines pulling in the relevant ai-toolkit-max rules (see [Rules](#rules) below). It does not copy the skills into the project, and it does not modify application code.

### Recommended fresh-machine flow

```bash
git clone https://github.com/easylager/ai-toolkit-max.git
cd ai-toolkit-max
./install.sh
```

Then, for each project you work in:

```bash
cd <project>
~/ai-toolkit-max/install.sh --project
```

Both are idempotent — safe to re-run any time. Two more modes, documented below: `./install.sh --portable` (degrade gracefully instead of failing, for locked-down environments) and `./install.sh --doctor` (health check only, no changes).

## Skills

Twenty-one skills, each a distinct mode of work rather than a fixed pipeline stage. None of them are mandatory gates — invoke only what the task warrants.

**PROJECT** — navigate work that spans more than one task. Skip entirely for a single task.

| Skill | Use it when |
|---|---|
| `/project` | Any time you want to know where the project is. Reports the current stage, the five questions, and the single next action — then takes that step: `DISCOVER` a goal, route a blocking choice to `/decide`, `DECOMPOSE` into a capability graph, hand a `READY` node to the task workflow, aggregate `VERIFY` results, or name what `HARDEN` still needs. Its only state is `.ai/project.md`, deliberately one screen long. |
| `/decide` | A choice has a real trade-off, is hard to reverse, or changes architecture — never for an implementation detail with one obvious answer. Produces a Decision Card — question, one recommendation, 2-3 reasons, 1-2 real alternatives when they exist, one trade-off — with a comparison matrix only when the trade-off is genuine. Stays `PROPOSED` until you pick: the agent proposes, you decide. |

**ENTRY** — decide how much process the task deserves.

| Skill | Use it when |
|---|---|
| `/classify` | At the start of any non-trivial task. Assesses complexity, risk, blast radius, and related dimensions, then recommends the minimum workflow chain — which skills to run, in what order. Doesn't clarify, plan, implement, or review itself. |

**AUTOMATE** — run the decided chain without invoking each skill by hand.

| Skill | Use it when |
|---|---|
| `/execute` | You want the recommended chain to run itself (`/execute` or `/execute TASK-NNN` to resume). Chains `/clarify` → `/design`/`/creative-explore` → `/plan` → `/estimate` → the execution loop → `/design-review` → `/review` within one invocation, checkpointing after every phase, stopping only at a Human Gate (Requirements, Creative Approval, a high-risk action, Final review), a blocker, a loop-detection limit, or `COMPLETE`. Runs autonomously within an invocation, not as an unattended background process — resuming after a closed session means re-invoking it. |

**THINK** — understand and reason about the problem, before code changes.

| Skill | Use it when |
|---|---|
| `/task` | Starting a task outside `/clarify`/`/plan` — from a bare idea or an existing note. Creates or opens the task's Task Context file (`.ai/tasks/TASK-NNN.md` by default, or the configured Obsidian vault). |
| `/research` | `/classify` flagged `research_required: true` (or a specific question is still open). Repository-aware investigation, targeted to the flagged uncertainty — not a full-repository scan. Persists a compact facts/patterns/open-questions summary to the task's `Research Notes`, so `/clarify`/`/plan` don't re-discover what it already found. Skip when nothing about the repo is actually uncertain. |
| `/clarify` | Before implementing anything ambiguous. Drafts an Acceptance Contract: candidate acceptance criteria classified CONFIRMED/INFERRED/UNKNOWN, their verification approach, and the questions needed to resolve what's open — the entry point for acceptance criteria in the workflow. Reuses `/research`'s `Research Notes` when present instead of re-deriving them. |
| `/design` | The task is UI-facing and no design context exists yet. Autonomously decides typography/color/composition/motion/3D (asking the user only for genuine business/brand input), builds a disposable HTML/CSS/JS prototype, iterates on it with the user in-browser, and hands off an `APPROVED` prototype as `/plan`'s primary UI source — replacing a Figma lookup when no Figma file exists. |
| `/creative-explore` | A significant visual project — a new major page, a new product surface, or an explicit request for something distinctive/premium. Generates 3-5 genuinely different creative concepts (not color variants), self-evaluates them, runs each through the Anti-Slop Review, and recommends one with reasoning. Skip for routine UI work — `/design`'s own autonomous Art Direction step is enough there. |
| `/plan` | Once requirements are clear. Produces a concise implementation plan anchored to `/clarify`'s acceptance criteria — every meaningful criterion mapped to a change and a test, flagged if it has neither. |
| `/impact` | The change touches shared code, public interfaces, migrations, or infrastructure. Affected surfaces, breaking changes, rollout risk — deeper than `plan`'s Risks line. Skip for isolated/local changes. |
| `/estimate` | Once a plan is approved. Decomposes it into the minimum reasonable number of executable slices, each covering specific acceptance criteria (goal, scope, dependencies, criteria covered, verification criteria, story-point estimate), and initializes the task's state. After work: actual vs. estimate, recorded for future calibration. |
| `/challenge` | A plan or decision carries real weight and has no second reviewer. Stress-tests the reasoning — weakest assumptions, simpler alternative, verdict. Not a repeat of `plan`'s risks. |

**EXECUTE** — manage incremental implementation against a plan.

| Skill | Use it when |
|---|---|
| `/next` | Deciding what to safely do next for a task (`/next` or `/next TASK-NNN`). The execution dispatcher: reads that task's plan, slice map, and state, and reports one canonical state — `READY`, `VERIFYING`, `BLOCKED`, `RECOVERABLE`, `REPLAN_REQUIRED`, or `COMPLETE` — routing automatically through verification/debug rather than making you orchestrate every step. `COMPLETE` means every acceptance criterion is verified, not just every slice touched. |
| `/verify` | The primary mechanism proving a slice is actually done — not code quality, that's `/review`. Checks each acceptance criterion the slice covers with the method it calls for (unit/integration/e2e/performance/security/manual/…) and marks it `VERIFIED`/`FAILED`/`BLOCKED`/`NOT_VERIFIED` with evidence. Never claims `VERIFIED` without it. |
| `/status` | Checking where things stand (`/status` or `/status TASK-NNN`) without changing anything. Reports one task's state and acceptance progress, or a compact list of all active tasks, straight from its Task Context file. |
| `/reconcile` | Resuming a task without the conversation context that produced its current state, or suspecting drift. Compares the persisted Task Context against the repo/git/conversation — new or changed acceptance criteria, human overrides, stale verification evidence — and flips status or marks evidence `STALE` when material. |

**QUALITY** — validate the result.

| Skill | Use it when |
|---|---|
| `/test` | Designing the test strategy for a change. Smallest useful set: must-test, edge cases, failure cases, optional. |
| `/review` | After a meaningful slice (local) or a finished feature (final). Finds problems first — Critical/High/Medium/Low — instead of rewriting half the project. Quality/architecture only; separate from `/verify`'s acceptance-criteria judgment — a change can pass one and not the other. |
| `/design-review` | After implementing a UI-facing task that went through `/design`, before `/verify`/`/review`. Renders the real (not prototype) UI in a browser, screenshots it, and critiques it against the Design Brief/Art Direction — hierarchy, spacing, generic-AI-aesthetic drift, a spot-check of responsive/motion/a11y/perf. The visual counterpart to `/review`. |
| `/debug` | Investigating a bug. Root-cause first, no speculative fixes, minimal fix at the end. `/verify` failures route here; the fix routes back to `/verify`. |
| `/short` | Compress any input — task, code, doc, plan, error, conversation — into a 1-2 sentence plain-language explanation. Compression, not analysis. |

**SETUP** — advise on project-specific Claude Code configuration. Independent of the workflow chain; run it any time.

| Skill | Use it when |
|---|---|
| `/audit` | Sizing up a project's Claude Code setup. Inspects the repo and recommends at most a handful of evidence-based customizations (rules, skills, hooks, subagents, MCP, tooling) justified by actual structure and recurring friction. Intentionally conservative — advisory only, never installs or modifies anything, and says so when nothing is missing. |

### Installing

Run `./install.sh` from a clone of this repo (see [Installation](#installation) above) — that's the supported path, and the only one that keeps this checkout as the single source of truth. `install.sh` drives the same underlying commands `/plugin marketplace add` and `/plugin install` would, non-interactively, plus validation and an idempotent refresh.

If you just want to try someone else's already-published copy without cloning it yourself, the plugin commands work directly inside a session too:

```
/plugin marketplace add easylager/ai-toolkit-max
/plugin install ai-toolkit-max@ai-toolkit-max
```

That has Claude Code fetch and manage its own copy from GitHub, separate from any local clone — fine for a quick try, but then *that* fetched copy is the source of truth, not a repo you control. For your own fork or local edits, use `./install.sh`.

Claude Code caches an installed plugin's content under an internal, version-numbered path, and only refreshes that cache when the plugin's version changes — editing files in this repo without bumping `.claude-plugin/plugin.json`'s version otherwise wouldn't take effect. `install.sh` sidesteps that by reinstalling on every run, so what's active always matches what's on disk here, regardless of version. This is also why `--doctor` can report a "stale cache": it means something installed the plugin without going through `install.sh`.

To remove it: `claude plugin uninstall ai-toolkit-max` and `claude plugin marketplace remove ai-toolkit-max`.

## Project state

When work spans more than one task, `/project` keeps a single dashboard at `.ai/project.md` — deliberately about one screen long, no history, no logs, no accumulated context. Full contract in `rules/core/project-state.md`.

```
.ai/
├── project.md      # stage · goal · next · blockers · open questions · decisions index · task graph
├── decisions.md    # PDEC-NNN Decision Cards
└── tasks/
    └── TASK-003.md # one node of the graph, once work on it starts
```

Six stages, five questions:

```
DISCOVER → DECIDE → DECOMPOSE → EXECUTE → VERIFY → HARDEN

[ ] Что строим?                  [ ] Как убедимся, что работает?
[ ] Как должно работать?         [ ] Что дальше?
[ ] Как построим?
```

- **The graph is behaviour, not files.** Nodes read "Пользователь может войти", never "создать модель / сериализатор / эндпоинт". Statuses are `BLOCKED`/`READY`/`IN_PROGRESS`/`DONE`/`FAILED` — nothing more.
- **A node becomes a task lazily.** Only when work starts does it get a `TASK-NNN.md`; from then on the task file is authoritative and the node's status is a derived mirror, never maintained twice.
- **Nothing accumulates.** Stale entries are overwritten, not appended beside their replacement. Detail lives in the task file, decision rationale in `.ai/decisions.md`, nothing in between.
- **Every technology and architecture decision is the human's.** `/decide` writes `PROPOSED`; only your choice makes it `ACCEPTED`. A project Human Gate exists exactly where a decision is hard to reverse, risky, architectural, or has a real trade-off — and nowhere else.
- **Project `VERIFY` aggregates, never re-verifies.** It reads the acceptance results already recorded by `/verify` in the task files.
- **Replanning changes the graph.** A node hitting `REPLAN_REQUIRED` means nodes get split, added, or dropped — not patched around.

```
/project
  DECOMPOSE

  - [x] Что строим?
  - [x] Как должно работать?
  - [ ] Как построим?   ←
  - [ ] Как убедимся, что работает?
  - [ ] Что дальше?

  Граф готов: AUTH-01, API-01, UI-01 — READY.

  Дальше: AUTH-01 → /classify
```

## Execution state

For tasks big enough to need multi-slice tracking across sessions, a task gets a stable id (`TASK-001`, `TASK-002`, …) and a persistent Task Context file — `.ai/tasks/TASK-NNN.md` at the root of the project you're working in by default, or wherever `TASK_CONTEXT_ROOT` resolves to (an external, possibly shared Obsidian vault — see `rules/core/task-context.md`):

```
.ai/
└── tasks/
    ├── TASK-001.md   # everything for this task: acceptance criteria, slices, state, decisions, human context
    └── TASK-002.md
```

```
TASK ──▶ classify ──▶ research (if needed) ──▶ clarify ──▶ plan+estimate ──▶ task file ──▶ next ──▶ slice ──▶ verify ──▶ task file ──▶ next ──▶ …
```

Created lazily — a task that doesn't need it never gets a task file or a `TASK-NNN` id. Full contract in `rules/core/execution-state.md` and `rules/core/task-context.md`, in short:

- **Acceptance criteria drive everything.** `/clarify` drafts them (`AC-NNN`, classified `CONFIRMED`/`INFERRED`/`UNKNOWN`), `/plan` finalizes and persists them into the task file, `/estimate` maps each slice to the criteria it covers, and `/verify` is what actually marks a criterion `VERIFIED` — with evidence, never on confidence alone. A task is `COMPLETE` when every criterion is `VERIFIED` (never `STALE`, `NOT_VERIFIED`, or `FAILED`), not when the code looks done. A criterion may also carry an optional capability hint (see [Capabilities](#capabilities) below) naming the MCP that most naturally supplies its evidence — advisory, never a blocker on its own.
- **One file per task is the single source of truth** for its position: status (`READY`/`EXECUTING`/`VERIFYING`/`BLOCKED`/`RECOVERABLE`/`REPLAN_REQUIRED`/`COMPLETE`), current slice, blockers, decisions, and each acceptance criterion's verification status (`VERIFIED`/`FAILED`/`BLOCKED`/`NOT_VERIFIED`/`STALE`) with its evidence — plus human-authored context (Objective, Business Context, Constraints, Human Overrides) in the same Obsidian-editable note. State is advisory; the repo (git diff, test output) is always ground truth.
- **Human edits always win.** A human can open the file directly, change an acceptance criterion, add an edge case, or write a `Human Overrides` note — Claude reconciles against the file fresh before every major step and treats those edits as authoritative, never silently reverting them.
- **Verification goes stale.** A `VERIFIED` result records the commit it was checked against; if relevant code changes afterward, `/reconcile` (or routine reconciliation before any major step) marks it `STALE` rather than leaving a falsely-current result in place.
- Only `/task`, `/clarify`, `/research`, `/plan`, `/estimate`, `/next`, `/verify`, `/reconcile`, and `/debug` (only for a durable edge case/decision) write inside a task file, and nowhere else — never source code, configs, or other project files.
- Commit `.ai/tasks/` to the project's own repo by default (or to the external vault's own repo, if `TASK_CONTEXT_ROOT` points at one), so a new session or a teammate can resume without replaying the conversation.

Work through it mostly with `/next` and `go`:

```
/next
  Task: TASK-003 — Migrate tenant authorization
  State: READY
  Slice: 3/5 — application authorization
  Covers: AC-002
  Verification: role checks enforced on all tenant routes; auth tests pass
  Ready to execute.

go
  ⋮ (implemented, then verified automatically)

/verify
  Acceptance:
  AC-002 VERIFIED
    Evidence: pytest tests/tenants/test_authz.py — 6 passed
  Overall: 2/4 criteria verified for this slice

/next
  Task: TASK-003 — Migrate tenant authorization
  State: RECOVERABLE
  One failing test, local to this slice.
  Next: /debug → /verify
```

`/status` answers "where are things" without touching anything:

```
/status
  TASK-001  COMPLETE
  TASK-002  EXECUTING  slice 2/4
  TASK-003  RECOVERABLE  slice 3/5

/status TASK-003
  TASK-003 — Migrate tenant authorization
  State: RECOVERABLE
  Current slice: 3/5
  Acceptance: 2/4 criteria verified
  Last action: application authorization implemented
  Next: /debug → /verify
  Blocked: no
```

## Rules

Markdown principle sets, grouped so you only pull in what's relevant to the project:

| File | Scope |
|---|---|
| `rules/core/engineering.md` | General engineering principles — simplicity, coupling, interfaces, dependencies, matching process depth to task complexity. |
| `rules/core/architecture.md` | Layering, dependency inversion, DDD — applied only when complexity justifies it. |
| `rules/core/quality.md` | Correctness, error handling, testing, observability. |
| `rules/core/security.md` | Secrets, untrusted input, least privilege. |
| `rules/core/execution-state.md` | The `.ai/` contract — the task file's location, the acceptance-criteria axes, the state machine, and that state is advisory. |
| `rules/core/project-state.md` | The project-level contract — `.ai/project.md`'s one-screen schema, the six stages and five questions, the task graph, and the Decision Card format. |
| `rules/core/task-context.md` | The Task Context document contract — schema, human/AI ownership, reconciliation, staleness, `TASK_CONTEXT_ROOT` resolution. |
| `rules/core/capabilities.md` | How to treat MCPs: minimum-capability selection, the registry of which MCP serves which skill, and default permission levels. |
| `rules/backend/python.md` | Python/FastAPI conventions — typing, async, thin routes, Pydantic. |
| `rules/frontend/design.md` | Premium/distinctive frontend principles — anti-generic-AI aesthetics, motion/3D/tokens/responsive/accessibility/performance as design, not an afterthought. Stack-agnostic. |
| `rules/frontend/react.md` | React conventions — composition, state, effects, accessibility. |

### Install rules

Rules aren't a plugin component Claude Code auto-loads — they're plain markdown pulled into a project's `CLAUDE.md` with an `@import` line, read straight from this checkout. (There's no stable path inside `~/.claude` to import from instead: a plugin installed from a local directory, which is what `install.sh` does, is cached internally under a version-numbered path that isn't meant to be referenced directly and won't update in place — this checkout's own path is the one stable, always-current reference.)

Run it for you:

```bash
./install.sh --project            # wires up the current directory
./install.sh --project /path/to/other-project
```

That creates (or, if one already exists, appends to) the project's `CLAUDE.md` with a clearly marked, regeneratable block:

```markdown
<!-- ai-toolkit-max:rules:start (managed by install.sh --project — do not hand-edit between markers) -->
@/absolute/path/to/ai-toolkit-max/rules/core/engineering.md
@/absolute/path/to/ai-toolkit-max/rules/core/architecture.md
@/absolute/path/to/ai-toolkit-max/rules/core/quality.md
@/absolute/path/to/ai-toolkit-max/rules/core/security.md
@/absolute/path/to/ai-toolkit-max/rules/core/execution-state.md
@/absolute/path/to/ai-toolkit-max/rules/core/task-context.md
@/absolute/path/to/ai-toolkit-max/rules/core/project-state.md
@/absolute/path/to/ai-toolkit-max/rules/core/capabilities.md
<!-- ai-toolkit-max:rules:end -->
```

The eight `core/` rules are always included. `backend/python.md` is added automatically when the project looks like it needs it (a `requirements.txt`/`pyproject.toml`/`*.py`); `frontend/design.md` is added whenever a `package.json` exists at all, and `frontend/react.md` on top of it specifically when that `package.json` depends on `react` — nothing is forced. Content outside the markers is never touched, and re-running is idempotent: it regenerates the block in place rather than duplicating it.

Claude Code may show a one-time prompt the first time a session loads a project with these imports, since the paths point outside the project — that's expected, approve it once.

Without running `install.sh --project`, you can still hand-write the same `@` lines yourself, pointing at wherever you cloned this repo.

## Capabilities

Skills decide *what* to do; capabilities decide *what Claude can reach* while doing it. There are two kinds — MCPs (external systems: Linear, GitHub, Figma, Context7, Playwright, Chrome DevTools, Sentry, Postgres) and the local filesystem/CLI. `rules/core/capabilities.md` has the full registry and default permission levels (e.g. Postgres read-only, GitHub minimum scope); `classify`'s "Potential capabilities" and each skill's `Capability:`/MCP hints point at it.

The rule everywhere it's referenced: an MCP is a hint, never a requirement. `clarify`, `plan`, `verify`, and `debug` use one only when it's the minimum capability that supplies evidence the repo can't, never invent access to one that isn't configured, and fall back to the best available local method — naming the gap only when it materially affects confidence. This toolkit never installs, configures, or bundles an MCP server itself (`./install.sh --doctor` confirms none were pulled in); it only documents how to use one if your session already has it.

## Doctor / health check

```bash
./install.sh --doctor
```

Read-only — makes no changes. Reports exactly what's installed, missing, or misconfigured: the `claude` CLI and its version, this repo's location and version, whether the marketplace is registered (and whether its registered path matches this checkout — catches a stray second clone), whether the plugin is installed and enabled, whether the installed skill set matches what's actually in `skills/` right now (catches a stale cache — see the note on `install.sh` below), that no MCP servers/hooks/agents have been pulled in, and how many rule files are present. Ends with **READY** or **NOT READY** plus a count of what's wrong; exits `0`/`1` to match.

## Portable / minimal mode

```bash
./install.sh --portable
```

Runs the same steps as plain `./install.sh`, but if the `claude plugin` commands can't complete — a locked-down or policy-restricted "fresh corporate" environment — it doesn't crash. It prints the exact `/plugin marketplace add` / `/plugin install` commands to run manually inside a session instead, and still finishes with a doctor check so you know precisely what did and didn't get set up. Never falls back to copying files into `~/.claude` — rules stay importable straight from this checkout either way.

## Tests

```bash
./tests/test_install.sh
```

Black-box tests for `install.sh` — fresh install, idempotency (no duplicate marketplaces/plugins on re-run), doctor's READY/NOT READY reporting, `--project` on both an empty and an existing `CLAUDE.md` (including that unrelated content survives and re-runs don't duplicate the managed block), `--portable` degrading instead of crashing, and unknown-flag handling. Runs entirely against an isolated `CLAUDE_CONFIG_DIR` and temp project directories — it never touches your real `~/.claude` or an actual project.

## Repo layout

```
.claude-plugin/
  plugin.json          # plugin manifest
  marketplace.json      # lets this repo be added as its own marketplace
install.sh              # bootstrap entrypoint — install/--project/--portable/--doctor
scripts/
  lib.sh                 # shared helpers (claude CLI detection, JSON parsing, CLAUDE.md block management)
  doctor.sh               # health check, used by install.sh --doctor and after every install
  project.sh               # --project: wires rules into a project's CLAUDE.md
tests/
  test_install.sh          # black-box tests, isolated from your real environment
skills/
  project/SKILL.md
  decide/SKILL.md
  classify/SKILL.md
  execute/SKILL.md
  task/SKILL.md
  clarify/SKILL.md
  research/SKILL.md
  design/SKILL.md
  creative-explore/SKILL.md
  plan/SKILL.md
  impact/SKILL.md
  estimate/SKILL.md
  challenge/SKILL.md
  next/SKILL.md
  verify/SKILL.md
  status/SKILL.md
  reconcile/SKILL.md
  test/SKILL.md
  review/SKILL.md
  design-review/SKILL.md
  debug/SKILL.md
  short/SKILL.md
  audit/SKILL.md
rules/
  core/
    engineering.md
    architecture.md
    quality.md
    security.md
    execution-state.md
    task-context.md
    project-state.md
    capabilities.md
  backend/
    python.md
  frontend/
    design.md
    react.md
```

## Deliberately excluded

`security`, `perf`, `api`, `llm`, `handoff`, `explore` are not skills here. Each either duplicates an existing rule (`rules/core/security.md`), duplicates a check already folded into `review` (performance, complexity), or has no concrete recurring need yet. Revisit only if real usage demonstrates a gap these don't cover.
