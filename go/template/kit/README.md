# kit

Shared, reusable Go packages used across all services in this workspace.

Each package is standalone, well-tested, and has minimal dependencies.

## Packages

| Package | Description |
|---|---|
| `apperror` | Application error envelope with code/message |
| `clock` | Time abstraction for testable time-dependent code |
| `httpjson` | JSON read/write helpers for HTTP handlers |
| `logger` | Structured logger built on `log/slog` |

Add new packages as the platform grows. Keep them focused: one concern per package.
