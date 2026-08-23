---
name: creative-explore
description: Generate 3-5 genuinely different, original creative directions for a significant UI/product surface — each with its own visual metaphor and narrative, not superficial color variants — self-evaluate them, run them through the Anti-Slop Review, and recommend one. Feeds an approved concept into /design's Art Direction and prototype step. Use only for significant visual projects; skip it for small UI changes.
---

# Creative Explore

Explore multiple original creative directions before committing to one, so the user reviews a recommendation instead of designing from scratch. Use this only for significant visual work — a new major landing page, a new product surface, or an explicit request for something distinctive/premium. For everything else, `/design`'s single autonomous Art Direction step is enough; do not force this ceremony onto small tasks.

## Rules

- Ground every concept in product context first: positioning, audience, personality, business/conversion goals, existing content, existing project design system, available technologies, performance constraints, brand constraints. Take `/clarify`'s Acceptance Contract and any Design Brief already established by `/design` as input; ask the user directly only for what neither covers.
- Generate 3-5 concepts, each a genuinely different visual idea and narrative — not superficial variants of the same idea (a different accent color, a darker shade). A concept is a name plus a core visual metaphor that no other concept in the set could share.
- If web research is available, use it to identify *why* current high-quality digital experiences work — interaction patterns, motion, typography, composition, storytelling, scroll structure — then combine and transform what you learn into an original concept. Never instruct the implementation to "look like" a specific existing site, and never copy one directly; references are inspiration, not templates.
- Write each concept in the Concept format (see Output), including an honest Technical Complexity and Performance Risk rating — do not undersell complexity to make a concept look more attractive.
- Self-evaluate all concepts in a single comparison (see Output) — score the criteria that actually matter for this product, and use the scores to support the reasoning, never as the decision by themselves.
- Run every concept through the Anti-Slop Review (`rules/frontend/design.md`) before recommending one. A concept that reads as generic AI-SaaS gets reworked or dropped, not shipped with more decoration added on top.
- Write a Creative Self-Critique (see Output) for the recommended concept specifically — mandatory for significant landing pages/product experiences, honest about what could still make it look AI-generated.
- Read the Task Context frontmatter's `creative_autonomy` field when one exists (`rules/core/task-context.md`), defaulting to `HIGH` when absent: at `HIGH`, recommend one concept with reasoning; at `MEDIUM`, present the top 2-3 with a clear recommendation instead of one; at `LOW`, follow the user's explicit direction instead of generating original concepts.
- Recommend exactly one concept with reasoning, and give one line each for why every rejected concept was rejected — the user should be able to respond `APPROVE`, `REVISE: <what>`, or `REJECT: <what>` without having to design an alternative themselves.
- Do not implement production code. A cheap prototype of the recommended concept's hero — and, only if genuinely needed to validate the idea, one more representative section — belongs to `/design`'s Prototype step next, not here.
- When a Task Context file exists, persist the recommendation and the one-line rejection reasons as Decisions (`DEC-NNN`) in its `## Decisions` section, and record explicit user feedback on the recommendation there too (e.g. "more premium, less SaaS" becomes an Art Direction constraint, not a silent adjustment) — this is what lets a future session understand why the design looks the way it does.

## Output

Scale to what the product needs — 3 concepts for most projects, up to 5 only when the product genuinely supports that many distinct directions.

### Concepts
Per concept:
```
# Concept

## Name
## Core Visual Idea
## Product Connection
Why this visual metaphor communicates the product.
## Emotional Response
## Visual Language
## Typography
## Imagery
What's needed and how to get it — see `rules/frontend/design.md`'s Asset Strategy.
## Motion
## 3D
Only if genuinely purposeful — state the reason, or omit this field entirely.
## Scroll Narrative
Only for a multi-section page.
## Mobile Strategy
## Technical Complexity
Low | Medium | High
## Performance Risk
Low | Medium | High
## Differentiation
How different this is from a generic SaaS site.
## Strengths
## Risks
```

### Creative Evaluation
A comparison table across the concepts, scored on the criteria that actually matter for this product (typically product fit, differentiation, storytelling, motion/3D potential, mobile viability, performance, implementation complexity). Follow with one paragraph of reasoning — the table supports the decision, it doesn't make it.

### Anti-Slop Review
Per concept, one line: clean, or which specific generic pattern was found and whether it was reworked or the concept was dropped because of it.

### Creative Self-Critique
For the recommended concept only: what's strong, what feels generic, what could read as AI-generated, what should be removed, what should become the visual signature, what would make it meaningfully more premium.

### Recommendation
One recommended concept with reasoning. One line per rejected concept, why.

Ends with **Ready for /design's prototype step**, or — if Creative Autonomy is `MEDIUM`/`LOW` and a human decision is still needed — a note on exactly what's open.
