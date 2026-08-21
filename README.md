# ai-toolkit-max

A reusable engineering toolkit for Claude Code, split into two layers:

```
                    ai-toolkit-max
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

Process depth is meant to scale with the task: a trivial change is just `implement → verify`; a risky or ambiguous one pulls in `estimate → clarify → plan → impact/challenge → next → implement → verify → review`. See `rules/core/engineering.md`. There's no skill for "implement" — writing the code is Claude's normal behavior, not a separate mode.

## Skills

Eleven skills, each a distinct mode of work rather than a fixed pipeline stage. None of them are mandatory gates — invoke only what the task warrants.

**THINK** — understand and reason about the problem, before code changes.

| Skill | Use it when |
|---|---|
| `/clarify` | Before implementing anything ambiguous. Surfaces only high-impact ambiguities, edge cases, acceptance criteria, and open questions. |
| `/plan` | Once requirements are clear. Produces a concise implementation plan (approach, changes, data/API, tests, risks). |
| `/impact` | The change touches shared code, public interfaces, migrations, or infrastructure. Affected surfaces, breaking changes, rollout risk — deeper than `plan`'s Risks line. Skip for isolated/local changes. |
| `/estimate` | Before work: a range estimate with assumptions and uncertainty exposed. After work: actual vs. estimate, recorded in a structured format for future calibration. |
| `/challenge` | A plan or decision carries real weight and has no second reviewer. Stress-tests the reasoning — weakest assumptions, simpler alternative, verdict. Not a repeat of `plan`'s risks. |

**EXECUTE** — manage incremental implementation against a plan.

| Skill | Use it when |
|---|---|
| `/next` | Deciding what to safely build next. Reads `.ai/` + the repo and reports Ready (a vertical slice, not the next plan item), Blocked, Plan invalidated, or Complete. |
| `/verify` | The current slice needs objective proof before moving on — tests, lint, types, build. Reports PASS/FAIL/UNKNOWN per check; never claims success without evidence. |

**QUALITY** — validate the result.

| Skill | Use it when |
|---|---|
| `/test` | Designing the test strategy for a change. Smallest useful set: must-test, edge cases, failure cases, optional. |
| `/review` | After a meaningful slice (local) or a finished feature (final). Finds problems first — Critical/High/Medium/Low — instead of rewriting half the project. |
| `/debug` | Investigating a bug. Root-cause first, no speculative fixes, minimal fix at the end. `/verify` failures route here; the fix routes back to `/verify`. |
| `/short` | Compress any input — task, code, doc, plan, error, conversation — into a 1-2 sentence plain-language explanation. Compression, not analysis. |

### Install skills (recommended)

Inside Claude Code:

```
/plugin marketplace add easylager/ai-toolkit-max
/plugin install ai-toolkit-max@ai-toolkit-max
```

That installs the plugin — including the `rules/` files below — to `~/.claude/plugins/marketplaces/ai-toolkit-max/`. All eleven skills become available in any session immediately. To update later:

```
/plugin marketplace update ai-toolkit-max
```

### Manual install (fallback)

```bash
git clone https://github.com/easylager/ai-toolkit-max.git
cp -r ai-toolkit-max/skills/* ~/.claude/skills/
```

## Execution state

For tasks big enough to need multi-slice tracking across sessions, `/next` and `/verify` read and write `.ai/` at the root of the project you're working in (not this toolkit repo):

```
.ai/
├── plan.md        # the destination — plan + intended slices, written by /plan
├── state.md        # the current position — in progress/complete/verified/failing/next
└── decisions.md     # meaningful decisions worth not rediscovering, append-only
```

Created lazily — a task that doesn't need it never gets a `.ai/` folder. Full contract in `rules/core/execution-state.md`, in short:

- State is advisory; the repo (git diff, test output) is always ground truth.
- Only `/next`, `/verify`, `/plan`, and `/estimate` write inside `.ai/`, and nowhere else — never source code, configs, or other project files.
- Commit `.ai/` to the project's own repo by default, so a new session or a teammate can resume without replaying the conversation.

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

Rules aren't a plugin component Claude Code auto-loads — they're plain markdown that you pull into a project's `CLAUDE.md` (or your global `~/.claude/CLAUDE.md`) with an `@import` line. Once the plugin above is installed, the files live at a stable path, so add only the ones relevant to the project:

```markdown
@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/core/engineering.md
@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/core/architecture.md
@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/core/quality.md
@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/core/security.md
@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/core/execution-state.md

@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/backend/python.md
@~/.claude/plugins/marketplaces/ai-toolkit-max/rules/frontend/react.md
```

Drop the `backend`/`frontend` lines that don't apply to a given project. Without the plugin installed, clone the repo anywhere and import from that path instead.

## Repo layout

```
.claude-plugin/
  plugin.json          # plugin manifest
  marketplace.json      # lets this repo be added as its own marketplace
skills/
  clarify/SKILL.md
  plan/SKILL.md
  impact/SKILL.md
  estimate/SKILL.md
  challenge/SKILL.md
  next/SKILL.md
  verify/SKILL.md
  test/SKILL.md
  review/SKILL.md
  debug/SKILL.md
  short/SKILL.md
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
