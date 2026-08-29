---
name: research
description: Repository-aware investigation that reduces the uncertainty `/classify` flagged (or a specific open question) — finds relevant existing facts and patterns, tells fact from assumption, and persists a compact summary to the task's Research Notes. Not a full-repository audit; skip when nothing is actually uncertain.
---

# Research

Reduce a specific uncertainty about the repository — not "learn the codebase." Investigate only what's needed to answer the question(s) at hand.

## Scope

Take the areas to investigate from, in priority order:

1. An area/question given explicitly in this invocation.
2. Unresolved `Open Questions` in the task's Task Context file, or `/classify`'s `research_areas` recorded there.
3. `/classify`'s `research_areas` from this conversation, if no task file exists yet.

Investigate only the areas in scope. Do not scan the whole repository "just in case," and do not treat `research_areas` as a list of files to open — they're conceptual hints (`/classify` never names files); finding the actual files, classes, and patterns is this skill's job.

## Workflow

1. For each area in scope, identify the relevant part of the repository (directory, module, layer).
2. Search directly — Bash/Grep/Read in the main agent's context — for existing patterns, conventions, and related implementations. This is the default for every area.
3. Delegate an area to a subagent only when it is genuinely independent of the other areas in scope *and* substantial enough that parallel investigation actually saves time — decide this here, from what the areas turn out to be, never because `research_required: true` was set upstream. State briefly why before spawning. One subagent per independent area, not one per file.
4. Subagents return raw findings as text only; they never write the task file. This agent is the only writer — read what they return, synthesize, deduplicate, and decide what's a fact vs. still open.
5. Classify every finding:
   - **Fact** — grounded in code actually read (name the file/module briefly so it can be checked). Never state an inference as a fact.
   - **Open Question** — ambiguous, contradictory, or something the repo doesn't answer.
6. Stop once the areas in scope are addressed. Don't keep exploring for completeness.

## Rules

- Follow `rules/core/common-rules.md`'s Investigation bounds — no repository-wide search beyond what's in scope for this task.
- Only the task's Task Context file may be written. Create it (`rules/core/task-context.md`, same `TASK-NNN` allocation `/clarify`/`/plan` use) if none exists yet and the findings are worth persisting; otherwise reconcile first (re-read fresh off disk, note human edits), then update its `Research Notes` and `Open Questions` sections. Never write source code or any other file.
- Persist findings, not process: never record which files were opened, which greps ran, or dead ends followed. Keep only what a later phase would otherwise have to re-derive, or could get wrong without it (`rules/core/common-rules.md`'s Output brevity applies to the task file too, not just chat).
- Merge into existing `Research Notes` rather than duplicating it — update a Fact if new evidence changes it, add genuinely new ones, leave unrelated existing entries alone. This is what makes research safe to re-invoke for one targeted follow-up question later.
- Open Questions raised here use the same `Q-NNN` convention `/clarify` uses (`Open Questions` is a Shared-owned section, not exclusive to `/clarify`) — `Affects:` names the acceptance criterion if one already exists, otherwise the research area or component.
- Do not touch `phase` — research doesn't own a workflow phase and can run again later without re-running `clarify`/`plan` (`rules/core/execution-state.md`). Append one `RESEARCH` `Execution History` event summarizing what changed (facts added/updated, questions raised) — or that this pass confirmed there was nothing new to add. Persist-before-report (`rules/core/common-rules.md`): write, re-read to confirm, only then report.
- Do not draft acceptance criteria (`/clarify`'s job), do not produce an implementation plan (`/plan`'s job), do not write implementation code.
- If every area in scope is already answered by prior Research Notes, say so plainly and don't re-investigate.

## Output (in Russian)

Begin with the Task header (`rules/core/common-rules.md`): `Task: TASK-NNN — <title>` — omit only if no task file exists yet and none was created this pass.

```
### Факты
- <finding> (<file/module>)

### Паттерны
- <existing convention relevant to this task>

### Выводы
- <what this implies for clarify/plan>

### Открытые вопросы (если есть)
- Q-NNN: <question> — Affects: <AC id or area>
```

Omit any subsection with nothing in it. If this pass found nothing new beyond what's already persisted, say so in one line instead of repeating the sections.
