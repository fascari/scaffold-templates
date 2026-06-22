# scaffold-templates

[Copier](https://copier.readthedocs.io/) templates I use to bootstrap personal projects, plus the Copilot skill that drives them. One subdirectory per language.

## Available templates

| Template | Status | Description |
|---|---|---|
| [`go/`](./go) | v3 | Go services and libraries. REST + gRPC, single-module or multi-service workspace, atlas migrations, OTel, testcontainers integration tests. Mirrors my production layout. |
| `node/` | planned | TypeScript/Node.js services. |
| `python/` | planned | Python services. |

## Requirements

- [Copier](https://copier.readthedocs.io/) ≥ 9 (`uv tool install copier` or `pipx install copier`)
- `git`, plus the language toolchain

## Cloning this repo

This repo uses shared `.github` symlinks into [`ai-config`](https://github.com/) so the full set of personal Copilot skills is auto-loaded by Copilot CLI when you work here. Clone with:

```bash
git clone git@github.com-<your-github-user>:<your-github-user>/scaffold-templates.git
```

Skills loaded when you open Copilot CLI in this repo:

- `.github/skills/` — linked from `ai-config` (planning, committing, reviewing, testing, writing-modern-go, etc.)
- `skills/` — local scaffold skills (`scaffolding-project`, `maintaining-scaffold`); `scripts/install.sh` symlinks both into `~/.copilot/skills/` so they're available in any cwd.

## Creating a new repo

> Replace `<your-github-user>` below with your GitHub username (the account that owns your fork of this repo). The scripts also read it from the `GITHUB_USER` env var.

Three ways to bootstrap a new project, from highest to lowest level.

### 1. Copilot CLI skill (recommended)

Install once per machine:

```bash
export GITHUB_USER=<your-github-user>
bash <(curl -fsSL https://raw.githubusercontent.com/$GITHUB_USER/scaffold-templates/main/scripts/install.sh)
```

The installer clones this repo and symlinks the `scaffolding-project` skill into `~/.copilot/skills/`. Then, to create a new repo:

```bash
mkdir my-project && cd my-project
copilot                       # start Copilot CLI in the empty directory
> scaffold a new go project   # ask the skill in chat
```

The skill prompts for the language, runs copier, wires the shared `.github` links and `plans/` symlink, configures the `git@github.com-personal:<your-github-user>/<repo>.git` remote, and offers to do the initial commit + push. See [`SKILL.md`](./skills/scaffolding-project/SKILL.md) for the full procedure and prerequisites (SSH alias, `mise`, etc.).

`scripts/sync-skill.sh` runs at the start of each invocation, so skill updates here flow to your machine without a manual reinstall.

### 2. Copier directly (no Copilot)

```bash
mkdir my-project && cd my-project
copier copy --trust "gh:<your-github-user>/scaffold-templates/go" .
```

Copier prompts for project name, module path, project type, and optional features. `--trust` is required because templates run post-render tasks (`go mod tidy`, dynamic dirs, etc.). After copier finishes you have to wire git/remote and the shared `.github` links manually — that's what the skill above automates.

### 3. `mise` task (from a clone of this repo)

```bash
GITHUB_USER=<your-github-user> mise run -C ~/path/to/scaffold-templates scaffold my-project go
```

Creates `my-project/` in your CWD and runs copier inside it.

### Updating an existing project

To re-apply the template after this repo evolves:

```bash
copier update
```

## Layout

```
go/                                Copier template for Go projects
  copier.yml                       prompts, conditions, exclude rules, post-render tasks
  template/                        Jinja-templated files
.github/                           shared symlinks -> ai-config (auto-loaded by Copilot CLI)
skills/
  scaffolding-project/SKILL.md     personal skill: bootstraps new projects
                                   (symlinked into ~/.copilot/skills/ by install.sh)
  maintaining-scaffold/SKILL.md    project skill: evolve the templates themselves
                                   (auto-loads when Copilot opens this repo via global symlink)
scripts/
  install.sh                       first-time setup on a new machine
  sync-skill.sh                    keeps the installed skill in sync with upstream
.mise/tasks/
  scaffold.sh                      `mise run scaffold <name> <language>` wrapper
```

## License

MIT.
