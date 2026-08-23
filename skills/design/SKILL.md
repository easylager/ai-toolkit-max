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
- Commit to one visual direction — typography, color, composition, imagery, motion language, 3D strategy (if any) — that reinforces the Design Brief's positioning, not a generic default. Justify the direction against the product's positioning, not aesthetic preference alone.
- Actively avoid generic AI-SaaS aesthetics unless the Design Brief gives a specific reason to use one: purple gradients, glassmorphism, meaningless glowing blobs, floating cards, generic dashboard heroes, default Tailwind-looking layouts, Inter-plus-gradient-plus-cards compositions, 3D or motion with no communicative purpose. These aren't banned outright — use them only when they serve the visual concept, and say why when you do. See `rules/frontend/design.md` for the full list.
- For a multi-section page, treat it as a narrative, not a list of disconnected sections: define what the user understands after each section, in sequence (e.g. problem → product → proof → action). Cut any section that doesn't earn a place in that sequence.

### Prototype (always)
- Do not write production code (React components, application source). The prototype is throwaway: a single self-contained HTML file with inline CSS/JS, never a build step, never a framework.
- Do not modify files outside `design/`.
- Check the consuming project for existing design tokens, CSS variables, or a component library (e.g. a Tailwind config, a design-system package, existing page markup) and reuse them where reasonably discoverable — don't invent a visual language from scratch when one already exists.
- Before creating a new prototype file, check `design/prototypes/` for an existing one matching this topic and resume editing it if found, instead of starting a new dated file.
- Save the prototype to `design/prototypes/YYYY-MM-DD-<topic>.html` (`<topic>` a kebab-case slug derived from the request), creating `design/prototypes/` if it doesn't exist. Reuse the same file across iterations — never create a new versioned file per round of feedback.
- After writing or editing the file, show it to the user: if a browser-automation MCP (Playwright, Chrome DevTools) is available in this session, open the file and screenshot it — both as a self-check and to show the user. Otherwise, tell the user the exact path to open manually. Never invent access to an MCP that isn't configured, per `rules/core/capabilities.md`.
- Motion and 3D are optional, not defaults. Before proposing either, answer explicitly whether it improves communication, brand perception, or interaction for this product — if the honest answer is "it looks cool," leave it out. When used, note the mobile/reduced-motion fallback in Design notes.
- Iterate on explicit feedback only — do not guess at unstated preferences or add polish the user didn't ask for.
- Stay in DRAFT until the user gives explicit approval (e.g., "approved", "looks good", "ship it"). Do not infer approval from silence or from the absence of further feedback in the same turn.
- Keep the prototype itself out of scope for accessibility/production concerns (semantic HTML is still good practice, but this is not the place to chase WCAG compliance) — those apply to the real implementation, governed by `rules/frontend/design.md`/`rules/frontend/react.md` and checked by `skills/design-review/SKILL.md`.

### Task Context integration
- When a Task Context file exists for this task (`rules/core/task-context.md`), set its `phase` to `design` while this skill is active, and write a short pointer into its `## Design Context` section (Design Brief summary plus the `design/DESIGN-SYSTEM.md` path if persisted, or inline if not) rather than duplicating the brief there in full.
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
`DRAFT` (awaiting feedback) or `APPROVED` (ready to hand off to `/plan`).

If `APPROVED`, end with: **Ready for /plan.**
