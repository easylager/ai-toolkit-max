# Python / FastAPI

- Follow existing Python project conventions.
- Prefer type hints.
- Use async only where it provides value.
- Do not introduce async merely because FastAPI supports it.
- Keep FastAPI routes thin.
- Keep business logic outside route handlers when it has meaningful complexity.
- Use Pydantic for external data validation.
- Handle database transactions explicitly.
- Avoid blocking I/O in async execution paths.
- Prefer FastAPI dependency injection for infrastructure boundaries.
- Write focused pytest tests.
