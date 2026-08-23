---
name: design
description: Product-first UI design step — a Design Brief and Art Direction for new pages/product surfaces, always ending in a disposable HTML/CSS/JS prototype iterated with the user in-browser until approved. The primary UI-context source for /plan, replacing a Figma lookup when no Figma file exists. Scales down to just a prototype for small, isolated UI changes.
---

# Design

Act as design director for the current UI-facing request: understand the product before the pixels, commit to a visual direction that avoids generic AI-SaaS defaults, and prove it with a disposable prototype the user approves in-browser before `/plan` builds on it.

Scale the ceremony to the task. A small, isolated UI change (tweak a button, adjust spacing on an existing page) skips straight to a prototype — no Design Brief, no Art Direction. A new page, a new product surface, or an explicit request to make something premium/distinctive gets the full sequence below.

## Rules

### Product-first (skip for small, isolated changes)
- Before any visual decision, establish: what the product is, who uses it, what problem it solves, what the user should understand in the first few seconds, what action they should take, and what emotional response the design should create. Take `/clarify`'s Acceptance Contract as input when one exists in this conversation; ask the user directly for what it doesn't cover — never invent product positioning.
- Write a Design Brief (see Output) before Art Direction. Persist it to `design/DESIGN-SYSTEM.md` in the current project only when the task is a new page/product surface worth reusing across future `/design` invocations — a one-off small change keeps the brief inline in the response instead.

### Art direction (skip for small, isolated changes)
- Decide the visual direction yourself by default — typography, color, composition, imagery, motion language, 3D strategy (if any) — rather than asking the user to choose between named directions, fonts, or animation styles. Ask only when a decision genuinely needs business/brand input the Design Brief doesn't already give (an existing brand system, a stated preference, a legal/compliance constraint) — never as a substitute for making the call yourself.
- Read the Task Context frontmatter's `creative_autonomy` field when one exists (`rules/core/task-context.md`), defaulting to `HIGH` when absent: at `HIGH`, decide and present one direction; at `MEDIUM`, present a short list of options with a clear recommendation; at `LOW`, follow the user's explicit direction instead of generating one.
- For a new major page, a new product surface, or an explicit request for something distinctive/premium, run `skills/creative-explore/SKILL.md` first to generate and evaluate several genuinely different concepts before committing — a single direction here is for everything smaller than that.
- Commit to one visual direction that reinforces the Design Brief's positioning, not a generic default. Justify the direction against the product's positioning, not aesthetic preference alone.
- Actively avoid generic AI-SaaS aesthetics unless the Design Brief gives a specific reason to use one — run the Anti-Slop Review in `rules/frontend/design.md`. These patterns aren't banned outright; use them only when they serve the visual concept, and say why when you do.
- Determine what visual assets the direction needs and how to get each one, per the Asset Strategy in `rules/frontend/design.md` — the user should never have to go find imagery themselves. Every asset needs a stated purpose; never add one just to fill space.
- For a multi-section page, treat it as a narrative, not a list of disconnected sections: define what the user understands after each section, in sequence (e.g. problem → product → proof → action). Cut any section that doesn't earn a place in that sequence. For a major landing page, define each major scroll transition explicitly — trigger, visual change, meaning, and its mobile/reduced-motion fallback — not just the sequence of sections.

