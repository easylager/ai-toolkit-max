---
name: design-review
description: Render the implemented UI in a browser, screenshot it, and critique it against the approved Design Brief/Art Direction — hierarchy, spacing, typography, responsive behavior, motion, accessibility basics, generic-AI-aesthetic drift — with concrete, actionable findings. The visual counterpart to /review; use after implementing an approved /design prototype, before /verify.
---

# Design Review

Judge the actual rendered UI against the approved design intent, not against whether the code compiles. This is not a repeat of `/review` (code quality) or `/verify` (acceptance criteria) — it's a critique of what a user would actually see and feel, backed by a real render.

## Rules

- Render the real implementation, not the prototype: start the app (or use an already-running dev server) and open the actual page. Use a browser-automation MCP (Playwright, Chrome DevTools) if available; if none is configured, ask the user to share screenshots or run the app themselves and describe what they see — never fabricate a visual assessment from source code alone.
- Screenshot at minimum a desktop and a mobile viewport; add tablet or specific breakpoints only if the Design Brief calls them out. Capture interactive/hover/focus states that the Design Brief or Art Direction singled out as meaningful, not every possible state exhaustively.
- Compare against the task's Design Brief/Art Direction (from `/design`, inline in the conversation or persisted at `design/DESIGN-SYSTEM.md`) and the approved prototype if one exists. Flag drift from either as a finding, not silently.
- Give concrete findings, not vague impressions: name the element, the problem, and why it reads wrong — e.g. "the hero headline and product screenshot have near-identical visual weight, so the eye has no clear entry point" rather than "looks a bit flat."
- Explicitly check for generic-AI-SaaS aesthetics that weren't a deliberate Art Direction choice: unexplained purple gradients, glassmorphism, floating cards, glowing blobs, default-Tailwind-looking layouts, motion with no purpose (full list in `rules/frontend/design.md`). If found and not justified in the Art Direction, flag it — don't silently wave it through.
- Spot-check, don't formally verify, responsiveness/motion/accessibility/performance: obvious breakage at mobile width, motion that ignores `prefers-reduced-motion`, missing focus states, an unreasonably heavy initial render. Formal acceptance-criteria verification (`RESPONSIVE-`/`MOTION-`/`A11Y-`/`PERF-` criteria) belongs to `/verify`, not here — this skill surfaces what a human eye would catch, `/verify` proves it against a stated threshold.
- Do not modify files. Do not write implementation code — recommend fixes, let the implementer (or a follow-up turn) make them.
- After fixes are made, re-render and re-screenshot rather than trusting the diff alone.

## Output

### Findings
Per finding: what's wrong, where (element/viewport), why it matters, and — only if not obvious — how to fix. Group by severity if there are more than a few: Critical (breaks the experience or contradicts the Design Brief) / Notable (weakens it) / Polish (small, optional).

### Generic-AI-aesthetic check
One line: clean, or which specific pattern was found and whether it's justified by the Art Direction.

### Assessment
Matches approved design intent / needs fixes / needs another round of `/design` (if the gap is a direction problem, not an implementation one).
