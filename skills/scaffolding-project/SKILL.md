---
name: scaffolding-project
description: Use when bootstrapping a new repository from scratch with the standard personal layout. Triggers on "scaffold", "scaffold a new project", "bootstrap repo", "novo projeto", or "iniciar projeto do zero". Thin wrapper around the Copier templates in this same repo (github.com/<your-github-user>/scaffold-templates).
---

# Scaffolding a New Project

Bootstraps a new repository using the [scaffold-templates](https://github.com/<your-github-user>/scaffold-templates) Copier templates, then wires the personal conventions on top: git remote with personal SSH alias, `.github` submodule, `plans/` symlink, and an optional vault folder.

This skill is **versioned in the same repo as the templates**. The skill keeps itself
in sync with upstream automatically (see step 1).

## When to Use

- Starting a new repository from an empty directory
- User says "scaffold this project", "bootstrap a new repo", "novo projeto"
- Before any implementation work — this skill **never** writes business logic

## Constraints

- **Personal account only.** Use `git@github.com-personal:<your-github-user>/<repo>.git` as origin.
- **Stop before implementation.** Once scaffolding is done, hand control back to the user.
- **Do not enter plan mode automatically.** This is an executive task with a clear procedure.
- **Trust copier prompts.** Copier asks the structural questions interactively.

## Prerequisites

Verify before starting (fail fast with a clear message if missing):

- `copier` on PATH (`copier --version`). Install hint: `uv tool install copier` or `pipx install copier`.
- `git`, `mise` on PATH.
- `~/.ssh/config` has a `github.com-personal` host alias.

## Steps

0. **Resolve the GitHub user** (used in every URL/remote below):
   ```bash
   GITHUB_USER="${GITHUB_USER:-}"
   ```
   - If `$GITHUB_USER` is set in the environment, use it silently.
   - Otherwise, **ask the user once** ("What's your GitHub username?") and export it for the rest of the session: `export GITHUB_USER=<answer>`.
   - Use `$GITHUB_USER` in all subsequent commands. Wherever this skill shows `<your-github-user>`, substitute `$GITHUB_USER` literally — do **not** hardcode any username in commands you run.

1. **Self-sync the skill from upstream:**
   The skill should always run the latest version published in `$GITHUB_USER/scaffold-templates`.
   Run a quiet sync before doing anything else:
   ```bash
   GITHUB_USER="$GITHUB_USER" bash <(curl -fsSL "https://raw.githubusercontent.com/$GITHUB_USER/scaffold-templates/main/scripts/sync-skill.sh") --quiet
   ```
   - The sync script checks if `~/.copilot/skills/scaffolding-project/SKILL.md` matches the upstream version and updates if not.
   - If offline or the script fails, log a warning and continue with the local version.

2. **Verify the working directory is suitable for scaffolding:**
   ```bash
   pwd
   ls -A | head -20
   ```
   - If the directory has files other than `.git/`, `.github/`, `.gitmodules`, ask before proceeding.
   - If `.git/` already exists with commits, ask whether to scaffold into the existing repo (overlay) or abort.

3. **Identify the language template:**
   Currently supported: `go`. (Check the README for the current list.) Ask the user if it's not obvious from context.

   Note on `study-tutorial`: copier asks `domain_names` (scenario-named
   packages, e.g. `goroutines,channels,transfers,deposits`), `study_entrypoint`
   (`cli` → `cmd/concurrency` with `--pattern` flag, `rest` → `cmd/api` with
   one POST per scenario) and `include_store` (map+sync.RWMutex shared store).
   You do not pre-answer these — copier owns the prompts.

   Note on `cli`: copier asks `cli_style` (`cli-simple` → single-command,
   os.Args, for assessments/scripts; `cli-complex` → cobra, subcommands,
   domain/, config/, for releasers/deployment tools). You do not pre-answer
   this — copier owns the prompts.

4. **Run copier interactively — DO NOT mediate the prompts:**

   Run this exact command in the user's interactive terminal and let copier own all prompts:
   ```bash
   copier copy --trust \
     --data "github_user=$GITHUB_USER" \
     --data "project_name=$(basename "$PWD")" \
     ~/personal/profissional/projects/scaffold-templates/<language> .
   ```

   Use the local path to the cloned `scaffold-templates` repo. The `gh:` shortcut
   (`gh:user/repo/<lang>`) does NOT work here because copier expands it to
   `https://github.com/user/repo/<lang>.git`, which GitHub rejects (no subdirectory
   support in clone URLs). If the user keeps the repo elsewhere, swap the path.

   The two `--data` overrides are allowed and required: both values are derivable from context the user already provided (the exported `$GITHUB_USER` and the current directory name). Forwarding them auto-fills `module_path` (`github.com/$GITHUB_USER/<project>`), `author_name`, and the project name itself, so copier doesn't ask for them.

   **Hard rules for this step (no exceptions, no rationalizations):**
   - **You do not call `ask_user` during this step.** Not for project type, not for units, not for "essential questions", not for anything. Copier asks; the user answers in copier's TUI.
   - **You do not pre-select, filter, or shortlist `project_type` choices** based on the repo name, your inference about what kind of project it is, or "sensible defaults". The user sees all 7 options copier offers (`single-service-rest`, `single-service-grpc`, `single-service-graphql`, `cli`, `library`, `study-tutorial`, `multi-service-workspace`) and picks one themselves.
   - **You do not pass any `--data` other than the two shown above** unless the user explicitly listed extra values in their request.
   - **You do not paraphrase copier's questions into your own forms.** If you find yourself about to write `ask_user(...)` in this step, stop — that's the bug.

   Your only job in step 4 is: invoke copier and stay silent until it finishes. `--trust` is required because templates run post-render tasks (`go mod tidy`, dynamic dirs).

5. **Initialize git (if not already initialized):**
   ```bash
   git init -b main
   ```

6. **Configure the personal remote:**
   Ask for the repo name on GitHub if it differs from the directory name. Default = directory name.
   ```bash
   git remote add origin "git@github.com-personal:$GITHUB_USER/<repo>.git"
   ```
   If the user has not yet created the repo on GitHub, instruct them to create it manually under the personal account (the work `gh` CLI auth would push to the wrong org).

7. **Add the `.github` submodule (ai-config):**
   ```bash
   git submodule add "git@github.com-personal:$GITHUB_USER/ai-config.git" .github
   ```
   This pulls the public skills, agent rules, and `AGENTS.md`.

8. **Create the `plans/` symlink:**
   ```bash
   mkdir -p ~/ai-plans/<repo>
   ln -s ~/ai-plans/<repo> .github/plans
   ```
   `.github/plans` is in ai-config's `.gitignore`, so the submodule stays clean.

9. **(Optional) Create the vault project folder** (only if `$COPILOT_VAULT` is set):
   ```bash
   mkdir -p "$COPILOT_VAULT/<repo>"/{logs,architecture,plans,features}
   ```

10. **Verify the scaffold builds (when applicable):**
    - Go single-service: `mise run build` or `go build ./...`
    - Library / study / workspace types: skip.

11. **Stage and present, do not commit yet:**
    ```bash
    git add -A
    git status --short
    ```
    Show the user what was scaffolded. Ask whether they want the initial commit + push now, or to inspect first.

12. **(On user confirmation) initial commit and push:**
    ```bash
    git commit -m "chore: scaffold project from \$GITHUB_USER/scaffold-templates"
    git push -u origin main
    ```

## What This Skill Does NOT Do

- Write any application logic, tests, or feature code.
- Pick project_type, license, or feature flags without asking — copier handles that.
- Create the GitHub remote repo (auth is on the work account; user creates manually).
- Bump submodules in other repos, run linters, or generate documentation.

## Failure Modes

- **`copier: command not found`** → tell the user to install (`uv tool install copier`) and stop.
- **SSH push fails with permission denied** → check `ssh -T github.com-personal`; the user may need to load the personal key.
- **`gh` CLI authenticated as MHE work** → do **not** use `gh repo create`; ask the user to create the repo via web UI under the personal account.
- **Directory not empty** → list contents and ask before overwriting.
- **Sync script fails (step 1)** → continue with the local skill version, but warn the user that the skill may be stale.

## First-time install

If this skill isn't installed at all on a new machine, run (replace `<your-github-user>` with your actual GitHub username — this section is bootstrap, run before the skill itself):
```bash
export GITHUB_USER=<your-github-user>
bash <(curl -fsSL "https://raw.githubusercontent.com/$GITHUB_USER/scaffold-templates/main/scripts/install.sh")
```
This clones the repo into `~/personal/profissional/projects/scaffold-templates/` (or a path of your choice) and creates symlinks for `scaffolding-project` and `maintaining-scaffold` under `~/.copilot/skills/`.

## Reference

- Templates + skill repo: https://github.com/<your-github-user>/scaffold-templates
- Copier docs: https://copier.readthedocs.io/
