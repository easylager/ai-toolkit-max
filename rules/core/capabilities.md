# Capabilities

External systems Claude can reach are capabilities, not requirements. A skill decides *what* to do; a capability decides *what it can reach* while doing it. Use the minimum capability that produces sufficient evidence — prefer the local filesystem/CLI over an MCP, and prefer no capability over an unnecessary one.

## Selection

Before reaching for an MCP: can the repository, git history, or local tooling already answer this? If yes, use that. Only invoke an MCP when it's the minimum one that supplies a fact or evidence the local context can't.

Never invent or assume access to an MCP that isn't configured in this session. If the ideal capability is unavailable, use the best available alternative and say so explicitly only when the gap materially affects confidence in the result — an MCP hint is never a blocking requirement by itself.

## Registry

| MCP | Supplies | Used by | Default permission |
|---|---|---|---|
| Linear / Notion | requirements, specs, discussion | `clarify` | read |
| GitHub | issues, PRs, review comments, repo history | `clarify`, `plan`, `review` | minimum scope needed, prefer read |
| Figma | design/layout context, when a Figma file already exists for this UI | `plan`, before implementing UI, only if no `/design` prototype exists | read, unless a change is explicitly requested |
| Context7 | current/version-specific library docs | `plan`, `debug` | read |
| Playwright / Chrome DevTools | browser automation, DOM/console/network inspection | `verify`, `debug` | no destructive action without explicit authorization |
| Sentry | production errors, stack traces, events | `verify`, `debug` | read |
| Postgres | schema/data inspection | `verify`, `debug` | read-only |

Extend this list only when a skill demonstrably needs a new capability, not speculatively.

`/design`'s disposable HTML prototype (see `skills/design/SKILL.md`) is the default UI-context source for `/plan` — reach for the Figma row above only when no approved prototype exists for the task and a Figma file already does.

## Permissions

- Treat any capability touching a shared or production system as high-risk: read by default, write/mutate only with explicit authorization for that specific action.
- Tool availability is not permission — being able to call an MCP doesn't mean a destructive action on it is authorized.
