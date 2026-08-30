---
name: research
description: Repository-aware investigation that reduces uncertainty from a task's `Strategy` or explicit areas — always delegates the actual digging to one or more subagents (never in this agent's own context) to keep raw search noise out of the main conversation, decides whether independent areas warrant parallel subagents, and persists a compact summary of returned findings to the task's `Comprehension Tips`. Not a full-repository audit; skip when nothing is uncertain.
---

# Research

Reduce specific uncertainties about the repository — not "learn the codebase." Investigate only what's needed to answer the question(s) at hand.

## Invocation

```
/research                          # No args: use the one active task, its Strategy's research_areas
/research TASK-NNN                  # Explicit task: use that task's research_areas
/research area1, area2              # Explicit areas: investigate these (task file optional)
/research TASK-NNN area1, area2     # Explicit task + override areas
```

Task resolution without an explicit id follows `/next`'s convention (`rules/core/task-context.md` Location): exactly one active task → use it; more than one → list briefly and ask; none — if explicit areas were given, investigate them without a task file; if none were given either, say so in one line and stop.

## Scope

Take the areas to investigate from, in priority order:

1. Explicit areas given in this invocation (override all other sources).
2. `research_areas` from the task's `Strategy` section (`/classify`'s output).
3. Unresolved `Open Questions` already affecting a research area.

Investigate only the areas in scope. Do not scan the whole repository "just in case," and do not treat `research_areas` as a list of files to open — they're conceptual hints (`/classify` never names files); finding the actual files, classes, and patterns is this skill's job.

## Workflow

1. For each area in scope, identify the relevant part of the repository (directory, module, layer).
2. Always delegate the actual digging (Bash/Grep/Read) to subagent(s) — never investigate directly in this agent's own context. Decide only how many, from what the areas turn out to be, never from a flag set upstream:
   - **Single investigator (default)** — areas are interdependent or share context (e.g. "data model" and "API endpoints" both need the schema) — spawn one subagent covering all areas together.
   - **Multiple, in parallel** — some areas are genuinely independent *and* substantial enough that parallel investigation saves real time (e.g. "auth mechanism" vs. "database connection pooling" share nothing) — spawn one subagent per independent cluster, state briefly why before spawning. One subagent per cluster, not one per area or per file.
3. Brief each subagent with the specific area(s) and question(s) in scope — not "explore the codebase." Subagents return raw findings as text only; they never write the task file. This agent is the only writer — read what they return, synthesize, deduplicate, and decide what's a fact vs. still open.
4. Classify every finding:
   - **Fact** — grounded in code actually read (name the file/module briefly so it can be checked). Never state an inference as a fact.
   - **Pattern** — an existing convention or repeated design choice relevant to this task.
   - **Open Question** — ambiguous, contradictory, or something the repo doesn't answer.
5. Stop once the areas in scope are addressed. Don't keep exploring for completeness.

## Rules

- Follow `rules/core/common-rules.md`'s Investigation bounds — no repository-wide search beyond what's in scope for this task.
- Only the task's Task Context file may be written (`rules/core/task-context.md`). Create it (same `TASK-NNN` allocation `/clarify`/`/plan`/`/classify` use) only if findings are worth persisting and none exists yet; otherwise reconcile first (re-read fresh off disk, note human edits), then update its `Comprehension Tips` section. Never write source code or any other file.
- Persist findings, not process: never record which files were opened, which greps ran, or dead ends followed. Keep only what a later phase would otherwise have to re-derive, or could get wrong without it (`rules/core/common-rules.md`'s Output brevity applies to the task file too, not just chat).
- Merge into existing `Comprehension Tips` rather than duplicating it — update a Fact if new evidence changes it, add genuinely new ones, leave unrelated existing entries alone. This is what makes research safe to re-invoke for one targeted follow-up question later.
- Open Questions raised here use the same `Q-NNN` convention `/clarify` uses (`Open Questions` is a Shared-owned section, not exclusive to `/clarify`) — `Affects:` names the acceptance criterion if one already exists, otherwise the research area or component.
- Do not touch `phase` — research doesn't own a workflow phase and can run again later without re-running `clarify`/`plan` (`rules/core/execution-state.md`). Append one `RESEARCH` `Execution History` event summarizing what changed (facts added/updated, questions raised) — or that this pass confirmed there was nothing new to add. Persist-before-report (`rules/core/common-rules.md`): write, re-read to confirm, only then report.
- Do not draft acceptance criteria (`/clarify`'s job), do not produce an implementation plan (`/plan`'s job), do not write implementation code.
- If every area in scope is already answered by existing `Comprehension Tips`, say so plainly and don't re-investigate.

## Output (in Russian)

Begin with the Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>` — omit only if no task file exists yet and none was created this pass.

One line first stating delegation: `Делегировано 1 investigator'у: <area1>, <area2>, ...` (single) or `Распределено на N параллельных investigator'ов: <cluster1>, <cluster2>, ...` (multiple).

```
### Факты
- <finding> (<file/module>)

### Паттерны
- <existing convention relevant to this task>

### Открытые вопросы (если есть)
- Q-NNN: <question> — Affects: <AC id or area>
```

Omit any subsection with nothing in it. If this pass found nothing new beyond what's already persisted, say so in one line instead of repeating the sections.
