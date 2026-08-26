# Lifecycle Planes

Not every slash command in this framework needs the same amount of reasoning. This file draws the line between the two kinds that exist today, so a command's existence as a Claude Code skill never implies paying full agentic cost for what is architecturally a deterministic read or write.

## Control Plane

Deterministic, single-turn, mechanical operations — a lifecycle command's own contract asks for a bounded read or write, not a judgment call:

- `/task` — create or open a Task Context file.
- `/status` — read persisted task state and report it verbatim.

A Control Plane skill's own `SKILL.md` is the authority on what it may do; this file states what it may **not**, absent a named exception in that skill's own rules:

- No repository-wide investigation beyond the resolved task root (`rules/core/task-context.md`'s `TASK_CONTEXT_ROOT` resolution). A duplicate-title check or a frontmatter glob is in scope; searching source code, git history, or the filesystem outside the resolved root is not.
- No spawning subagents or background agents.
- No invoking the Supervisor decision model (`rules/core/execution-state.md`'s Supervisor decision model section) — that model is `/execute`'s, not a Control Plane skill's.
- No reading `rules/core/execution-state.md` beyond its Execution History format section, cited by name — never the whole file. A Control Plane skill has no use for the Supervisor Inputs/Decision table, Autonomy, Loop detection, Execution mode, or Event ownership sections.
- Genuine ambiguity (e.g. more than one plausible task root, an unclear duplicate match) is resolved by asking the human directly, one bounded question — never by searching the filesystem or the repository for evidence to disambiguate.

## Reasoning Plane

Everything that requires actual judgment keeps its existing agentic path, unchanged by this file:

- `/clarify`, `/plan`, `/design`, `/creative-explore`, `/execute`, `/review`
- Genuinely ambiguous architectural decisions, semantic interpretation, creative reasoning

## Not yet classified

`/next`, `/estimate`, `/verify`, `/reconcile`, and `/design-review` are deliberately left unclassified here. Each has its own mix of deterministic dispatch and judgment (e.g. `/next` reconciles repo state before deciding; `/verify` has to interpret whether evidence actually satisfies a criterion) that hasn't been diagnosed against this boundary yet. Do not assume they default to either plane — that determination is future work, not a gap to guess at.

## Future extensions

This boundary is the seam future work hangs off of, not the finished system:

- **Context Pack** — what a Control Plane skill reads today (a task's frontmatter, a resolved root) is a first, informal instance of a bounded context contract; a full Context Pack would formalize it per-task.
- **Context Budget** — the prohibitions above are today enforced by instruction only; a future budget mechanism could enforce them structurally.
- **Model Routing** — a Control Plane operation is exactly the kind of case where "no model, or the cheapest one" would apply, if this framework ever routes by model per skill.

None of these are implemented by this file — it only names where they'd attach.
