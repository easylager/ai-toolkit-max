# Design Engine Architecture — Research Report

Date: 2026-08-24
Status: Research only. No source files were modified to produce this report. Contains proposals for future TASKs — none created.

## Scope and method

This report researches the architecture for a future high-quality "Design Engine" inside AI Studio (ai-toolkit-max) — the subsystem that decides whether a task needs design work, how much, generates high-fidelity interactive prototypes, gets human approval, and hands off to implementation. It is grounded in AI Studio's actual mechanisms, read in full for this report:

- `rules/core/execution-state.md` — the Supervisor decision model, Human Gates, execution modes, event vocabulary.
- `rules/core/task-context.md` — the Task Context file schema, ownership matrix, reconciliation, staleness.
- `rules/core/architecture.md`, `rules/core/capabilities.md`, `rules/core/quality.md`, `rules/core/security.md`.
- `skills/classify/SKILL.md`, `skills/clarify/SKILL.md`, `skills/plan/SKILL.md`, `skills/estimate/SKILL.md`, `skills/execute/SKILL.md`, `skills/verify/SKILL.md`, `skills/review/SKILL.md`, `skills/reconcile/SKILL.md`.
- `skills/design/SKILL.md`, `skills/design-review/SKILL.md`, `skills/creative-explore/SKILL.md`, and the principles they apply from `rules/frontend/design.md`.
- The four prior-art design docs from 2026-08-23: `docs/plans/2026-08-23-design-skill.md`, `2026-08-23-design-skill-design.md`, `2026-08-23-task-context-design.md`, `2026-08-23-task-context.md`.
- `README.md` for overall system framing.

**Important finding before anything else**: the prior-art docs in `docs/plans/` describe an *earlier* version of `/design` (a bare prototype-only skill, no Design Brief, no Art Direction, no Anti-Slop Review, no Asset Strategy, no `creative_autonomy`, no category-prefixed criteria ids). The **current** `skills/design/SKILL.md`, `skills/creative-explore/SKILL.md`, `skills/design-review/SKILL.md`, and `rules/frontend/design.md` have already evolved substantially past that plan — apparently in later, uncommitted-to-`docs/plans/` work. This report treats the *current skill files* as the authoritative baseline (not the older plan docs), and flags every place a recommendation would add to, rather than duplicate, what's already built. Every divergence from either source is called out explicitly in the relevant section and summarized in §13.

A few web searches were used for narrow, dual-use technical grounding (iframe/CSP sandboxing for untrusted generated HTML, GSAP/Framer Motion/R3F selection criteria, visual-regression/accessibility tooling) — cited inline where used. The report is not a generic design-engineering survey; every recommendation is stated in terms of AI Studio's classify → clarify → plan → estimate → execute → verify → review → reconcile pipeline, its Task Context file, and its AUTONOMOUS/SUPERVISED execution modes.

---

## 1. Executive recommendation

Build the Design Engine as an **extension of the existing THINK-phase design skills, not a parallel subsystem**. Concretely:

1. **Don't add a Design Classifier skill.** Fold design-intensity determination into `/clarify` as a byproduct of the Acceptance Contract it already drafts, with `/design` itself owning the final call and downgrade/upgrade authority. A dedicated classifier would be a fifth THINK skill duplicating work `/clarify` already does over the same input (§3).
2. **Replace the implicit binary ("is this UI-facing?") with an explicit, small multi-dimensional profile** persisted in Task Context frontmatter — not a single NONE/STANDARD/RICH/SUPER_RICH enum, and not a numeric score. Five independent boolean/tri-state fields, cheap to reason about, cheap for a human to override (§4).
3. **Introduce a `design_budget` field**, human-settable and Design-Agent-recommendable, that caps how far the intensity profile is allowed to escalate autonomously — the guardrail against over-engineering design when the product doesn't benefit (§5).
4. **Keep `/design` a single skill with internal stages**, not a decomposed multi-agent pipeline. `/creative-explore` already exists as the separable "many concepts, pick one" stage for high-intensity work; that's the one seam worth keeping as its own skill. Everything else (research, art direction, asset strategy, prototyping) stays inside `/design`'s existing stage structure. Do not introduce Motion Design or Prototype Engineering as separate agents yet (§6).
5. **Keep prototypes as disposable, self-contained HTML/CSS/JS files** (`design/prototypes/*.html`) — already the architecture — and layer isolation onto *how they're rendered for review* (a sandboxed iframe with a restrictive CSP), not onto the artifact format itself (§7, §11).
6. **Model iteration as Task Context Decisions + git history on one mutable file**, matching the existing "one file per task, human edits win, reconcile before acting" model — not a new versioning scheme (§9).
7. **Extend the four existing Human Gates**, don't add a fifth. Creative Approval already covers `/design`/`/creative-explore` `DRAFT` states; the work here is making the gate's *content* scale with intensity (a one-line approval for STANDARD vs. a scored critique packet for CINEMATIC), not inventing a new gate type (§8, §12).

This is deliberately conservative: AI Studio's existing architecture (Supervisor decision model, Task Context ownership matrix, capability registry, Human Gates) already has the load-bearing joints a Design Engine needs. The research questions below are mostly about *how much new machinery is actually justified* versus how much is already covered by generalizing an existing mechanism a bit further.

---

## 2. Recommended architecture

```
Task → /classify → /clarify → (design profile persisted) → /plan → /estimate
                                      │
                          design_required: NONE?
                                      │ no
                          ┌───────────┴────────────┐
                          │                         │
                    /creative-explore          (skip — /design's own
                  (only if intensity ≥        Art Direction step is enough)
                   PREMIUM or SUPER_RICH             │
                   or explicitly requested)          │
                          │                         │
                          └───────────┬─────────────┘
                                      ▼
                                  /design
                    (Design Brief → Art Direction → Asset Strategy →
                     Prototype → DRAFT/APPROVED loop)
                                      │
                         Human Gate: Creative Approval
                                      │ APPROVED
                                      ▼
                                   /plan  (prototype = primary UI source)
                                      │
                                  /estimate
                                      │
                              implement (per slice)
                                      │
                              /design-review  (implementation vs. prototype)
                                      │
                                   /verify
                                      │
                                   /review
                                      │
                                 /reconcile (on resume/drift)
                                      │
                              Human Gate: Final review
                                      │
                                  COMPLETE
```

This is the existing chain in `README.md`/`rules/core/execution-state.md` (`clarify → design/creative-explore → plan → estimate → execute loop → design-review → review`) with one addition made explicit: **the design-intensity profile is a first-class decision that happens inside `/clarify`, gets read by `/design` to decide its own ceremony level, and is persisted in Task Context frontmatter** so `/execute`'s Supervisor Decision (`rules/core/execution-state.md` §Decision) can route on it without re-deriving it at every phase boundary. Nothing here adds a new phase value to the `phase:` enum in `rules/core/task-context.md` — `design` and `creative-explore` already exist as phases; the profile is new *frontmatter*, not a new *phase*.

No new orchestrator is introduced. `/execute`'s Supervisor already re-evaluates at every phase boundary (`rules/core/execution-state.md`'s Supervisor decision model) and already knows to insert `design`/`creative-explore` conditionally — extending it to read a persisted intensity profile instead of inferring "is this UI-facing" fresh each time is a strict simplification of what it already does, not new complexity.

---

## 3. Classification/routing model