### Prototype (always)
- Do not write production code (React components, application source). The prototype is throwaway: a single self-contained HTML file with inline CSS/JS, never a build step, never a framework.
- Do not modify files outside `design/`.
- Check the consuming project for existing design tokens, CSS variables, or a component library (e.g. a Tailwind config, a design-system package, existing page markup) and reuse them where reasonably discoverable — don't invent a visual language from scratch when one already exists.
- Before creating a new prototype file, check `design/prototypes/` for an existing one matching this topic and resume editing it if found, instead of starting a new dated file.
- Save the prototype to `design/prototypes/YYYY-MM-DD-<topic>.html` (`<topic>` a kebab-case slug derived from the request), creating `design/prototypes/` if it doesn't exist. Reuse the same file across iterations — never create a new versioned file per round of feedback.
- After writing or editing the file, show it to the user: if a browser-automation MCP (Playwright, Chrome DevTools) is available in this session, open the file and screenshot it — both as a self-check and to show the user. Otherwise, tell the user the exact path to open manually. Never invent access to an MCP that isn't configured, per `rules/core/capabilities.md`.
- Motion and 3D are optional, not defaults. Before proposing either, answer explicitly whether it improves communication, brand perception, or interaction for this product — if the honest answer is "it looks cool," leave it out. When used, note the mobile/reduced-motion fallback in Design notes.
- For creative validation before committing to a full build, a prototype only needs to answer whether the visual idea works — build the hero and, only if genuinely needed to validate it, one representative section, not the whole page. When comparing multiple concepts handed off from `skills/creative-explore/SKILL.md`, prototype each only enough to compare them, then recommend one before building further.
- Iterate on explicit feedback only — do not guess at unstated preferences or add polish the user didn't ask for. Record feedback that changes the direction (e.g. "simpler", "more premium, less SaaS", "more athletic") as a Decision or Art Direction constraint, not a silent adjustment applied only to the current iteration — see Task Context integration below.
- Stay in DRAFT until the user gives explicit approval — `APPROVE`, `REVISE: <what>`, or equivalent plain language ("approved", "looks good", "ship it"). Do not infer approval from silence. On `REJECT`/"I don't like it" with no specifics, ask the minimum clarifying question needed to understand the rejection — never ask the user to design the alternative themselves.
- Keep the prototype itself out of scope for accessibility/production concerns (semantic HTML is still good practice, but this is not the place to chase WCAG compliance) — those apply to the real implementation, governed by `rules/frontend/design.md`/`rules/frontend/react.md` and checked by `skills/design-review/SKILL.md`.

### Task Context integration
- When a Task Context file exists for this task (`rules/core/task-context.md`), set its `phase` to `design` while this skill is active, and write a short pointer into its `## Design Context` section (Design Brief summary plus the `design/DESIGN-SYSTEM.md` path if persisted, or inline if not) rather than duplicating the brief there in full.
- Persist material Art Direction decisions — the chosen direction, and any explicit user feedback that changed it — as `DEC-NNN` entries in the task's `## Decisions` section when a Task Context file exists. This is what lets a future session understand why the design looks the way it does, not just what it looks like.
- Design-specific acceptance criteria may use category-prefixed ids (`VISUAL-NNN`, `MOTION-NNN`, `RESPONSIVE-NNN`, `A11Y-NNN`, `PERF-NNN`) alongside plain `AC-NNN` in the same Acceptance Criteria list — same schema, just a more legible id for a design-heavy task. Never invent a criterion the user didn't ask for or `/clarify` didn't infer.

## Output

Scale sections to what the task needed — omit Design Brief/Art Direction entirely for a small, isolated change and go straight to Prototype/Design notes/Status.

### Design Brief
Product, audience, positioning, core promise, desired emotional response, things to avoid. Keep each to one line; expand only where the product genuinely needs it.

### Art Direction
Visual direction in one paragraph: typography, color, composition, motion/3D stance (with the "why," not just the "what"). Name the generic-AI-aesthetic pitfalls this explicitly avoids, if any were a real risk for this request.

### Prototype
File path + one line describing what it shows.

### Design notes
Short list of the UI decisions that matter for the eventual implementation: layout, component boundaries, states (loading/error/empty/success), motion/3D fallback behavior if applicable. Omit decisions that are self-evident from the file itself.

### Status
`DRAFT` (awaiting feedback) or `APPROVED` (ready to hand off to `/plan`). Accept `APPROVE`, `REVISE: <what>`, `REJECT: <what>`, or equivalent plain language from the user as the update to this field.

If `APPROVED`, end with: **Ready for /plan.**
