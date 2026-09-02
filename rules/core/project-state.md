# Project State

The project-level layer above `rules/core/task-context.md`. One project = one dashboard file. It answers *where are we, what matters now, what's next* — nothing else.

For shared skill constraints, see `rules/core/common-rules.md`.

## Navigator, not orchestrator

`/project` is a read/analyse/recommend operation only. It MUST NOT invoke other skills or perform implementation actions. It may update compact project state when reflecting already established information, but it must never autonomously advance the project by executing the next workflow action.

`/project` показывает следующий шаг, но никогда не делает его за пользователя.

Concretely: `Goal`, `Flow`, `Verification` candidates, the `Decisions` index, and a node's derived `status` are all `/project` recording a fact that is *already true* elsewhere — a doc says so, a card is `ACCEPTED`, a task file shows real progress. That's reporting, always allowed on a bare call. `Task Graph` is different — it's authored by `/decompose` (`skills/decompose/SKILL.md`), a separate skill the user runs explicitly; `/project` only ever displays it, never writes or triggers it. Sufficient information for the next stage is not the same thing as that stage having happened — accepted technology decisions make a project *ready* for `DECOMPOSE`, not decomposed.

## Location

`.ai/project.md` at the root of the project. Created lazily by `/project` — a single task never needs one.

## Five questions

The mental model of the whole system. `/project` reports progress through them, always in this order:

```
[ ] Что строим?                    DISCOVER
[ ] Как должно работать?           DECIDE
[ ] Как построим?                  DECOMPOSE
[ ] Как убедимся, что работает?    EXECUTE → VERIFY
[ ] Что дальше?                    HARDEN
```

Six stages, five questions — `EXECUTE` and `VERIFY` answer the same one. Never invent a seventh stage.

A question is checked `[x]` only when its stage's output actually exists in the file: a goal is written; every blocking decision is `ACCEPTED`; the task graph exists; every node is `DONE` with its acceptance criteria verified; harden findings are recorded. The current stage is marked `←`.

## DECOMPOSE readiness gate

Technology decisions being `ACCEPTED` is not the same as the project being ready for `DECOMPOSE`. Before `/project` recommends running `/decompose`, these must be sufficiently understood — not exhaustively specified, just enough that decomposition and implementation stop being guesswork:

- **What** — what's being built, who the user is, MVP scope (`Goal`).
- **Behaviour** — the main user flow and business rules, not just the happy path (`Flow`).
- **Edge cases** — for anything the flow depends on, especially external dependencies: not-found, invalid/malformed input, timeout, temporary failure, missing optional data, duplicate/concurrent action if relevant. Not every case needs its own decision, but the behaviour must be knowable, not guessed at implementation time.
- **Architecture** — the decisions that actually matter are `ACCEPTED` (`Decisions`); component boundaries and external integrations are understood.
- **Verification** — there's a real, even short, answer to "how do we know it works" that also covers the main failure scenarios (`Verification`).
- **Scope** — what's in the MVP and what's explicitly out.

Don't turn this into bureaucracy: no full PRD, no exhaustive edge-case catalogue, no API contracts, no full test plan, no pile of Decision Cards — this is a small project, not a spec exercise. The test for whether a gap belongs here: *would leaving it unresolved change architecture, behaviour, scope, or verification?* Resolve only those. Everything else is a task-level detail, resolved once work starts on that node (`/clarify`, `/research`), not here.

`/project` reports unmet gaps against this gate as `Open Questions`; it never marks the gate satisfied by inventing an answer. `/decompose` re-checks the same gate before writing anything (see below) — a premature `/decompose` call reports the gaps instead of guessing.

## Schema

`.ai/project.md` must fit roughly on one screen. If it doesn't, something belongs in a task file or nowhere.