### Q1 — where design requirements get decided

Four options were evaluated:

| Option | Reliability | Separation of concerns | Recovery from ambiguity | Human override | Autonomous compatibility | Impl. complexity |
|---|---|---|---|---|---|---|
| (A) `/classify` decides | Low — `/classify` explicitly "does not clarify requirements" (`skills/classify/SKILL.md`) and only sees the raw request, not confirmed business context | Violates `/classify`'s own stated boundary — it recommends a workflow chain, it doesn't set persisted parameters that downstream phases depend on | Poor — `/classify` runs once, at the very top, before ambiguity is resolved | Awkward — there's no persisted field yet at that point to override | Fine | Low |
| (B) `/clarify` decides | High — `/clarify` already produces the Acceptance Contract design depends on (states/data/interactions), and already creates the Task Context file | Natural — `/clarify`'s existing job ("what does this feature need to do") already implies most of the intensity signal | Good — `/clarify` is explicitly re-enterable (`REPLAN_REQUIRED` routes back through it) and its output is `INFERRED`/`UNKNOWN`-tagged, so an intensity guess can be provisional the same way a criterion can | Good — same mechanism as any other `INFERRED` field: human edits the persisted value, it's authoritative | Fine — persisted before `/design` ever runs, so the Supervisor Decision can read it | Low — reuses an existing skill's existing output shape |
| (C) dedicated Design Classifier skill | High in isolation, but duplicates `/clarify`'s work over the same input | Worst — a sixth THINK skill whose entire input is a subset of what `/clarify` already reads, immediately re-triggering `/clarify`'s process depth debate ("why does this task need two clarification passes") | No better than (B) — still one-shot unless re-invoked | Fine | Adds a phase boundary the Supervisor must route through even for NONE-design tasks | Highest — new skill file, new phase value, new event types, new classify-chain entry |
| (D) Hybrid: `/clarify` drafts, `/design` confirms/escalates on contact with actual product understanding | Highest — two independent checks, same as the `Requirement`/`Result` two-axis pattern the Task Context already uses everywhere | Clean — matches the existing precedent that `/clarify` drafts and a later skill promotes/finalizes (exactly how Acceptance Criteria already work: `/clarify` drafts `INFERRED`, `/plan` finalizes) | Best — `/design` can revise the profile once it actually engages with product positioning, without a second full clarification pass | Best — override at either point, same Task Context ownership rules | Fine | Low-to-moderate — no new skill, two small additions to existing skills |

**Recommendation: (D), implemented as a light version of (B) plus a confirmation step already latent in `/design`.**

