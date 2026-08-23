---
name: design
description: Build a disposable HTML/CSS/JS prototype for a UI-facing task and iterate on it with the user in-browser until approved — the primary UI-context source for /plan, replacing a Figma lookup when no Figma file exists.
---

# Design

Turn the current UI-facing request into a disposable, static HTML/CSS/JS prototype the user can look at in a browser, iterate on conversationally, and approve. This is the UI-context step in the workflow — `/plan` later reads the approved prototype as its primary source for Data/API and Changes, in place of a Figma lookup when no Figma file exists.

## Rules

- Do not write production code (React components, application source). The prototype is throwaway: a single self-contained HTML file with inline CSS/JS, never a build step, never a framework.
- Do not modify files outside `design/prototypes/`.
- Take `/clarify`'s Acceptance Contract as input when one exists in this conversation — what the screen must do, what data it shows, what states it has (loading/error/empty/success). Otherwise work directly from the request.
- Check the consuming project for existing design tokens, CSS variables, or a component library (e.g. a Tailwind config, a design-system package, existing page markup) and reuse them in the prototype where reasonably discoverable — don't invent a visual language from scratch when one already exists.
- Before creating a new file, check `design/prototypes/` for an existing prototype matching this topic and resume editing it if found, instead of starting a new dated file.
- Save the prototype to `design/prototypes/YYYY-MM-DD-<topic>.html` (`<topic>` a kebab-case slug derived from the request) in the current project (not inside ai-toolkit-max), creating the `design/prototypes/` directory if it doesn't exist yet. Reuse the same file across iterations — never create a new versioned file per round of feedback.
- After writing or editing the file, show it to the user: if a browser-automation MCP (Playwright, Chrome DevTools) is available in this session, open the file and screenshot it — both as a self-check and to show the user. Otherwise, tell the user the exact path to open manually. Never invent access to an MCP that isn't configured, per `rules/core/capabilities.md`.
- Iterate on explicit feedback only — do not guess at unstated preferences or add polish the user didn't ask for.
- Stay in DRAFT until the user gives explicit approval (e.g., "approved", "looks good", "ship it"). Do not infer approval from silence or from the absence of further feedback in the same turn.
- Keep the prototype itself out of scope for accessibility/production concerns (semantic HTML is still good practice, but this is not the place to chase WCAG compliance) — those apply to the real implementation, governed by `rules/frontend/react.md`.

## Output

### Prototype
File path + one line describing what it shows.

### Design notes
Short list of the UI decisions that matter for the eventual implementation: layout, component boundaries, states (loading/error/empty/success). Omit decisions that are self-evident from the file itself.

### Status
`DRAFT` (awaiting feedback) or `APPROVED` (ready to hand off to `/plan`).

If `APPROVED`, end with: **Ready for /plan.**
