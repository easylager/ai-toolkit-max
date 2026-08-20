# max-base-skills

A reusable engineering toolkit for Claude Code, split into two layers:

```
                    max-base-skills
                          │
          ┌───────────────┴────────────────┐
          │                                 │
        RULES                            SKILLS
          │                                 │
   ┌──────┼──────┐                 ┌────────┼───────┐
   ↓      ↓      ↓                 ↓        ↓       ↓
 core  backend frontend        clarify    plan    review
                                  test     debug
```

- **Rules** answer *how I should engineer* — always-on principles you pull into a project's `CLAUDE.md`.
- **Skills** answer *what process should I run now* — on-demand workflows you invoke with `/clarify`, `/plan`, etc.

## Skills

Five lean workflow skills for the core dev loop: **clarify → plan → test → review → debug**. Each one is deliberately short — a handful of rules and a fixed output shape — so Claude asks a few high-value questions instead of dumping 30 questions, 17 edge cases, and 12 NFRs on you.

| Skill | Use it when |
|---|---|
| `/clarify` | Before implementing anything ambiguous. Surfaces only high-impact ambiguities, edge cases, acceptance criteria, and open questions. |
| `/plan` | Once requirements are clear. Produces a concise implementation plan (approach, changes, data/API, tests, risks). |
| `/test` | Designing the test strategy for a change. Smallest useful set: must-test, edge cases, failure cases, optional. |
| `/review` | After Claude (or you) writes code. Finds problems first — Critical/High/Medium/Low — instead of rewriting half the project. |
| `/debug` | Investigating a bug. Root-cause first, no speculative fixes, minimal fix at the end. |

### Install skills (recommended)

Inside Claude Code:

```
/plugin marketplace add easylager/max-base-skills
/plugin install max-base-skills@max-base-skills
```

That installs the plugin — including the `rules/` files below — to `~/.claude/plugins/marketplaces/max-base-skills/`. The five skills become available in any session immediately. To update later:

```
/plugin marketplace update max-base-skills
```

### Manual install (fallback)

```bash
git clone https://github.com/easylager/max-base-skills.git
cp -r max-base-skills/skills/* ~/.claude/skills/
```

## Rules

Markdown principle sets, grouped so you only pull in what's relevant to the project:

| File | Scope |
|---|---|
| `rules/core/engineering.md` | General engineering principles — simplicity, coupling, interfaces, dependencies. |
| `rules/core/architecture.md` | Layering, dependency inversion, DDD — applied only when complexity justifies it. |
| `rules/core/quality.md` | Correctness, error handling, testing, observability. |
| `rules/core/security.md` | Secrets, untrusted input, least privilege. |
| `rules/backend/python.md` | Python/FastAPI conventions — typing, async, thin routes, Pydantic. |
| `rules/frontend/react.md` | React conventions — composition, state, effects, accessibility. |

### Install rules

Rules aren't a plugin component Claude Code auto-loads — they're plain markdown that you pull into a project's `CLAUDE.md` (or your global `~/.claude/CLAUDE.md`) with an `@import` line. Once the plugin above is installed, the files live at a stable path, so add only the ones relevant to the project:

```markdown
@~/.claude/plugins/marketplaces/max-base-skills/rules/core/engineering.md
@~/.claude/plugins/marketplaces/max-base-skills/rules/core/architecture.md
@~/.claude/plugins/marketplaces/max-base-skills/rules/core/quality.md
@~/.claude/plugins/marketplaces/max-base-skills/rules/core/security.md

@~/.claude/plugins/marketplaces/max-base-skills/rules/backend/python.md
@~/.claude/plugins/marketplaces/max-base-skills/rules/frontend/react.md
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
  test/SKILL.md
  review/SKILL.md
  debug/SKILL.md
rules/
  core/
    engineering.md
    architecture.md
    quality.md
    security.md
  backend/
    python.md
  frontend/
    react.md
```