```
---
project: <slug>
stage: DISCOVER | DECIDE | DECOMPOSE | EXECUTE | VERIFY | HARDEN
updated_at: <YYYY-MM-DD>
---

# <project name>

## Goal
<1-3 lines — what we are building and for whom>

## Flow
<2-5 lines — how it works end-to-end; omit the section while unknown>

## Progress
- [x] Что строим?
- [ ] Как должно работать?   ←
- [ ] Как построим?
- [ ] Как убедимся, что работает?
- [ ] Что дальше?

## Next
<exactly one action — the smallest useful next step>

## Blockers
<one line each, or empty — what is needed and from whom; omit the section body when none>

## Open Questions
- Q-N <question> — blocks: <node id / stage>

## Decisions
- PDEC-NNN <question> → <choice> — ACCEPTED | PROPOSED

## Verification
<candidate ways to confirm the MVP works, incl. main failure scenarios — omit the section while unknown>
- [ ] <e.g. external API mapping / failure-handling tests>
- [ ] <e.g. frontend loading / not-found / error states>
- [ ] <e.g. end-to-end happy path>

## Task Graph
| id | capability | status | depends | task |
|---|---|---|---|---|
| AUTH-01 | Пользователь может зарегистрироваться | READY | — | TASK-003 |
```

Node statuses: `BLOCKED` / `READY` / `IN_PROGRESS` / `DONE` / `FAILED`. Nothing else — this is not a workflow engine.

`Goal` answers *Что строим?*, `Flow` answers *Как должно работать?*. Both stay absent until confidently known from a source of truth (user statement, `docs/`) — never filled with invented detail to make the dashboard look complete. `Verification` starts as candidate items `/project` derives from `Goal`/`Flow`/`Decisions` while checking the DECOMPOSE readiness gate — each stays `[ ]` until a node's task file records real evidence for it (`rules/core/task-context.md`), then `[x]`. Listing candidates is analysis, not action; it needs no explicit trigger.

## No accumulation

There is no history, log, or decision rationale in `project.md`. Stale information is **overwritten**, never appended next to its replacement. Anything that grows over time lives elsewhere:

- per-task detail (acceptance criteria, slices, evidence, execution history) → the node's `TASK-NNN.md` (`rules/core/task-context.md`);
- decision rationale → `.ai/decisions.md` (below).

If a section can be re-derived from a task file in one read, it does not belong here.

## Task graph

Nodes describe **behaviour or capability**, never files or layers: "Пользователь может войти", not "создать модель / сериализатор / эндпоинт". Decomposition finds capabilities and vertical slices first — technical breakdown (models, endpoints, clients) is a task-level concern that shows up later, inside a node's own plan.

`/decompose` is the sole author of `Task Graph`. It runs only when the user explicitly invokes it, only once the DECOMPOSE readiness gate (above) holds — otherwise it reports the same gaps `/project` would and writes nothing. `/project` only ever reads and displays the graph; it never creates, extends, or triggers it.

A node is a graph entry until work starts on it. Only then does it get a `TASK-NNN.md`, created the normal way (`/classify`, or `/task` for a bare node), and from that moment **the task file is authoritative**: the node's `status` is a derived mirror of it, regenerated on read, never hand-maintained in two places. A node with no task file yet has `—` in its `task` column.

```
PROJECT → readiness gate → /decompose → node → classify → clarify → plan → estimate → execute → verify → node DONE
```

`/project`'s `EXECUTE`-stage job is to pick the single `READY` node that most blocks progress and recommend the command to work it (`/classify`, or `/execute TASK-NNN` once a task file exists) — never to invoke that skill itself. `stage` advances to `EXECUTE` only once a node's task file already shows real progress, a fact `/project` observes rather than creates.

Project-level `VERIFY` aggregates the nodes' already-recorded acceptance results. It never re-verifies criteria itself and never marks anything `VERIFIED` — that stays `/verify`'s job against a task file.

## Decisions

`/decide` is not an ADR generator and does not chase "the one correct answer." Its job: find the decision that actually needs making right now, look into it if that changes the answer, and propose the best call — one recommendation, not an absolute truth.

