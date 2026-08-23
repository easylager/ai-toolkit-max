# `/design` skill — design doc

Date: 2026-08-23

## Problem

The current UI/design flow relies on Figma as the design-context capability (`rules/core/capabilities.md`): `/plan` reads an existing Figma file, read-only, before planning UI changes. That only works when a Figma file already exists — it gives Claude no way to *propose* a UI and get it approved before committing to a React implementation.

## Solution

Add `/design`, a new THINK-layer skill, between `/clarify` and `/plan`:

```
classify → clarify → design → plan → estimate → next → verify → review
                        │
               (for UI-facing tasks, optional)
```

`classify` recommends `design` in the chain only when the task is visibly UI/frontend-facing (new screen, dashboard, form, layout change). Backend-only tasks never get it in the recommended chain, same way `impact`/`challenge` are conditional today.

### Mechanics

1. Takes `/clarify`'s Acceptance Contract as input when one exists in the conversation — what the screen must do, what data it shows.
2. Builds a **disposable** HTML/CSS/JS prototype at `design/prototypes/YYYY-MM-DD-<topic>.html` in the consuming project's repo root — static markup, no build step, inline CSS/JS in one file.
3. Shows the result: if Playwright MCP is available, opens the file and screenshots it (self-check, and to show the user); otherwise tells the user to open the file manually (`open design/prototypes/...html`). Per the toolkit-wide rule, MCP is a hint, never a requirement — never invents access to one that isn't configured.
4. Iterates in place on user feedback ("sidebar is too wide", "make it mobile") — edits the same file, no per-iteration file versioning.
5. Stops only on explicit approval from the user.

### Output format

Follows the toolkit's existing skill-output convention (`clarify`'s Acceptance Contract, `plan`'s Approach/Changes):

```
### Prototype
File path + one line describing what it shows.

### Design notes
Short list of the UI decisions that matter for the eventual React implementation:
layout, component boundaries, states (loading/error/empty/success).

### Status
DRAFT (awaiting feedback) | APPROVED (ready to hand off to /plan)
```

On `APPROVED`, the prototype becomes the primary UI source for `/plan`'s Data/API and Changes sections — `/plan` no longer has to infer UI shape from the task description alone.

### File locations

- Prototypes live in the *consuming project's* repo (not inside ai-toolkit-max itself), at `design/prototypes/YYYY-MM-DD-<topic>.html` — sibling to `docs/plans/` by convention.
- Committed to the project's own repo, same as `docs/plans/*-design.md`: an approved prototype is the framing artifact for the React implementation and is worth keeping in history, not gitignored as throwaway.

## Changes to existing files

- **`rules/core/capabilities.md`** — remove the Figma row as the recommended design-context path before UI work. Figma stays usable as an MCP if configured, but the registry no longer tells `/plan` to reach for it by default; that guidance now points at `/design`.
- **`skills/plan/SKILL.md`** — replace "check Figma before finalizing Changes" with: if an `APPROVED` `/design` prototype exists for this task, use it as the primary UI source; otherwise fall back to Figma if available, per `rules/core/capabilities.md`.
- **`skills/classify/SKILL.md`** — add `design` to the list of valid skill names classify is allowed to reference in a recommended chain.
- **`README.md`** — add a `design` row to the THINK skills table, and update the top-of-file chain diagram/prose to show `design` as the optional UI step between `clarify` and `plan`.
- **`rules/frontend/react.md`** — no changes needed; the prototype itself is disposable static HTML, not React, so it doesn't inform React conventions directly — it only informs what `/plan` asks for.

## Out of scope

- No changes to `.ai/` state contract — `/design` doesn't write there (only `/next`, `/verify`, `/plan`, `/estimate` do, per `rules/core/execution-state.md`).
- No new MCP is installed, configured, or bundled — Playwright usage is opportunistic, matching the toolkit's existing capability rule.
- No enforcement mechanism forcing `/design` to run for UI tasks — like every other skill in this toolkit, it's invoked when `classify` (or the user) judges it useful, never a mandatory gate.
