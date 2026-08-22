# ai-toolkit-max

A reusable engineering toolkit for Claude Code, split into two layers:

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

- **Rules** answer *how I should engineer* — always-on principles you pull into a project's `CLAUDE.md`.
- **Skills** answer *what process should I run now* — on-demand workflows you invoke with `/clarify`, `/plan`, etc.

Process depth is meant to scale with the task. `classify` is the entry point: it looks at the task and recommends the minimum chain needed — a trivial change is just `implement → verify`; a risky or ambiguous one pulls in `clarify → plan → estimate → impact/challenge → next → implement → verify → review`. See `rules/core/engineering.md`. There's no skill for "implement" — writing the code is Claude's normal behavior, not a separate mode.

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

Fourteen skills, each a distinct mode of work rather than a fixed pipeline stage. None of them are mandatory gates — invoke only what the task warrants.

**ENTRY** — decide how much process the task deserves.

| Skill | Use it when |
|---|---|
| `/classify` | At the start of any non-trivial task. Assesses complexity, risk, blast radius, and related dimensions, then recommends the minimum workflow chain — which skills to run, in what order. Doesn't clarify, plan, implement, or review itself. |

**THINK** — understand and reason about the problem, before code changes.

| Skill | Use it when |
|---|---|
| `/clarify` | Before implementing anything ambiguous. Drafts an Acceptance Contract: candidate acceptance criteria classified CONFIRMED/INFERRED/UNKNOWN, their verification approach, and the questions needed to resolve what's open — the entry point for acceptance criteria in the workflow. |
| `/plan` | Once requirements are clear. Produces a concise implementation plan anchored to `/clarify`'s acceptance criteria — every meaningful criterion mapped to a change and a test, flagged if it has neither. |
| `/impact` | The change touches shared code, public interfaces, migrations, or infrastructure. Affected surfaces, breaking changes, rollout risk — deeper than `plan`'s Risks line. Skip for isolated/local changes. |
| `/estimate` | Once a plan is approved. Decomposes it into the minimum reasonable number of executable slices, each covering specific acceptance criteria (goal, scope, dependencies, criteria covered, verification criteria, story-point estimate), and initializes the task's state. After work: actual vs. estimate, recorded for future calibration. |
| `/challenge` | A plan or decision carries real weight and has no second reviewer. Stress-tests the reasoning — weakest assumptions, simpler alternative, verdict. Not a repeat of `plan`'s risks. |

**EXECUTE** — manage incremental implementation against a plan.

| Skill | Use it when |
|---|---|
| `/next` | Deciding what to safely do next for a task (`/next` or `/next TASK-NNN`). The execution dispatcher: reads that task's plan, slice map, and state, and reports one canonical state — `READY`, `VERIFYING`, `BLOCKED`, `RECOVERABLE`, `REPLAN_REQUIRED`, or `COMPLETE` — routing automatically through verification/debug rather than making you orchestrate every step. `COMPLETE` means every acceptance criterion is verified, not just every slice touched. |
| `/verify` | The primary mechanism proving a slice is actually done — not code quality, that's `/review`. Checks each acceptance criterion the slice covers with the method it calls for (unit/integration/e2e/performance/security/manual/…) and marks it `VERIFIED`/`FAILED`/`BLOCKED`/`NOT_VERIFIED` with evidence. Never claims `VERIFIED` without it. |
| `/status` | Checking where things stand (`/status` or `/status TASK-NNN`) without changing anything. Reports one task's state and acceptance progress, or a compact list of all active tasks, straight from `.ai/state.md`. |

**QUALITY** — validate the result.

| Skill | Use it when |
|---|---|
| `/test` | Designing the test strategy for a change. Smallest useful set: must-test, edge cases, failure cases, optional. |
| `/review` | After a meaningful slice (local) or a finished feature (final). Finds problems first — Critical/High/Medium/Low — instead of rewriting half the project. Quality/architecture only; separate from `/verify`'s acceptance-criteria judgment — a change can pass one and not the other. |
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

## Execution state

For tasks big enough to need multi-slice tracking across sessions, a task gets a stable id (`TASK-001`, `TASK-002`, …) and persistent state in `.ai/` at the root of the project you're working in (not this toolkit repo):

```
.ai/
├── plan.md        # the destination — plan + acceptance criteria + slice map, written by /plan, sliced by /estimate
├── state.md        # the current position of every task, incl. per-criterion verification status — one block per id, owned by /next + /verify
└── decisions.md     # meaningful decisions worth not rediscovering, append-only, tagged by task id
```

```
TASK ──▶ classify ──▶ clarify ──▶ plan+estimate ──▶ state ──▶ next ──▶ slice ──▶ verify ──▶ state ──▶ next ──▶ …
```

Created lazily — a task that doesn't need it never gets a `.ai/` folder or a `TASK-NNN` id. Full contract in `rules/core/execution-state.md`, in short:

- **Acceptance criteria drive everything.** `/clarify` drafts them (`AC-NNN`, classified `CONFIRMED`/`INFERRED`/`UNKNOWN`), `/plan` finalizes and persists them into `.ai/plan.md`, `/estimate` maps each slice to the criteria it covers, and `/verify` is what actually marks a criterion `VERIFIED` — with evidence, never on confidence alone. A task is `COMPLETE` when every criterion is `VERIFIED`, not when the code looks done.
- `.ai/state.md` is the single source of truth for a task's position: state (`READY`/`EXECUTING`/`VERIFYING`/`BLOCKED`/`RECOVERABLE`/`REPLAN_REQUIRED`/`COMPLETE`), current slice, last action, next action, blockers, and each acceptance criterion's verification status (`VERIFIED`/`FAILED`/`BLOCKED`/`NOT_VERIFIED`) with its evidence. State is advisory; the repo (git diff, test output) is always ground truth.
- Only `/next`, `/verify`, `/plan`, and `/estimate` write inside `.ai/`, and nowhere else — never source code, configs, or other project files.
- Commit `.ai/` to the project's own repo by default, so a new session or a teammate can resume without replaying the conversation.

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
| `rules/core/execution-state.md` | The `.ai/` contract — what `plan.md`/`state.md`/`decisions.md` mean, who writes what, and that state is advisory. |
| `rules/backend/python.md` | Python/FastAPI conventions — typing, async, thin routes, Pydantic. |
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
<!-- ai-toolkit-max:rules:end -->
```

The five `core/` rules are always included. `backend/python.md` or `frontend/react.md` are added automatically only when the project looks like it needs them (a `requirements.txt`/`pyproject.toml`/`*.py`, or a `package.json` depending on `react`) — nothing is forced. Content outside the markers is never touched, and re-running is idempotent: it regenerates the block in place rather than duplicating it.

Claude Code may show a one-time prompt the first time a session loads a project with these imports, since the paths point outside the project — that's expected, approve it once.

Without running `install.sh --project`, you can still hand-write the same `@` lines yourself, pointing at wherever you cloned this repo.

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
rules/
  core/
    engineering.md
    architecture.md
    quality.md
    security.md
    execution-state.md
  backend/
    python.md
  frontend/
    react.md
```

## Deliberately excluded

`security`, `perf`, `api`, `llm`, `handoff`, `explore` are not skills here. Each either duplicates an existing rule (`rules/core/security.md`), duplicates a check already folded into `review` (performance, complexity), or has no concrete recurring need yet. Revisit only if real usage demonstrates a gap these don't cover.