A decision is worth a card only if at least one is true:

- it changes architecture;
- it affects behaviour that matters;
- it's hard or expensive to reverse later;
- there's a meaningful trade-off between real options.

Otherwise it's an implementation detail — decide it inline while building, no card. "GET for listing tickets" is not a decision; "PostgreSQL vs SQLite vs in-memory for ticket storage" is. Don't manufacture a card to look thorough — a small project with one obvious choice at every step should produce zero cards, not fifteen.

Not limited to technology choices — a behavioural policy the DECOMPOSE readiness gate flags (how to handle an external API timeout, whether to retry, where to normalize a response, what "not found" means to the user) is just as much a `PDEC-NNN` candidate as a stack pick, judged by the same four-part test.

Project decisions are `PDEC-NNN` and live in `.ai/decisions.md`, one compact Decision Card each — distinct from a task's own `DEC-NNN` (`rules/core/task-context.md`), which stays inside that task file. `project.md` carries only the one-line index.

```
## PDEC-NNN
Question: <what's being decided>
Recommendation: <option>
Why:
- <2-3 bullets>
Alternatives: <omit if none material>
- <option> — <one-line why not>
Trade-off: <one line — the recommendation's own cost>
Status: PROPOSED | ACCEPTED | SUPERSEDED by PDEC-NNN
```

Cards are short by contract. `Alternatives` lists only real, relevant options — 1-2 at most — never a padded list of things nobody would pick; omit it entirely when the recommendation is simply the obvious choice. No context section, no reasoning transcript.

## Human authority

**Every technology and architecture decision belongs to the human, not the agent.** The agent analyses, recommends, and executes; it never writes `ACCEPTED` on its own. A card stays `PROPOSED` until the user picks. A user's choice against the recommendation is recorded as chosen, without re-arguing.

A project-level Human Gate exists exactly where a decision is hard to reverse, carries real risk, changes architecture, or has a meaningful trade-off. Everything else the agent just does. On a gate, `stage` stays put, the reason goes in `Blockers`, and `Next` names what the user has to decide — the actual question ("how should tickets be stored?"), never a bare instruction to run a command.

## Reading docs/

`DISCOVER` and `/decide` are the stages most likely to need `docs/` (requirements, constraints, external specs) — see `rules/core/common-rules.md`'s Source of truth section for the boundary. Read only what the current question needs, never the whole tree, and never re-read what `project.md` or a task's `Comprehension Tips` already answers compactly.

A `/project @path` call names the docs to read directly — read exactly that path (file or directory) and extract only what's confidently there for `Goal`/`Flow`, nothing invented. If that's enough to answer both, `DISCOVER` completes and advances to `DECIDE` in the same pass — don't hold at `DISCOVER` or manufacture open questions just to keep the dashboard busy. If it isn't enough, the gap becomes a specific `Open Question`, not a generic "requirements unclear." A doc that only spells out the happy path leaves the DECOMPOSE readiness gate's edge-case and verification dimensions open — say so specifically (e.g. "external API timeout behaviour"), don't treat happy-path coverage as the whole picture.

## Reconciliation

`project.md` is advisory; task files and the repo are ground truth. Re-read it fresh off disk before acting (`rules/core/common-rules.md`), refresh node statuses from their task files, and if a node's task went `REPLAN_REQUIRED` (`rules/core/execution-state.md`), change the graph — split, add, or drop nodes — instead of patching around a plan that is already wrong.

## Timebox

Under a hard timebox the stages compress, they do not disappear:

```
0-10 DISCOVER · 10-20 DECIDE · 20-25 DECOMPOSE · 25-70 EXECUTE · 70-82 VERIFY · 82-90 HARDEN
```

Prefer a good-enough answer now over an exhaustive one later: ask what matters now, what can be skipped, what the smallest useful next step is.
