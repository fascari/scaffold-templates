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

This repo ships **both** the templates and the Copilot skill that drives them. Install once per machine:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/fascari/scaffold-templates/main/scripts/install.sh)
```

This clones the repo and creates a symlink at `~/.copilot/skills/scaffolding-project/`. Then in any new empty repo dir, ask Copilot CLI: *"scaffold a new go project"* — the [`scaffolding-project`](./skills/scaffolding-project/SKILL.md) skill handles the prompts, copier run, `.github` submodule, `plans/` symlink, and initial commit.

The skill self-syncs on each run via `scripts/sync-skill.sh`, so your installed version stays current automatically.

You can also invoke `copier` directly without the skill:

```bash
mkdir my-project && cd my-project
copier copy --trust "gh:fascari/scaffold-templates/go" .
```

Re-apply the template later (when patterns evolve):

```bash
copier update
```

## Layout

```
go/                              Copier template for Go projects
  copier.yml                     prompts, conditions, exclude rules, post-render tasks
  template/                      Jinja-templated files
skills/
  scaffolding-project/SKILL.md   Copilot CLI skill (thin wrapper around copier)
scripts/
  install.sh                     first-time install on a new machine
  sync-skill.sh                  keep the installed skill in sync with upstream
```

## License

MIT — feel free to fork, adapt, and reuse.
