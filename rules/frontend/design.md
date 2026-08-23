# Design & Frontend Creation

Principles for premium, distinctive frontend work. Applies alongside `rules/frontend/react.md` when this project has a React frontend, and stands alone for any other UI stack. `skills/design/SKILL.md`, `skills/creative-explore/SKILL.md`, and `skills/design-review/SKILL.md` are the process that applies these principles; this file is what they apply.

## Core principles

- Premium means intentional, coherent, restrained, distinctive, technically polished, fast, responsive, and accessible — not more gradients, more 3D, more animation, or more shadows. Prefer one great idea over twenty effects.
- Ground every visual decision in the product's actual positioning, not aesthetic preference — see `skills/design/SKILL.md`'s Design Brief step, which establishes this before any implementation.
- Design responsively from the start — desktop, tablet, and mobile compositions, not a desktop layout shrunk to fit. Motion and 3D may behave differently per breakpoint; state that explicitly rather than leaving mobile behavior implicit.
- Accessibility is part of the design, not a final pass: semantic HTML, visible focus states, sufficient contrast, keyboard operability, adequate touch targets, and `prefers-reduced-motion` support belong in the first implementation, not a follow-up fix.
- Motion should communicate hierarchy, continuity, or feedback — never add animation for its own sake, and never let it compensate for weak composition. Keep entrance/scroll/hover transitions fast enough that the interface doesn't feel sluggish, and never let motion block interaction.
- 3D/WebGL must be conceptual, not decorative: one strong, purposeful visual idea (a product metaphor, an object transforming through scroll, a spatial representation of a workflow) beats many decorative effects (floating spheres, glowing blobs, meaningless particles, generic abstract shapes). Before adding 3D, answer explicitly why it needs to be 3D — if the honest answer is "it looks cool," use CSS/SVG/Canvas instead. When used, state the mobile/low-power fallback and a performance budget (frame rate, asset size, texture size).
- Translate the visual direction into design tokens (color, spacing, radius, motion durations, typography scale) that the implementation consumes, instead of scattering arbitrary values through the codebase. Reuse the project's existing tokens/component library if one already exists rather than inventing a parallel one.
- Extract a component only when repetition or semantic meaning justifies it — resist creating `Button`/`Card`/`Box`/`Container` abstractions before the actual design calls for them.
- A frontend implementation isn't done because it compiles — it's done once the actual rendered UI has been inspected (`skills/design-review/SKILL.md`) at real breakpoints, not just read as source code.

## Quality budget

Spend effort where users actually look, in this order: hero, typography, primary visual metaphor, major transitions, product presentation, CTA, responsive experience, micro-interactions, decorative details. Polishing low-impact details while the hero or core narrative is weak is effort in the wrong place.

For every major visual technique (3D, shaders, particles, video, parallax, heavy animation), ask what its communication value actually is; if the complexity exceeds that value, remove it rather than justify it after the fact.

## Asset strategy

Determine what visual assets a direction needs and how to get each one, in this preference order: generate an original asset if an image-generation capability is configured (per `rules/core/capabilities.md` — never invent one that isn't); otherwise a suitable licensed/source asset if available tools permit; SVG/CSS/Canvas; procedural graphics; 3D geometry or GLTF/GLB; the product's own UI as the visual asset; or decide no asset is needed. Never add imagery just to fill space — every major image needs a stated purpose, and the design should be judged stronger without one before reaching for a weak one.

## Anti-slop review

Run this against every creative concept and every implemented UI before calling it done — a mandatory gate, not optional polish. If a design reads as generic AI-SaaS, rework the composition, typography, visual metaphor, storytelling, imagery, or spatial design — never "fix" genericness by adding more animation, gradients, 3D, glow, or shadows.

- Could this belong to 50 other SaaS companies?
- Generic gradients, excessive glassmorphism, meaningless floating cards, an arbitrary glowing sphere, too many cards?
- Is 3D or animation present without a real reason — compensating for weak composition rather than adding to it?
- Is the typography generic? Is the visual hierarchy actually strong?
- Is there one memorable visual idea, and does every major visual element have a purpose?
- Would the design still feel strong with all animation removed?
- Does the page tell a coherent story, and does the visual concept reinforce the product's actual positioning?

Avoid generic AI-SaaS defaults unless a Design Brief gives a specific reason to use one: purple gradients, glassmorphism, meaningless glowing blobs, floating cards, generic dashboard heroes, interchangeable card grids, default Inter-plus-gradient-plus-cards compositions, 3D or motion added because it's possible rather than because it communicates something.
