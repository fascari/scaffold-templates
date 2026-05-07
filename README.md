# scaffold-templates

[Copier](https://copier.readthedocs.io/) templates for bootstrapping new personal projects. Each language lives in its own subdirectory.

## Available templates

| Template | Status | Description |
|---|---|---|
| [`go/`](./go) | ✅ v1 | Go services and libraries (REST, gRPC, GraphQL, library, tutorial, multi-service workspace). Optional Dockerfile, DB toolchain, mockery, env files. |
| `node/` | ⏳ planned | TypeScript/Node.js services. |
| `python/` | ⏳ planned | Python services. |

## Requirements

- [Copier](https://copier.readthedocs.io/) ≥ 9 (`uv tool install copier` or `pipx install copier`)
- `git`, plus the language toolchain you're targeting

## Usage

The standard workflow is via the [`scaffolding-project`](https://github.com/fascari/ai-config/tree/main/skills/scaffolding-project) skill, which wraps this template, sets up the `.github` submodule, the `plans/` symlink, the initial commit, and the GitHub remote.

You can also invoke `copier` directly:

```bash
mkdir my-project && cd my-project
copier copy "gh:fascari/scaffold-templates/go" .
```

Re-apply the template later (when patterns evolve):

```bash
copier update
```

## License

MIT — feel free to fork, adapt, and reuse.
