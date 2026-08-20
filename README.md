# max-base-skills

Five lean Claude Code skills for the core dev loop: **clarify → plan → test → review → debug**.

Each one is deliberately short — a handful of rules and a fixed output shape — so Claude asks a few high-value questions instead of dumping 30 questions, 17 edge cases, and 12 NFRs on you.

## Skills

| Skill | Use it when |
|---|---|
| `/clarify` | Before implementing anything ambiguous. Surfaces only high-impact ambiguities, edge cases, acceptance criteria, and open questions. |
| `/plan` | Once requirements are clear. Produces a concise implementation plan (approach, changes, data/API, tests, risks). |
| `/test` | Designing the test strategy for a change. Smallest useful set: must-test, edge cases, failure cases, optional. |
| `/review` | After Claude (or you) writes code. Finds problems first — Critical/High/Medium/Low — instead of rewriting half the project. |
| `/debug` | Investigating a bug. Root-cause first, no speculative fixes, minimal fix at the end. |

## Install on any machine (recommended)

Inside Claude Code:

```
/plugin marketplace add easylager/max-base-skills
/plugin install max-base-skills@max-base-skills
```

That's it — the five skills (`clarify`, `plan`, `test`, `review`, `debug`) become available in any session. To update later:

```
/plugin marketplace update max-base-skills
```

## Manual install (fallback)

If you'd rather not use the plugin system, clone the repo and drop the `skills/` contents into your personal skills directory:

```bash
git clone https://github.com/easylager/max-base-skills.git
cp -r max-base-skills/skills/* ~/.claude/skills/
```

## Repo layout

```
.claude-plugin/
  plugin.json        # plugin manifest
  marketplace.json    # lets this repo be added as its own marketplace
skills/
  clarify/SKILL.md
  plan/SKILL.md
  test/SKILL.md
  review/SKILL.md
  debug/SKILL.md
```