- `/clarify` adds one lightweight judgment to its existing output: a draft `design_required` classification (`NONE`/`STANDARD`/`RICH`/`SUPER_RICH` — see §4 for why this is the wrong final model but an adequate *draft* signal) with the same `CONFIRMED`/`INFERRED`/`UNKNOWN` status every other criterion gets. This is not a new skill capability — it's the same judgment `/clarify` already implicitly makes when it decides whether a request is UI-facing enough to draft `VISUAL-`/`RESPONSIVE-`/`A11Y-` category criteria (`skills/design/SKILL.md`'s "Design-specific acceptance criteria may use category-prefixed ids" already assumes this judgment happens somewhere upstream).
- `/design` reads that draft on entry (exactly like it already reads `creative_autonomy`), and its existing Design Brief step (`skills/design/SKILL.md` — "before any visual decision, establish: what the product is, who uses it...") is precisely the point where a bad `/clarify`-time guess gets caught and corrected, because `/design` has now actually engaged with product positioning that `/clarify` may not have had reason to probe deeply. If `/design` revises the profile, it persists the revision as a `DEC-NNN` Decision (the same mechanism it already uses for Art Direction changes) — never silently overwrites the frontmatter without a record.
- `/classify` keeps its current, narrower role unchanged: it still only decides *whether `design`/`creative-explore` appear in the recommended chain at all* (`skills/classify/SKILL.md`'s existing "Recommend `design` only for tasks that are visibly UI/frontend-facing" rule) — a coarse yes/no gate before any real classification happens, not the classification itself. This is consistent with `/classify`'s explicit charter ("Does not clarify requirements... recommend the skill for that instead of doing it").

This diverges from nothing in the prior-art docs (they don't address design classification at all — `/design` was UI-facing-only, binary, in the original plan) and is additive to the current `skills/design/SKILL.md`, which already implies a product-first judgment but never names or persists it as a field.

### Q5 — backend / frontend / full-stack / marketing behavior, and Q13 — routing table

Task type is an **input signal**, not the classifier — the actual intensity comes from what the task's Acceptance Contract implies about the user-facing surface, which `/clarify` already derives per-task rather than from a category label. But task type is a strong prior worth encoding as guidance (not a hard rule) in `/clarify`'s judgment:

| Task class | Example | Typical `design_required` | Why |
|---|---|---|---|
| Backend-only | "Add pagination to the users endpoint" | `NONE` | No new user-facing surface; `/design` never enters the chain, matching `/classify`'s existing "omit it from the chain for backend-only work" rule |
| Admin/internal CRUD | "Add a table view for managing API keys" | `STANDARD` | Functional clarity and consistency matter; premium visual differentiation doesn't — low Design Budget by default (§5) |
| SaaS product surface | "Dashboard for managing insurance claims" | `RICH` | Product usability and visual coherence matter to retention; this is `/design`'s existing default ceremony level (Design Brief + Art Direction + single-direction prototype) |
| Full-stack feature | "Add a claims-export feature with a UI and a backend job" | Derived from the *frontend* portion only | The backend slice(s) still classify `NONE` at the slice level once `/estimate` decomposes the plan — design intensity is a property of the UI-facing surface, not the task as a whole. This matters for `/estimate`: a full-stack task's slice map should not force every slice through `/design-review`, only the UI slices. |
| Marketing/landing page | "Launch page for an AI logistics company" | `SUPER_RICH` (default), escalate to `CINEMATIC` only on explicit request or a `/creative-explore` recommendation that earns it | Conversion and brand impression are the entire point of the surface; this is exactly the case `/creative-explore` already exists for ("a new major landing page, a new product surface, or an explicit request for something distinctive/premium") |
| Cinematic product experience | Explicit ask for something award-show-grade | `CINEMATIC`, always gated by Design Budget (§5) and always through `/creative-explore` | Highest technical complexity and highest risk of the Anti-Slop Review failing if not backed by strong positioning |

Routing table (Q13), mapping intensity → concrete workflow steps — this generalizes what `skills/classify/SKILL.md` and `skills/design/SKILL.md` already state piecemeal into one table:

| `design_required` | `/design` ceremony | `/creative-explore` | Prototype scope | `/design-review` | Human Gate content |
|---|---|---|---|---|---|
| `NONE` | Skipped entirely | Skipped | None | Skipped | None — design never enters the chain |
| `STANDARD` | Prototype only, no Design Brief/Art Direction (`skills/design/SKILL.md`'s existing "small, isolated UI change" fast path, generalized to "low-stakes surface" rather than only "small edit") | Skipped | Whole surface, functional fidelity, minimal motion | Optional — only if `/classify` flagged elevated risk | One-line approve/revise |
| `RICH` (default for new product surfaces) | Full sequence: Design Brief, Art Direction (single direction, `creative_autonomy`-gated), Asset Strategy | Skipped unless explicitly requested | Hero + one representative section minimum, full surface before `/plan` | Required | Design Brief/Art Direction summary + screenshot |
| `SUPER_RICH` | Full sequence, Art Direction sourced from an *approved* `/creative-explore` concept | Required | Hero fully built, scroll narrative/major transitions defined explicitly per `rules/frontend/design.md` | Required, with Anti-Slop Review re-run against the live render | Full Creative Evaluation table + Anti-Slop Review outcome + Self-Critique |
| `CINEMATIC` | Full sequence, plus explicit 3D/motion budget line items (§6) | Required, 4-5 concepts | Multiple concepts prototyped enough to compare (per `/creative-explore`'s existing rule), then the winning concept built out fully including major scroll transitions | Required, plus a performance spot-check (frame rate, initial load) | Full Creative Evaluation + a stated performance budget the human is approving alongside the visuals |

This table is a *description* of what the existing skills already do differently at different implied intensities (`/design`'s "scale the ceremony to the task" line, `/classify`'s conditional `creative-explore` recommendation) — made explicit and keyed off a persisted field instead of left as each skill's own re-derived judgment call every time.

---

## 4. Design intensity model

### Q2 — what to persist, and what shape

**Recommendation: reject a single enum as the persisted representation; use five independent fields**, one coarse "headline" enum for human legibility plus four tri-state/boolean dimensions for machine routing. This directly answers the prompt's challenge to evaluate NONE/FUNCTIONAL/PRODUCT/PREMIUM/CINEMATIC or a score/budget model against separate dimensions.

Why not a single enum (NONE/STANDARD/RICH/SUPER_RICH or any relabeling of it): a landing page can need heavy visual/motion complexity but zero 3D and zero asset generation; an admin dashboard can need `human_review_required: true` (a compliance-sensitive internal tool where a designer must sign off) while being visually `STANDARD`. Collapsing these into one enum forces the routing table in §3 to either over- or under-provision workflow steps for the dimension that doesn't match the headline label. This is the same reasoning the Task Context schema already applies to Acceptance Criteria: `Requirement` and `Result` are two independently-owned axes precisely *because* they change at different times and correlate imperfectly — the same logic applies to design intensity.

Why not a raw numeric score/budget model instead: `rules/core/task-context.md`'s existing fields (`priority`, `creative_autonomy`, `execution_mode`) are all qualitative enums a human can read and override at a glance in Obsidian. A 0–100 "design score" would be harder for a human to sanity-check on sight and harder for `/design` to justify ("why did this task get a 62?") than a small set of named levels — this is the qualitative-over-precision principle `/classify` already states explicitly ("Use qualitative levels (Trivial/Low/Medium/High), not scores").

**Proposed frontmatter fields** (new, in `rules/core/task-context.md`'s schema):

```
design_required: NONE | STANDARD | RICH | SUPER_RICH | CINEMATIC
visual_complexity: LOW | MEDIUM | HIGH        <derived from design_required, overridable>
motion_complexity: NONE | SUBTLE | RICH        <independent — a RICH-visual dashboard can be NONE-motion>
three_d_required: true | false                 <default false — see rules/frontend/design.md's existing "why does it need to be 3D" gate>
asset_generation_required: true | false        <whether the Asset Strategy needs generation/sourcing beyond SVG/CSS>
human_design_review_required: true | false     <default = (design_required != NONE); can be forced true independent of intensity, e.g. compliance>
```

This keeps `design_required` as the one headline field most consumers (routing table, `/classify`, a human skimming the file) actually need, while the four supporting dimensions exist for the cases where they diverge from what the headline implies — each overridable independently, same ownership rules as everything else in Task Context (§9). `prototype_required` is deliberately **not** a separate field: per the routing table, a prototype is required for every `design_required` value except `NONE`, so it would be a redundant derived fact, not new information — adding it would violate the same "don't duplicate state that already exists" principle `rules/core/task-context.md` invokes for why there's no separate implementation-status field.

**Naming**: keep `NONE`/`STANDARD`/`RICH`/`SUPER_RICH` (the labels already used in the prompt and implied by the existing skills) rather than switching to `FUNCTIONAL`/`PRODUCT`/`PREMIUM`, and add `CINEMATIC` as a fifth level above `SUPER_RICH` for the explicit "cinematic product experience" case in the prompt's own examples — `SUPER_RICH` alone doesn't distinguish "ambitious landing page" from "award-show 3D experience," and those have materially different Design Budget and technology implications (§5, §10). This is the one place this report *introduces* a new label beyond what's implied by existing files; flagged here because it's a naming decision, not an architectural one, and easy to relabel later without disturbing anything else.

---

## 5. Design budget model

### Q3

**Recommendation: a `design_budget` field — `LOW`/`MEDIUM`/`HIGH`/`EXTREME` — that caps how far `/design`/`/creative-explore` may autonomously escalate technique (§6), independent of `design_required`.**

Why a separate field from `design_required` rather than folding budget into intensity: intensity answers "how much visual/product effort does this surface deserve," budget answers "how much technical/performance/complexity risk is this project willing to carry to get there." A `SUPER_RICH` landing page for a performance-sensitive mobile-first product might warrant `MEDIUM` budget (rich art direction, but no WebGL) — that distinction is exactly what `rules/frontend/design.md`'s existing "Quality budget" section ("For every major visual technique... ask what its communication value actually is; if the complexity exceeds that value, remove it") is already gesturing at without a persisted, settable value to point to.

How the budget is set — evaluated against the prompt's five options:

- **Explicitly requested**: the human can set `design_budget` directly, same override precedent as `priority`/`creative_autonomy`/`execution_mode` (all "optional, human-set" in `rules/core/task-context.md`'s existing schema).
- **Inferred**: `/clarify`/`/design` propose a default from `design_required` (`STANDARD→LOW`, `RICH→MEDIUM`, `SUPER_RICH→HIGH`, `CINEMATIC→EXTREME`) — a sensible starting correlation, not a hard link, since the whole point of a separate field is letting them diverge.
- **Constrained by task type**: not a separate mechanism — task type already feeds the `design_required` inference in §3, which feeds the budget default above. No third input needed.
- **Recommended by the Design Agent**: `/design`'s existing Art Direction step already states "decide the visual direction yourself by default... ask only when a decision genuinely needs business/brand input" — the same posture applies here: `/design` can recommend raising the budget (e.g., "this concept genuinely needs one purposeful 3D moment to land — raise budget to HIGH?") but never raises it unilaterally past what's persisted, for the same reason it doesn't unilaterally decide `creative_autonomy`.
- **Overridden by the human**: always wins, same Task Context ownership rule as everything else.

**Recommendation: inferred by default, with `/design` allowed to *recommend* (never silently apply) an increase, and the human able to set or cap it explicitly.** This mirrors `creative_autonomy`'s existing default-`HIGH`-but-overridable pattern exactly, so it needs no new mental model for someone already using this toolkit.

`design_budget` gates technique choice, not ceremony — it answers "is a 3D hero justified here," not "does this task get a Design Brief." Concretely: at `LOW`, `/design` may not reach for 3D, video, generated imagery, or scroll-driven parallax regardless of `design_required`; at `EXTREME`, all of §6's techniques are available subject to the existing per-technique justification gate in `rules/frontend/design.md` ("before adding 3D, answer explicitly why it needs to be 3D"). This makes budget the practical enforcement mechanism for a principle the rules file already states in prose but has no persisted lever for.

---

## 6. Design Agent architecture

### Q7

Evaluated: single agent vs. decomposed capabilities (Design Research → Art Direction → Asset Selection/Generation → UI Design → Motion Design → Prototype Engineering → Design Critique) vs. sequential pipeline vs. parallel agents vs. supervisor-driven orchestration.

**Recommendation: keep `/design` as a single skill with internal sequential stages (already true today), keep `/creative-explore` as the one separable skill for high-intensity concept generation (already true today), and do not decompose further.**

Reasoning, evaluated against the prompt's explicit instruction not to assume more agents = better:

- The seven-stage decomposition in the prompt (Research → Art Direction → Assets → UI → Motion → Prototype → Critique) already exists *as stages inside one skill file*, not as separate agents: `skills/design/SKILL.md`'s current structure is literally Product-first (research) → Art Direction → Prototype, with Asset Strategy and motion/3D decisions folded into Art Direction, and `skills/design-review/SKILL.md` already *is* the Critique stage — deliberately kept as its own skill because it runs at a different time (against the real implementation, post-`/plan`, not against the prototype) and is read-only where `/design` is write-heavy. That's the correct seam — critique-of-the-real-thing is genuinely a different job at a different pipeline position, not the same job split for org-chart reasons.
- Splitting further (a standalone "Motion Design" agent, a standalone "Asset Selection" agent) would mean each new agent needs its own context reconstruction of the Design Brief and Art Direction already settled by the stage before it — the same overhead problem this codebase's own subagent guidance warns about (context that isn't already shared has to be re-derived). Inside one skill invocation, later stages just read earlier stages' output in the same conversation; across separate agent invocations, they'd need it re-fed or re-read from a persisted artifact, for no benefit since these stages are never independently useful (nobody wants "just the motion design" without the Art Direction it has to match).
- **Where decomposition *does* pay for itself**: `/creative-explore` generating 3-5 independent concepts is a case where genuine parallelism helps (concepts should not contaminate each other's thinking) — and this is exactly the one place AI Studio already breaks `/design` into a separate skill. That's the model to extend, not abandon: **decompose only the stage that benefits from independent, non-contaminating exploration; keep sequential, context-sharing stages inside one skill.**
- Supervisor-driven orchestration across sub-agents (a Design Supervisor dispatching to Research/Assets/Motion/Prototype agents) would duplicate `/execute`'s existing Supervisor Decision loop at a smaller scope, with no new decision types it actually needs to make — `/design`'s internal stages aren't independently resumable, retriable, or skippable in ways that need Supervisor-grade state tracking; they're a fixed sequence within one invocation, same as `/clarify`'s internal structure (draft criteria → classify status → generate questions) is a fixed sequence, not a sub-orchestration.

**The smallest architecture that scales**: today's two skills (`/design`, `/creative-explore`) plus `/design-review`, unchanged in count. The scaling lever for future intensity levels is *not* more agents — it's more internal stage detail inside `/design` (e.g., an explicit Motion Design sub-section for `CINEMATIC`-tier tasks, per §13) and a richer Asset Strategy (§10). If real usage later demonstrates that, say, 3D/WebGL prototyping genuinely needs a different skill invocation lifecycle than 2D prototyping (different tools, different review cadence, different failure modes), that's the one seam worth revisiting — and even then, follow the `/creative-explore` precedent (split only the part that benefits from an independent invocation) rather than a wholesale re-architecture.

### Q8 — visual research / asset discovery

`rules/frontend/design.md`'s existing Asset Strategy preference order (generate → licensed/sourced → SVG/CSS/Canvas → procedural → 3D/GLTF → product's own UI → no asset) already answers most of Q8's mechanics. What it doesn't yet address, and what the Design Engine should add:

- **Reference research is input to originality, never a template.** `skills/creative-explore/SKILL.md` already states this exactly: "Never instruct the implementation to 'look like' a specific existing site, and never copy one directly; references are inspiration, not templates." Extend this stated rule (no file change needed here — this is existing behavior, restated for completeness) to explicitly cover images returned by an image-search capability, not just textual research: an image found via search may inform palette/composition/motion *language*, never be reproduced, cropped, or lifted as an asset in the prototype.
- **Copyright/licensing discipline belongs in the Asset Strategy's existing preference order, not a separate policy.** The order already de-prioritizes "a suitable licensed/source asset" below "generate an original asset" — meaning the safest asset (generated, no licensing question) is already preferred over the riskiest (sourced, needs a license check) by construction. The one gap: if a sourced asset actually gets used, its license/attribution should be recorded as a `DEC-NNN` Decision in Task Context (`rules/core/task-context.md`'s existing Decisions section, `skills/design/SKILL.md`'s existing pattern of persisting Art Direction decisions there) — so a future session or reviewer can see *why* a non-generated asset was chosen and what its terms are, without inventing a new section.
- **Screenshots of competitor/reference products** (explicitly named in Q8) are the one category that needs an explicit constraint not yet stated anywhere: they may inform the Design Brief's positioning research (what does this category typically do, what would differentiate us) but must never appear as an asset or be used as a literal layout template in the prototype — this is a strengthening of the existing Anti-Slop Review's spirit ("could this belong to 50 other SaaS companies") applied to sourced references specifically, and should be added as one line to `rules/frontend/design.md`'s Asset Strategy in a future TASK (§15), not invented here.

---

## 7. Prototype architecture

### Q9

Evaluated: standalone HTML/CSS/JS, React/Vite, isolated mini-app, iframe, sandboxed iframe, separate process, static artifact, dynamically generated application.

**Recommendation: keep the existing architecture — a single self-contained HTML file with inline CSS/JS, no build step, no framework (`skills/design/SKILL.md`'s current, explicit rule) — and do not change the artifact format even for `CINEMATIC`-tier work.** Rendering/review isolation is a separate concern, addressed in §11, not a reason to change the artifact itself.

Why this beats the alternatives for this system specifically:

| Option | Isolation | Iteration speed | Fidelity ceiling | 3D/animation support | Persistence | In-toolkit preview |
|---|---|---|---|---|---|---|
| **Standalone HTML/CSS/JS (current)** | Good once rendered in a sandboxed iframe (§11) | Fastest — one file, edit-in-place, no build | High — CSS/SVG/Canvas cover most of §6; WebGL via CDN-free inline `<script>` (e.g. an inlined minimal Three.js build, or a `<canvas>` shader) still fits one file | Full — a `<canvas>`/WebGL context works fine in a static file; GSAP/Motion/Three.js can be inlined or loaded from a pinned CDN URL in the prototype's `<script>` tag | Trivial — it's already a git-committed file (`design/prototypes/*.html`) | Trivial — open the file, or screenshot via Playwright/Chrome DevTools (already wired per `rules/core/capabilities.md`'s registry) |
| React/Vite mini-app | Needs a dev server + process isolation | Slower — build step, dependency install, dev server lifecycle | Highest achievable fidelity, but the prompt's own constraint rules this out for a *prototype*: `/design`'s explicit rule is "do not write production code... the prototype is throwaway," and `/plan` treats the prototype as UI *context*, not a codebase to promote — a React prototype blurs that line and invites "just keep this" pressure that undermines the disposable/throwaway design the rest of the pipeline depends on | Full | Needs its own deploy/hosting story that doesn't exist in this toolkit | Requires running a dev server the reviewer must have set up |
| Separate process / isolated mini-app | Best OS-level isolation | Slowest to set up per task | Full | Full | Needs a runtime, not just a file | Requires the toolkit to manage process lifecycle — a new capability class entirely, disproportionate to what a disposable prototype needs |
| Iframe (unsandboxed) embedding the same HTML | No isolation gain over opening the file directly | Same as current | Same as current | Same as current | Same as current | Marginal — only useful if AI Studio grows an in-app review surface (§15) |
| **Sandboxed iframe (rendering layer, not artifact format)** | Strong — see §11 | Same as current (this is how the file is *viewed*, not how it's built) | Same as current | Same as current | Same as current | This is the recommended review surface once/if AI Studio grows a review UI |

The static single-file architecture already satisfies nearly every column, because it was chosen (per the prior-art docs) specifically to be disposable and dependency-free, and the current skill file's constraints ("never a build step, never a framework") remain correct for a *prototype* even as design intensity scales to `CINEMATIC`. The scaling axis for high intensity is **what's inlined into that one file** (a shader, an inlined R3F-equivalent vanilla Three.js scene, a GSAP ScrollTrigger timeline loaded from a pinned CDN URL), not a different artifact architecture. This is consistent with `rules/core/capabilities.md`'s minimum-capability principle applied to the prototype's own tech stack: use the smallest mechanism (static HTML) that produces sufficient fidelity, escalate only what's inside it.

One addition worth persisting for `CINEMATIC`-tier prototypes specifically: when a prototype legitimately needs an external script (a pinned Three.js/GSAP CDN URL, since a fully inlined WebGL library is impractical past a certain size), record that dependency as a Design note (`skills/design/SKILL.md`'s existing "Design notes" output section already covers "the UI decisions that matter for the eventual implementation" — a CDN dependency used only for the prototype, and what its production equivalent should be, belongs there) so `/plan` doesn't silently inherit an ad-hoc CDN dependency into the real implementation without a deliberate decision.

---

## 8. Human review model

### Q10 — interaction model, and Q12 — automated quality evaluation

**Interaction model**: this already exists as the Creative Approval Human Gate (`rules/core/execution-state.md`) and `/design`'s `DRAFT`/`APPROVED` status field accepting `APPROVE`/`REVISE: <what>`/`REJECT: <what>` — the Design Engine's job is to make the *content* of that gate scale with intensity (§3's routing table) and make feedback persistence explicit, not to invent a new interaction model.

What should be persisted per iteration, and where — mapped onto the existing Task Context schema, no new sections invented:

| Feedback element | Where it lives today | Gap to close |
|---|---|---|
| Explicit feedback that changes direction (e.g. "more premium, less SaaS") | `/design`'s existing rule: "Record feedback that changes the direction... as a Decision or Art Direction constraint" → `## Decisions` (`DEC-NNN`) | None — already specified |
| The approval/revision/rejection event itself | `Execution History`, via `/execute`'s `HUMAN_GATE`/`HUMAN_DECISION` events when orchestrated, or implicit in the conversation when `/design` is invoked manually | Minor gap: manually-invoked `/design` (not via `/execute`) never logs a `HUMAN_DECISION` event today per the existing event-ownership table ("only while orchestrating"). Worth a small future addition: `/design` itself appends a lightweight note to Execution History on `APPROVED` even outside `/execute` orchestration, so a resumed session can see the approval happened without replaying the conversation — flagged as a candidate TASK in §15, not something to invent here. |
| Screenshots per iteration | Not currently persisted — `/design` screenshots opportunistically as a self-check/to show the user, but the screenshot itself isn't saved anywhere | **Recommend**: when a browser-automation MCP is available, save each iteration's screenshot alongside the prototype at `design/prototypes/YYYY-MM-DD-<topic>-vN.png` (see §9 for why versioning is a snapshot concept, not a new artifact-per-iteration model) — cheap, useful for `/design-review` to visually diff the eventual implementation against, and useful for a human resuming the task cold |
| Video/interaction recordings | Not applicable to a static prototype without added tooling | Explicitly **defer** (§14) — only relevant once motion/interaction complexity is high enough that a static screenshot can't represent the experience; not worth the capability cost until `CINEMATIC`-tier tasks are common |

**Visual diffs**: recommend supporting them opportunistically, not as new infrastructure — `/design-review` already screenshots the real implementation at multiple viewports; if a prior prototype screenshot exists (from the addition above), a simple side-by-side is a natural extension of `/design-review`'s existing "compare against the task's Design Brief/Art Direction... and the approved prototype if one exists" rule, not a new capability. A dedicated pixel-diffing tool (Percy/Chromatic-style automated visual regression) is a Q15/deferred concern (§14) — those tools are built for component-level regression across many commits in a CI pipeline, a different problem than a one-shot human approval of a single evolving prototype.

**Should every iteration create a new artifact/version?** No — see §9; this directly answers part of Q10 by pointing at Q11's model.

### Q12 — prototype quality evaluation, automated vs. human

The prompt is explicit that an automated score must never replace human design approval — consistent with `rules/core/execution-state.md`'s Creative Approval gate being one of exactly four Human Gates that can never be skipped regardless of execution mode (§12). Automated checks should **narrow what the human has to evaluate manually**, not stand in for the decision:

| Check | Automatable today | Mechanism | Still requires human judgment for |
|---|---|---|---|
| Accessibility basics (contrast, focus states, semantic structure) | Yes, partially | `axe-core`-style automated scanning via a browser-automation MCP if configured; `design-review`'s existing "spot-check... missing focus states" is the manual fallback when no MCP is available | Whether the a11y gaps matter for *this* product's actual users, not just WCAG letter-compliance — `/design`'s own rule already scopes full a11y compliance to the real implementation, not the throwaway prototype |
| Responsive breakage | Yes | `/design-review`'s existing multi-viewport screenshot capture (desktop + mobile minimum) | Whether a breakpoint's *visual quality*, not just absence of overflow/breakage, holds up |
| Performance (load weight, animation frame rate) | Partially | A browser-automation MCP can report basic timing/frame metrics if configured; no capability in the current registry does this today (a gap, not a blocker — `rules/core/capabilities.md`'s principle is "use the best available alternative," and reasoning from asset sizes/technique choice is an adequate manual fallback) | Whether the actual felt experience is "fast enough" — frame-counter numbers don't capture perceived smoothness |
| Design-system/token adherence | Yes, once a project has persisted tokens | Diff the prototype's inline styles against `design/DESIGN-SYSTEM.md` or the project's existing token source, when either exists | Whether deviating from tokens was a deliberate, justified choice (a hero section legitimately breaking the grid) vs. drift |
| Generic-AI-aesthetic drift ("Anti-Slop") | No — this is a judgment call by construction | `rules/frontend/design.md`'s Anti-Slop Review is already framed as a checklist a reasoning agent runs, not a pattern-matcher; it depends on *why* a technique was used, which isn't mechanically detectable | The entire assessment — this stays exactly where it is today: an LLM-reasoned gate inside `/design`/`/creative-explore`/`/design-review`, never a lint rule |
| Visual hierarchy, storytelling coherence, interaction quality, content clarity | No | N/A | Entirely human/LLM-judgment; no proposed automation |

**Recommendation**: automated checks feed `/design-review`'s existing Findings output as additional evidence (grouped under its existing Critical/Notable/Polish severity buckets — no new output section needed), and — critically — never change `/design`'s `DRAFT`→`APPROVED` transition, which stays gated on explicit human language exactly as it is today. This keeps the "automated score can narrow attention, never replace approval" boundary structural rather than a documentation promise.

---

## 9. Versioning/iteration model

### Q11

Evaluated: immutable versions, mutable artifact, git commits, filesystem snapshots, Task Context history, artifact metadata.

**Recommendation: mutable artifact + git commit history + Task Context Decisions — exactly the model `/design` already implements, made explicit as the deliberate answer rather than an implicit default.**

This is the one question where the existing skill file's behavior is already the right architectural answer, and the job here is justifying *why*, against the Task Context system's own stated principles:

- `rules/core/task-context.md`: "Overwritten in place per section, not appended — except `Execution History`." The Task Context file itself is explicitly *not* an append-only/immutable log for most sections; it's a current-state document with a separate append-only history section for what needs a trail. Prototype iteration should follow the same split: **the prototype file is current-state (mutable, overwritten in place per `/design`'s existing "reuse the same file across iterations — never create a new versioned file per round of feedback")**, and **the trail lives in git history (since `design/prototypes/*.html` is committed to the project's own repo, per the prior-art docs' explicit "committed to the project's own repo... worth keeping in history") plus Task Context Decisions (`DEC-NNN` for direction-changing feedback)**.
- This means "v1 → feedback → v2 → feedback → v3 → APPROVED" is represented as: one file, N commits, and however many `DEC-NNN` entries correspond to feedback that actually changed direction (not every round — `/design`'s existing rule already distinguishes direction-changing feedback, which gets recorded, from a silent per-iteration adjustment, which doesn't). A reviewer wanting "show me v2" runs `git log -p -- design/prototypes/<file>.html`, which AI Studio doesn't need to build any tooling for — it's already there because the file is git-tracked.
- **Why not immutable versioned files** (`-v1.html`, `-v2.html`, ...): `/design`'s existing rule explicitly forbids this ("never create a new versioned file per round of feedback"), and for good reason — it would fragment "the current state of this task's design" across N files with no single source of truth, breaking the same "one file, one place to look" property the Task Context system is built around. It also multiplies what `/design-review` and `/plan` have to disambiguate ("which version is approved?") when git history + a single `APPROVED` status field already answers that unambiguously.
- **Why not filesystem snapshots or artifact metadata as a separate mechanism**: both would duplicate what git commits already give for free on a file that's already committed. This is the same "don't duplicate state that already exists" principle `rules/core/task-context.md` invokes for why there's no separate implementation-status field alongside slice status.
- **The one true gap**: screenshots per iteration (§8) aren't currently captured at all, so there's no way to *see* what v2 looked like without checking out that git revision and re-rendering it. Saving a screenshot alongside each meaningfully-different iteration (tied to the commit, informally by filename/date) closes this cheaply without inventing a versioning scheme — it's a convenience artifact, not a new source of truth, exactly the same relationship an optional `INDEX.md` has to the task files it summarizes (`rules/core/task-context.md`'s Obsidian conventions).

This model is fully compatible with the existing Task Context architecture and requires **no schema change** to `rules/core/task-context.md` — `## Design Context` and `## Decisions` already exist and already do this job.

---

## 10. Technology recommendations

### Q6 — when each technique is justified, and who decides

The prompt asks explicitly not to just list technologies. The organizing principle already exists in `rules/frontend/design.md`'s Quality budget section ("ask what its communication value actually is; if the complexity exceeds that value, remove it") and the 3D-specific gate ("before adding 3D, answer explicitly why it needs to be 3D — if the honest answer is 'it looks cool,' use CSS/SVG/Canvas instead"). The Design Engine's job is to generalize that one gate, already stated for 3D specifically, into a uniform per-technique gate, and attach each technique to a `design_budget` floor (§5) below which `/design` may not reach for it autonomously.

| Technique | Justified when | Complexity/cost it introduces | Autonomous default | Human gate | `design_budget` floor |
|---|---|---|---|---|---|
| Typography system, responsive composition | Always | Low | Always used, chosen by `/design`'s Art Direction step | None | `LOW` |
| CSS transitions/entrance motion | Motion communicates hierarchy/feedback (existing rule) | Low | Default-available | None | `LOW` |
| Micro-interactions (hover/focus/press states) | Improves perceived quality/feedback | Low | Default-available | None | `LOW` |
| SVG animation, procedural graphics | A visual metaphor benefits from a crafted, non-photographic asset | Low-Medium | Available at `STANDARD`+ | None | `LOW` |
| Scroll-driven animation, parallax (GSAP ScrollTrigger-class) | Multi-section narrative page where scroll position *is* the interaction model (per `/design`'s existing "define each major scroll transition explicitly" rule for major landing pages) | Medium — needs explicit reduced-motion fallback per existing rule | Available at `RICH`+, expected at `SUPER_RICH`+ for landing/marketing surfaces | None if within budget; flag in Design notes | `MEDIUM` |
| Page transitions | Multi-page/multi-view product where continuity across navigation matters | Medium | Available at `RICH`+ | None | `MEDIUM` |
| Canvas 2D | A visual idea needs pixel-level or particle-level control CSS/SVG can't give | Medium | Available at `RICH`+ with the same "why does it need to be canvas" justification as 3D | None | `MEDIUM` |
| Video, Lottie | The product itself is motion-native (a demo, a product walkthrough) — never as decoration | Medium (asset weight, licensing if not generated) | Available at `RICH`+, only with a stated purpose (Asset Strategy's existing "every major image needs a stated purpose" extends naturally to video/Lottie) | Recommend, don't force — `/design` proposes, human confirms if budget allows | `MEDIUM` |
| Generated imagery / image search | Asset Strategy's existing preference order already covers this — generation preferred over sourcing | Low if generation is configured; sourcing adds licensing review (§6/Q8) | Available whenever the capability exists, per existing capability rules | None for generation; licensing decision recorded as `DEC-NNN` if sourced | `LOW` |
| 3D geometry / Three.js / R3F | One strong, purposeful visual idea a 2D treatment genuinely can't express (existing rule, verbatim) | High — asset pipeline, performance budget, mobile fallback all become required, not optional | **Never autonomous below `HIGH` budget** — `/design` may *recommend* it (as in §5) but the budget gate decides whether it's available | Yes — always surfaces in the Creative Approval packet with its stated mobile/low-power fallback (existing rule already requires this) | `HIGH` |
| Shader effects, WebGL beyond basic R3F usage | Extremely narrow: the visual concept *is* the shader (a specific material behavior, a specific spatial distortion) | Very high — GPU performance budget, cross-device testing burden | Never autonomous | Yes, plus an explicit performance budget line (frame rate target, device floor) the human is co-approving | `EXTREME` |
| Physics simulation | Rare — only when a product metaphor is literally physical (a "throw," a "drop") | Very high | Never autonomous | Yes | `EXTREME` |

Sourcing note per technology (kept brief per the prompt's instruction not to survey generic web-dev content): GSAP/ScrollTrigger is the right default for scroll-choreography since Framer Motion's/Motion's strength is React-component-level declarative animation rather than scroll pinning/scrubbing, which the prototype (plain HTML, no React) wouldn't benefit from anyway; Three.js/R3F only matters once the *real implementation* is React, so a prototype needing 3D should use vanilla Three.js inline (matching §7's "no framework in the prototype" constraint) even if the eventual product implementation is R3F.

The decision of *who chooses*: for everything below the `HIGH` budget floor, `/design`'s existing autonomous posture applies unchanged ("decide the visual direction yourself by default... ask only when a decision genuinely needs business/brand input"). At `HIGH`/`EXTREME`, the technique itself becomes part of what the Creative Approval Human Gate is approving — not a separate, additional gate (§12), just richer content inside the existing one.

---

## 11. Security/isolation considerations

### Q9 (isolation half) and general

**The prototype file itself is not untrusted input in the traditional sense** — it's generated by Claude, inside the same trust boundary as any other code Claude writes in this repo, and `rules/core/security.md`'s "treat external input as untrusted" is about data crossing into the system, not about output the agent itself produced. The security question that actually matters here is narrower: **how should a human safely *view* a prototype that may contain arbitrary inline `<script>`, potentially loading a pinned third-party CDN script (§7, for `CINEMATIC`-tier work)?**

- Opening the file directly in a browser (today's default, per `skills/design/SKILL.md`'s "tell the user the exact path to open manually") already runs with the full privilege of a local file — no different from opening any other HTML file a developer wrote themselves. This is acceptable for the common case and requires no new machinery.
- **If AI Studio ever grows an in-toolkit review surface** that renders the prototype inline (e.g., an artifact-style preview, referenced as a possible future direction in §15) rather than telling the user to open the file themselves, that surface should render it inside a **sandboxed iframe using `sandbox` without `allow-same-origin`**, so that even if the generated script is buggy or (for a CDN-script case) the pinned third-party resource is later compromised, it cannot reach the parent page's DOM, cookies, or storage. Per current sandboxing guidance: `srcdoc` content is same-origin with the parent unless the frame is sandboxed *without* `allow-same-origin` — so `allow-same-origin` must never be combined with `allow-scripts` for this use case, since together they defeat the isolation `sandbox` exists to provide. ([Iframe Security Best Practices](https://www.invicti.com/blog/web-security/iframe-security-best-practices), [MDN: HTMLIFrameElement.srcdoc](https://developer.mozilla.org/en-US/docs/Web/API/HTMLIFrameElement/srcdoc), [Iframe XSS: postMessage, CSP, Sandboxing, & Clickjacking](https://7asecurity.com/blog/2026/06/iframe-xss-security/))
- A CSP on that review surface should restrict `frame-src`/`script-src` for the embedding page, and any pinned CDN dependency a `CINEMATIC`-tier prototype loads (§7) should be an explicit, reviewable URL (subresource-integrity pinned where practical) rather than an unpinned latest-version import — this is a natural extension of `rules/core/security.md`'s "least privilege" principle applied to the one place this Design Engine introduces a genuinely new external-content surface.
- This is entirely a **future** concern gated on AI Studio building an in-toolkit preview surface at all — it does not apply to the current "open the file yourself" flow, and should not be built preemptively (§14).

**Copyright/licensing** (the other half of Q8/Q9's security-adjacent territory) is already addressed structurally in §6/Q8's Asset Strategy ordering; the one gap closed there is recording the license/attribution of any sourced (non-generated) asset as a `DEC-NNN`.

**No changes needed to `rules/core/security.md` or `rules/core/capabilities.md`'s permission model** — the existing "read by default, write/mutate only with explicit authorization," "MCP is a hint, never a requirement," and "never invent access to an MCP that isn't configured" principles already cover every capability a Design Engine would reach for (image generation, browser automation for screenshots, a future accessibility-scanning capability).

---

## 12. Autonomous vs supervised behavior

### Q14

`execution_mode` (`rules/core/task-context.md`, `rules/core/execution-state.md`'s Execution mode section) is explicit that it "changes pacing only, never which decisions are available, which Human Gates apply, or what `COMPLETE` requires." This is the load-bearing constraint for this section: **the Design Engine must not weaken any Human Gate based on execution mode, ever** — only the *frequency of pausing between phases* changes.

What differs between AUTONOMOUS and SUPERVISED for design work, concretely:

| Behavior | AUTONOMOUS | SUPERVISED |
|---|---|---|
| Running `/clarify`'s design-profile draft, `/design`'s Design Brief/Art Direction, `/creative-explore`'s concept generation | All run back-to-back within one Supervisor Decision cycle each, no pause between them unless a gate trips | Same phases, but `/execute` stops after *each one* completes and its output is persisted, per the existing SUPERVISED rule ("after every `EXECUTE` completes... stop the current invocation instead of immediately deciding again") — so a human sees the Design Brief before Art Direction runs, sees Art Direction before the prototype is built, etc., if they choose to re-invoke incrementally |
| Creative Approval gate | Always stops — this is a Human Gate, unaffected by mode | Always stops — identical; SUPERVISED adds *more* pause points around it, never fewer |
| Escalating `design_budget`/technique choice at `HIGH`/`EXTREME` (§10) | Presented as part of the Creative Approval packet, same content | Same content; no difference — this was never mode-gated to begin with, it's already inside the one Human Gate that both modes respect identically |
| Re-running `/design` after `REVISE` feedback | Proceeds automatically to the next Supervisor Decision (still `/design`, still DRAFT) | Stops after the revision is persisted, waits for the next `/execute` invocation even though the "obvious next step" is more `/design` iteration — this is SUPERVISED's defining behavior ("no code path in which `SUPERVISED` skips a pause because a step 'looked safe'") applied to design iteration exactly as it applies to implementation |

**Which design decisions should ALWAYS require a human gate regardless of mode**, beyond the existing Creative Approval gate itself:

1. **Any technique at the `HIGH`/`EXTREME` budget floor (3D, shaders, physics)** — already folded into Creative Approval's content per §10, never a separate gate, but never skippable either, in either mode.
2. **`design_budget` escalation beyond what's persisted** — `/design` may recommend, never apply, exactly like `creative_autonomy` is never self-escalated by the agent that benefits from a looser one.
3. **Using a sourced (non-generated) asset with licensing implications** — this is closer to the existing High-risk action gate's spirit ("hard to reverse... a major architectural rewrite" is the closest existing category) than to Creative Approval, since shipping an improperly licensed asset is a business/legal risk, not a taste question. Recommend it route through the existing High-risk action gate rather than inventing a fifth gate type — consistent with `rules/core/execution-state.md`'s explicit instruction to "never invent additional" Human Gates.

No new Human Gate type is proposed anywhere in this report — every design-specific stop point maps onto one of the four that already exist (Creative Approval for direction/technique, High-risk action for licensing exposure, Requirements for an `UNKNOWN` design-relevant criterion, Final review for the completion check already including `/design-review`'s assessment).

---

## 13. What should be implemented now

Ranked by leverage-to-cost, all consistent with (not duplicating) the current `skills/design/SKILL.md`/`skills/creative-explore/SKILL.md`/`skills/design-review/SKILL.md`/`rules/frontend/design.md`:

1. **Persist the intensity/budget fields in `rules/core/task-context.md`'s frontmatter** (§4, §5) — `design_required`, `visual_complexity`, `motion_complexity`, `three_d_required`, `asset_generation_required`, `human_design_review_required`, `design_budget`. This is the single highest-leverage change: every other recommendation in this report (routing, gating, technique availability) reads these fields rather than re-deriving intensity ad hoc each time.
2. **Add the design-profile draft step to `/clarify`** (§3) — one small addition to its existing output, using the same `CONFIRMED`/`INFERRED`/`UNKNOWN` machinery it already has for everything else.
3. **Have `/design` read and, if needed, revise the persisted profile** on entry, persisting any revision as a `DEC-NNN` (§3) — small addition to an existing rule, not a new stage.
4. **Extend `skills/classify/SKILL.md`'s routing guidance** to the fuller table in §3/§13, so `/classify`'s recommended chain reflects `CINEMATIC`-tier work needing `/creative-explore` with more concepts, not just a binary "include creative-explore or don't."
5. **Add the per-technique budget gate to `rules/frontend/design.md`** (§10) — generalizing the existing 3D-specific "why does it need to be 3D" gate into the uniform table, and wiring it to the new `design_budget` field.
6. **Screenshot persistence per meaningful iteration** (§8, §9) — cheap, reuses the existing Playwright/Chrome DevTools capability already registered for `/design`, closes the one real gap in an otherwise-complete versioning story.
7. **One-line Asset Strategy addition** for competitor/reference screenshots (§6/Q8) — never used as literal template or asset, only as positioning research input.

## 14. What should explicitly be deferred

1. **A dedicated Design Classifier skill** (§3, option C) — `/clarify` + `/design`'s existing confirm/escalate loop covers this; revisit only if real usage shows the two-point check is unreliable in practice, not speculatively.
2. **Decomposing `/design` into Research/Assets/Motion/Prototype/Critique agents** (§6, Q7) — no demonstrated need yet; the sequential single-skill model with `/creative-explore` as the one parallel-exploration seam is the smallest architecture that scales, per the explicit instruction not to assume more agents = better.
3. **A React/Vite or isolated-process prototype architecture** (§7) — the static single-file model already satisfies the fidelity/isolation/persistence requirements; revisit only if a technique genuinely can't be expressed in inline HTML/CSS/JS, which nothing in §10's technology table currently requires.
4. **An in-toolkit sandboxed-iframe review surface** (§11) — today's "open the file / screenshot it" flow is sufficient; build the sandboxing described in §11 only when/if AI Studio grows an actual in-app preview surface, not preemptively.
5. **Automated visual-regression tooling (Percy/Chromatic-style pixel diffing)** (§8, Q12) — those tools solve component-level regression across many CI runs, a different problem than one-shot human approval of an evolving single prototype; `/design-review`'s existing screenshot-and-compare approach is adequate until AI Studio has a component library worth regression-testing.
6. **Video/interaction recording capture** (§8, Q10) — defer until `CINEMATIC`-tier tasks are common enough that a static screenshot genuinely fails to represent the experience.
7. **A dedicated performance-measurement capability** (frame-rate/timing MCP) (§10, §12) — not in the current capability registry (`rules/core/capabilities.md`); add only when a real `HIGH`/`EXTREME`-budget task needs it, per the toolkit's own "extend this list only when a skill demonstrably needs a new capability, not speculatively" rule.
8. **Multimodal design critique beyond what `/design-review` already does, brand-system/reusable-component abstractions, design-system versioning** — all named in Q15's future-proofing list; none has a concrete recurring need yet, matching `README.md`'s own "Deliberately excluded... revisit only if real usage demonstrates a gap" posture for the toolkit as a whole.

**Abstractions worth establishing now specifically because they're cheap and prevent a later rewrite**: the five-dimension intensity profile (§4) and the separate `design_budget` field (§5) are exactly this kind of abstraction — persisting them now, even before every consumer (a performance capability, a visual-regression integration) exists, means those future additions are new *readers* of an existing field rather than a schema migration. Everything else deferred above genuinely can wait without creating a migration problem later, because it either adds a new optional field/skill (cheap to add later) or a new capability (already designed to be added opportunistically per `rules/core/capabilities.md`'s registry pattern).

---

## 15. Proposed future TASK breakdown

Names and one-line scope only — no TASKs created, per this report's constraints.

1. **Design intensity & budget schema** — add `design_required`/`visual_complexity`/`motion_complexity`/`three_d_required`/`asset_generation_required`/`human_design_review_required`/`design_budget` to `rules/core/task-context.md`'s frontmatter schema and ownership matrix.
2. **`/clarify` design-profile draft** — extend `skills/clarify/SKILL.md` to draft the intensity profile alongside Acceptance Criteria, same CONFIRMED/INFERRED/UNKNOWN treatment.
3. **`/design` profile confirm/escalate** — extend `skills/design/SKILL.md` to read the draft profile on entry and persist any revision as a Decision.
4. **`/classify` intensity-aware routing** — extend `skills/classify/SKILL.md`'s guidance to route on the full profile (§3's table), not just a binary UI-facing check.
5. **Per-technique budget gate in `rules/frontend/design.md`** — generalize the existing 3D-only justification gate into the full technique/budget table from §10.
6. **Prototype screenshot persistence** — extend `skills/design/SKILL.md` to save a screenshot alongside each meaningfully-different prototype iteration when a browser-automation MCP is available.
7. **Asset Strategy: reference/competitor screenshot handling** — one-line addition to `rules/frontend/design.md`'s Asset Strategy distinguishing positioning research from asset sourcing.
8. **`/design-review` visual-diff-against-prior-screenshot** — extend `skills/design-review/SKILL.md` to compare against a saved prior iteration screenshot when one exists, in addition to its current Design Brief/Art Direction comparison.
9. **(Deferred, not scheduled) Sandboxed prototype preview surface** — only if/when AI Studio grows an in-toolkit rendering surface beyond "open the file"; scope would include the `sandbox`/CSP model from §11.
10. **(Deferred, not scheduled) Performance-measurement capability registration** — only once a real `HIGH`/`EXTREME`-budget task demonstrates the need, per `rules/core/capabilities.md`'s extension rule.

---

## Divergences from prior art — summary for the dispatcher

- **`docs/plans/2026-08-23-design-skill.md` / `-design.md`** describe an earlier, simpler `/design` (prototype-only, no Design Brief/Art Direction/Asset Strategy/Anti-Slop/creative_autonomy). The **current** `skills/design/SKILL.md` has already superseded that plan substantially. This report builds on the current skill files, not the older plan docs — flagged in case the dispatcher expected the plan docs to be the current state of the system.
- **`docs/plans/2026-08-23-task-context-design.md` / `-task-context.md`** describe the Task Context schema *before* `creative_autonomy` and `execution_mode` existed; the current `rules/core/task-context.md` already has both. No conflict — this report's proposed frontmatter additions (§4, §5) are additive to the current schema, following the exact same "optional, human-set, default stated" pattern those two fields already established.
- **No divergence found** between this report's recommendations and any explicit decision already made in the current skill files or `rules/frontend/design.md` — every recommendation either persists a field for a judgment those files already make implicitly (intensity, budget), generalizes a rule they already state narrowly (the 3D-only justification gate → all high-cost techniques), or explicitly defers rather than contradicts (no decomposed agent architecture, no new artifact format, no new Human Gate type).
- **One explicit new decision this report makes that prior art doesn't address at all**: adding `CINEMATIC` as a fifth intensity level above `SUPER_RICH` (§4). Flagged as a naming/scoping call, not implied by any existing file, and easy to revisit.
