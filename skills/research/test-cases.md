# Research Skill — Test Cases

Manual-reasoning checks (this toolkit has no automated skill runner — same style as `skills/classify/test.sh`). Each case asserts expected *behavior*, not hardcoded repo facts, since real findings depend on the actual target repo. Each also asserts a negative: no unnecessary orchestration.

---

## Case 1: Simple — Fix typo in error message

**Task:** "Fix the typo in the error message on line 42 of `errors.py` where 'reccomend' should be 'recommend'."

**Expected classify output:** `research_required: false`. No `research_areas`.

**Expected behavior:**
- `/research` is never invoked — nothing to reduce uncertainty about.
- No task file is created for this alone.
- Chain: `implement → verify`.

**Negative assertions:**
- No subagents spawned.
- No `Research Notes` section ever created.

---

## Case 2: Medium — Add endpoint following existing `/users` pattern

**Task:** "Add a `GET /orders/:id` endpoint that follows the same pattern as the existing `/users/:id` endpoint."

**Expected classify output:** `research_required: true`, `research_areas: ["existing /users endpoint implementation", "routing/controller pattern"]` — generic, no invented file names.

**Expected `/research` behavior:**
1. Auto-detects or reads task from TASK-001 (created by classify earlier)
2. Reads `research_areas` from the task's Strategy: ["existing /users endpoint implementation", "routing/controller pattern"]
3. Decides: both areas are interdependent (routing IS the pattern) — spawns a single subagent covering both, briefed with the `/users` route/handler/convention question
4. Subagent searches (Bash/Grep/Read) for the `/users` route, handler, and conventions, reading only relevant files (route file, handler, schema/model) — not whole directories — and returns raw findings as text
5. Main agent synthesizes the subagent's findings
6. **Saves to task file** under `Comprehension Tips` section:
   - Facts: "routes are thin, delegate to service layer" (`routes/users.ts:15`)
   - Patterns: "each resource has `routes/<name>.ts` + `services/<name>.ts`"
   - Open Questions (if any): "whether `/orders` needs auth middleware" (Q-001)
7. Reports findings to user in same format

**Negative assertions:**
- Only one subagent spawned — areas are interdependent, so no parallel split
- Main agent's own context never runs Bash/Grep/Read directly for this
- Task file is updated with Comprehension Tips (not a separate Research Notes section)
- `/clarify` only asks about Q-001 (what research left open)
- `/plan` reads Comprehension Tips instead of re-searching

---

## Case 3: High uncertainty — Fix incorrect behavior in legacy billing calculation

**Task:** "Users are occasionally being billed the wrong amount by the legacy billing calculator. Fix it."

**Expected classify output:** `research_required: true`, `clarification_required: true`, `planning_required: true`, `verification_level: elevated`. `research_areas` stays generic (e.g., "current billing calculation logic", "recent related bug fixes/edge cases") — classify does not guess which function or file is wrong.

**Expected `/research` behavior:**
- The two areas are related (both about the same billing code path), so a single subagent is spawned to read the billing calculation code and return raw findings. Main agent states as Facts only what the code actually does (e.g., "rounding happens before tax is applied in `calculate_total`") — never states *why* it's wrong or what the intended behavior should be as fact.
- Anything about intended/correct behavior that the code doesn't itself answer (business rule, edge case handling, whether the bug is a race condition vs. a logic error) is recorded as an `Open Question`, not guessed.
- Distinguishes clearly: current (observed) behavior = Fact; correct/intended behavior = Open Question for a human, unless unambiguous from code/tests/comments.
- Does not propose a fix — that's `/plan`'s and implementation's job.

**Negative assertions:**
- `/research` never states an inference about intended behavior as a Fact.
- No planning or fix is attempted inside `/research`.
- Chain: `research → clarify → plan → implement → verify` (or `→ review`), with `verification_level: elevated` carried through to `/verify`'s method choice.

---

## Case 4: Feature — Allow users to upload profile images

**Task:** "Allow users to upload a profile image."

**Expected classify output:**
```yaml
strategy:
  state_required: true
  research_required: true
  research_areas:
    - existing file/media upload handling (if any)
    - user profile data model
    - image storage approach
  clarification_required: true
  planning_required: true
  verification_level: standard
```
Note: `research_areas` names *topics* only — never a concrete class, library, or storage service. Classify has not read the repo and must not invent that e.g. `MediaStorage` or `Pillow` exists.

**Expected `/research` behavior:**
1. Auto-detects or reads TASK-002 created by classify
2. Reads `research_areas`: ["existing file/media upload handling", "user profile data model", "image storage approach"]
3. **Decides parallelization**: "storage approach" is independent from "profile model" and "upload handling" — spawns two subagents: one for storage, one covering profile model + upload handling together. States: "Распределено на 2 параллельных investigator'ов: image storage approach; user profile data model + existing upload handling"
4. **Subagent A** investigates profile model + upload handling:
   - Profile model: finds `models/user.py`, notes "no image field yet"
   - Upload handling: finds existing `Document` upload pattern, discovers `S3Storage` helper
5. **Subagent B** investigates storage in parallel and returns findings (raw text)
6. **Main agent synthesizes**: merges both subagents' findings, deduplicates
7. **Saves to task file** `Comprehension Tips`:
   - Facts: "User model, no image field yet" (`models/user.py:42`), "S3Storage helper exists" (`storage/s3.py:1-50`), "Pillow is dependency" (`requirements.txt`)
   - Patterns: "uploads use Document → S3Storage pattern" (`uploads/document.py`)
   - Open Questions: Q-001: "Max file size policy?", Q-002: "Resize before upload?" (both Affects: image storage)

**Negative assertions:**
- Classify's `research_areas` are generic, not invented file names
- Main agent's own context never runs Bash/Grep/Read directly for this — both clusters go through subagents
- Subagents never write task file — only main research does
- `/clarify` does not re-explore storage/profile after research completes

---

## How to check

1. **Classify phase**: Run `/classify` on each task; confirm `research_required`/`research_areas` match expected shape (generic hints, no invented file names).

2. **Research phase**: Run `/research` (or `/research TASK-NNN`); confirm:
   - Scope matches task's `research_areas`
   - Only relevant files were read
   - Facts are grounded and cite files/modules
   - Uncertain items are Open Questions (Q-NNN), not Facts
   - At least one subagent was spawned (main agent never investigates directly); subagent count (1 vs. parallel) is justified by area independence, and each returns raw text only
   - **Main agent writes the task file** under `Comprehension Tips` section
   - Output report matches the saved facts/patterns/questions

3. **Idempotency**: Run `/research TASK-NNN` again; confirm it reports "Компрехеншены tips уже полные — новых фактов не найдено." without re-investigating.

4. **Clarify phase**: Run `/clarify` afterward; confirm it does not re-ask anything already in Comprehension Tips (only asks about Open Questions or new uncertainties).

5. **Plan phase**: Run `/plan` afterward; confirm it reads Comprehension Tips for patterns/facts instead of re-exploring those areas.
