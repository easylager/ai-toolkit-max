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
- Scope comes from classify's `research_areas` (no task file yet, per Scope's priority order).
- Searches directly (Bash/Grep/Read in main-agent context) for the `/users` route, its controller/handler, and surrounding conventions — not a subagent, since this is one small, non-independent area.
- Reads only the files actually relevant to that one endpoint and its immediate pattern (route file, handler, maybe a schema/model file) — not the whole `routes/` or `controllers/` directory.
- Persists Facts (e.g., "routes are thin, delegate to a service layer") and Patterns (e.g., "each resource has `routes/<name>.ts` + `services/<name>.ts`") to `Research Notes`; anything genuinely ambiguous (e.g., whether `/orders` needs the same auth middleware) becomes an `Open Question`.
- `/clarify` then only asks about what research left open (e.g., the auth-middleware question) — it does not re-ask "how are existing endpoints structured," since `Research Notes` already answers that.
- `/plan` reuses `Research Notes` for the affected-files/pattern step instead of re-searching.

**Negative assertions:**
- No subagent spawned — one small area, handled inline.
- Chain includes `research` before `clarify`: `research → clarify → plan → implement → verify` — no unnecessary `design`/`creative-explore` (backend-only), no elevated verification (no stated risk/complexity driver).
- `/plan` does not redo step 2-4 file discovery for what `Research Notes` already covered.

---

## Case 3: High uncertainty — Fix incorrect behavior in legacy billing calculation

**Task:** "Users are occasionally being billed the wrong amount by the legacy billing calculator. Fix it."

**Expected classify output:** `research_required: true`, `clarification_required: true`, `planning_required: true`, `verification_level: elevated`. `research_areas` stays generic (e.g., "current billing calculation logic", "recent related bug fixes/edge cases") — classify does not guess which function or file is wrong.

**Expected `/research` behavior:**
- Investigates the billing calculation code directly, reads it, and states as Facts only what the code actually does (e.g., "rounding happens before tax is applied in `calculate_total`") — never states *why* it's wrong or what the intended behavior should be as fact.
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
- For each area, identifies the relevant part of the repo (e.g., `models/user.py`, any existing `upload`/`media` module, storage config).
- Discovers and records the *actual* repository-specific facts classify could not have known — e.g. "profile data lives in `User` model, no image field yet," "an `S3Storage` helper already exists and is used by `Document` uploads," "Pillow is already a dependency" — each tagged with the file/module it came from.
- If the areas are genuinely independent and substantial (e.g., "storage backend" vs. "profile model" vs. "existing upload validation conventions" are three separate subsystems), may delegate one area per subagent — stating briefly why — with subagents returning raw findings only; this agent alone writes `Research Notes`.
- Persists Facts/Patterns/Implications; anything the repo doesn't resolve (e.g., max file size policy, whether resizing is required) becomes an `Open Question` for `/clarify`.

**Negative assertions:**
- Classify's `research_areas` contain no file names, class names, or specific library names — those only appear after `/research` runs.
- If subagents are used, they never write the task file directly — only the main `/research` invocation does.
- `/plan` does not start repository exploration from scratch for storage/profile-model — it reads `Research Notes` first.

---

## How to check

1. Run `/classify` on each task description; confirm `research_required`/`research_areas` match the expected shape above (generic hints, no invented specifics) and that `research_mode` does not appear anywhere in the output.
2. Where research is required, run `/research` and confirm: scope matches what classify/task file provided, only relevant files were read (ask it to state what it read), Facts are grounded and cite a file/module, uncertain items are Open Questions not Facts, and subagents (if any) were justified and did not write the task file themselves.
3. Run `/clarify` afterward and confirm it does not re-ask anything `Research Notes` already answered.
4. Run `/plan` afterward and confirm its Changes/affected-files reasoning cites `Research Notes` rather than re-deriving them.
