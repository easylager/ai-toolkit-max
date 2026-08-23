# Design & Frontend Creation

Principles for premium, distinctive frontend work. Applies alongside `rules/frontend/react.md` when this project has a React frontend, and stands alone for any other UI stack. `skills/design/SKILL.md` and `skills/design-review/SKILL.md` are the process that applies these principles; this file is what they apply.

- Premium means intentional, coherent, restrained, distinctive, responsive, fast, and accessible — not more gradients, more 3D, more animation, or more shadows. Prefer quality over complexity.
- Ground every visual decision in the product's actual positioning, not aesthetic preference — see `skills/design/SKILL.md`'s Design Brief step, which establishes this before any implementation.
- Avoid generic AI-SaaS defaults unless the product's Design Brief gives a specific reason to use one: purple gradients, glassmorphism, meaningless glowing blobs, floating cards, generic dashboard heroes, interchangeable card grids, default Inter-plus-gradient-plus-cards compositions, 3D or motion added because it's possible rather than because it communicates something.
- Design responsively from the start — desktop, tablet, and mobile compositions, not a desktop layout shrunk to fit. Motion and 3D may behave differently per breakpoint; state that explicitly rather than leaving mobile behavior implicit.
- Accessibility is part of the design, not a final pass: semantic HTML, visible focus states, sufficient contrast, keyboard operability, adequate touch targets, and `prefers-reduced-motion` support belong in the first implementation, not a follow-up fix.
- Motion should communicate hierarchy, continuity, or feedback — never add animation for its own sake. Keep entrance/scroll/hover transitions fast enough that the interface doesn't feel sluggish, and never let motion block interaction.
- 3D/WebGL is optional and expensive — reach for it only when it demonstrably improves communication or brand perception over CSS/SVG/Canvas, and only with a stated mobile/low-power fallback and a performance budget (frame rate, asset size, texture size).
- Translate the visual direction into design tokens (color, spacing, radius, motion durations, typography scale) that the implementation consumes, instead of scattering arbitrary values through the codebase. Reuse the project's existing tokens/component library if one already exists rather than inventing a parallel one.
- Extract a component only when repetition or semantic meaning justifies it — resist creating `Button`/`Card`/`Box`/`Container` abstractions before the actual design calls for them.
- Treat imagery as part of the product story, not filler: every major image should support a specific point, not just occupy space.
- A frontend implementation isn't done because it compiles — it's done once the actual rendered UI has been inspected (`skills/design-review/SKILL.md`) at real breakpoints, not just read as source code.
