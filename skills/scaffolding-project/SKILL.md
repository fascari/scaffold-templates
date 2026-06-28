---
name: scaffolding-project
description: Use when bootstrapping a new repository from scratch with the standard Copier templates. Triggers on "scaffold a project", "novo projeto", "bootstrap repo", or similar.
---

# Scaffolding A New Project

Bootstraps a repository using the `scaffold-templates` Copier templates. The generated project receives only project files. AI-agent skills, instructions, memory, and provider-specific configuration stay global in the developer environment.

## Core Rules

- Do not copy or link AI skills into the generated repository.
- Do not create `.github/` for AI-agent configuration. GitHub-native files belong there only when the project explicitly needs them, such as workflows.
- Do not clone or link `ai-config`, `atlas`, or any other sibling repository.
- Do not write absolute local paths into generated files, docs, git remotes, or Copier answers.
- Treat the GitHub owner, remote URL, and AI memory location as configurable inputs.

## Required Tools

Verify before starting and fail fast if missing:

```bash
git --version
copier --version
go version
```

For remote templates, Copier also needs network access to the template repository. For local template usage, use the local path to this repository instead.

## Inputs To Confirm

Ask only for values that cannot be inferred safely:

- Target language template. Currently supported: `go`.
- Project name. Use the current directory basename when it is already the intended repo name.
- GitHub owner for module path and default origin URL. Prefer `$GITHUB_OWNER`; fall back to `$GITHUB_USER` only as a compatibility alias.
- Whether to configure a git remote. If yes, use `$GIT_REMOTE_URL` when set; otherwise default to `git@github.com:<owner>/<repo>.git`.
- Copier feature choices such as project type, database, gRPC, GraphQL, CLI style, and license. Let Copier prompt for these unless the user already supplied them.

## Procedure

1. **Check the target directory.**

   Run from the target project root, not from the `scaffold-templates` repository. The directory should be empty, except `.git/` is acceptable if the user already ran `git init`.

   Existing AI-agent instruction files such as `AGENTS.md` may remain when they were created by the user's environment, but do not create or modify them as part of scaffolding. If other project files exist, stop and ask before proceeding.

2. **Resolve template source.**

   Prefer a local template path when this skill is installed from a clone:

   ```bash
   <scaffold-templates>/go
   ```

   Otherwise use the remote Copier source:

   ```bash
   gh:<owner>/scaffold-templates/go
   ```

3. **Run Copier.**

   Pass only portable data:

   ```bash
   cd <target-project>
   copier copy --trust \
     --data "project_name=<repo>" \
     --data "github_user=<owner>" \
     <template-source> .
   ```

   Continue through Copier prompts with the user. Do not invent product choices.

4. **Initialize git if needed.**

   ```bash
   git init
   ```

5. **Configure the default origin only when requested.**

   ```bash
   git remote add origin "${GIT_REMOTE_URL:-git@github.com:<owner>/<repo>.git}"
   ```

   If `origin` already exists, inspect it and ask before changing it.

6. **Create external AI memory only when configured.**

   If `$AI_MEMORY_HOME` is set, create the project folders outside the repository:

   ```bash
   mkdir -p "$AI_MEMORY_HOME/<repo>"/{logs,architecture,plans,features}
   ```

   Do not create a repository symlink to that folder.

7. **Run validation.**

   For Go templates, run:

   ```bash
   go mod tidy
   go test ./...
   go build ./...
   ```

8. **Show the final state.**

   ```bash
   git status --short
   ```

   Summarize the template type, enabled major features, validation result, and any manual next steps.

## Boundaries

Do not:

- Create the GitHub repository remotely unless the user explicitly asks.
- Commit, push, or open a pull request without explicit approval.
- Add provider-specific AI configuration to the generated project.
- Add project-local skill links.
- Assume a personal SSH host alias.

## Failure Modes

- **Copier cannot find the template**: rerun with a local template path or set `GITHUB_OWNER` for the remote source.
- **Git remote auth fails**: use a standard GitHub remote, or ask the user for `GIT_REMOTE_URL`.
- **Validation fails**: keep the generated files in place, report the failing command, and fix template issues only when the user asks to update the scaffold.

## Installing This Skill Globally

From a clone of `scaffold-templates`:

```bash
./scripts/install.sh --provider codex
```

Other providers can be selected with `--provider copilot`, `--provider all`, or `--provider custom` plus `AI_SKILLS_DIR`.
