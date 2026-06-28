# scaffold-templates

Reusable [Copier](https://copier.readthedocs.io/) templates for bootstrapping projects with consistent defaults. The repository contains the templates and the optional global AI-agent skills that drive them; generated projects do not vendor those skills.

## Templates

| Path | Status | Scope |
|---|---:|---|
| [`go/`](./go) | v3 | Go services, CLIs, libraries, GraphQL, gRPC, multi-service workspaces, Atlas migrations, OTel, and testcontainers-based integration tests. |
| `node/` | planned | TypeScript/Node.js projects. |
| `python/` | planned | Python projects. |

## Design Rules

- A clean clone must work without sibling repositories, absolute local paths, or machine-specific symlinks.
- AI skills are installed globally per agent/provider. They are not copied or linked into generated projects.
- Generated projects should not assume a specific AI vendor. Provider-specific files and local skill links are left to the developer's environment.
- `.github/` is not used as a fixed AI configuration surface. If a generated project later needs GitHub-native files, they should be real project files such as workflows, not links to a local AI config checkout.

## Install Global Scaffold Skills

The `skills/` directory contains optional workflow skills for AI agents:

- `scaffolding-project`
- `maintaining-scaffold`

Install them globally for the provider you use:

```bash
git clone https://github.com/<owner>/scaffold-templates.git
cd scaffold-templates
./scripts/install.sh --provider codex
```

Supported providers:

```bash
./scripts/install.sh --provider codex
./scripts/install.sh --provider copilot
./scripts/install.sh --provider all
AI_SKILLS_DIR=/path/to/skills ./scripts/install.sh --provider custom
```

For a one-line install from a remote script, provide the repository owner or URL:

```bash
SCAFFOLD_TEMPLATES_REPO=<owner>/scaffold-templates \
  bash <(curl -fsSL https://raw.githubusercontent.com/<owner>/scaffold-templates/main/scripts/install.sh) --provider codex
```

The installer uses symlinks from the global skills directory back to this checkout. To update the skills, pull the repository and rerun the installer, or run `scripts/sync-skill.sh`.

## Generate A Project

### Through The Global Skill

Open your AI agent in the target project root and ask it to scaffold the project. This can be a new empty directory or an already-created git repository with no project files yet.

The skill prompts for the language and Copier answers, runs the template into the current directory, configures git metadata when requested, and leaves AI-agent memory outside the generated repository.

### Direct Copier Usage

Run Copier from the repository that should receive the generated files:

```bash
mkdir my-project && cd my-project
copier copy --trust "gh:<owner>/scaffold-templates/go" .
```

For an existing empty repository:

```bash
cd /path/to/my-project
copier copy --trust "gh:<owner>/scaffold-templates/go" .
```

`--trust` is required because the template runs post-render tasks such as `go mod tidy` and conditional setup scripts.

### Local Mise Task

From a clone of this repository:

```bash
GITHUB_OWNER=<owner> mise run scaffold my-project go
```

This renders into `./my-project` under the scaffold-templates checkout. Use direct Copier usage when the target repository already exists somewhere else.

## Updating A Generated Project

Generated projects keep Copier metadata, so future template updates can be applied from inside the project:

```bash
copier update
```

Review the diff carefully. Template updates can touch build files, generated documentation, and project structure.

## Layout

```text
.
├── go/
│   ├── copier.yml
│   ├── template/
│   └── _scripts/
├── scripts/
│   ├── install.sh
│   └── sync-skill.sh
└── skills/
    ├── maintaining-scaffold/
    └── scaffolding-project/
```

## License

MIT.
