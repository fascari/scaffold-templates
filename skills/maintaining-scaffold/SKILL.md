---
name: maintaining-scaffold
description: Use when evolving the scaffold-templates repo itself — adding a new language template, adding/removing flags, refactoring a kit package, or porting patterns from a real project into the templates. Triggers on "atualizar scaffold", "novo template no scaffold", "adicionar flag", "evoluir scaffold", "scaffold maintenance".
---

# Maintaining the scaffold-templates repo

This skill captures the workflow for evolving `<your-github-user>/scaffold-templates`. Use it when **changing the templates** (not when *using* them — that's `scaffolding-project`).

## When to Use

- Adding a new language template (e.g., `node/`, `python/`)
- Adding a new flag to an existing template (e.g., `include_redis`)
- Porting a pattern from a real project (e.g., cashback-platform) into the scaffold
- Refactoring a kit package
- Bumping defaults (Go version, library versions, project layout)
- Anything that modifies `copier.yml`, `template/**`, `scripts/**`, or the bundled skill

## Reference Project

The canonical reference for the **Go template** is `cashback-platform` at
`/Users/felipeascari/personal/profissional/projects/cashback-platform/`.

When in doubt about a pattern, **read cashback-platform first**:
- `services/cashback-service-api/internal/` for service layout
- `kit/` for shared utilities
- `.mise.toml` for task conventions
- `docs/` for documentation style
- `test/e2e/` for e2e suite pattern

But: **always strip project-specific bits** before porting. The scaffold must be generic.

## Before Touching the Templates

1. **Read the current decisions:**
   - `$COPILOT_VAULT/scaffold-templates/architecture/decisions.md`
   - Any prior session log in `$COPILOT_VAULT/scaffold-templates/logs/`
2. **Understand the current state:**
   - `copier.yml` — variables, prompts, `_exclude`, `_tasks`
   - `template/` — what's already there, what's conditional
   - `skills/scaffolding-project/SKILL.md` — what the user-facing skill assumes
3. **Render the current template** before editing, so you have a baseline:
   ```bash
   rm -rf /tmp/scaffold-baseline && mkdir -p /tmp/scaffold-baseline && cd /tmp/scaffold-baseline
   copier copy --defaults --trust /Users/felipeascari/personal/profissional/projects/scaffold-templates/go .
   ```

## Decision Log Discipline

Every non-trivial change must:
1. **Append an ADR** to `$COPILOT_VAULT/scaffold-templates/architecture/decisions.md`.
   Format: `## ADR-NNN (YYYY-MM-DD): Title — Status — Context — Considered — Decision — Rationale.`
2. **Reference the ADR** in the commit message (e.g., `feat: add include_redis flag (ADR-009)`).
3. **Save a session log** at the end via the global `checkpoint` skill.

This is the only way you, future-you, and the agent in the next session will remember WHY the template looks like it does.

## Workflow: Adding a New Flag

Example: adding `include_redis` for projects that need Redis cache.

1. **Decide the surface area:**
   - What files are conditionally added? (e.g., `internal/cache/redis.go`, mise tasks, docker-compose service)
   - What config struct changes? (e.g., `Config.Redis.URL`)
   - What env vars? (e.g., `REDIS_URL`)

2. **Update `copier.yml`:**
   - Add the variable under "Optional features" with sensible default and `when:` guard.
   - Add `_exclude` entries for files that should NOT be rendered when the flag is off.
   - Update `_tasks` if needed.

3. **Add the template files:**
   - Create them under `template/` with `.jinja` suffix.
   - Use `{% if include_redis %}...{% endif %}` blocks INSIDE files when the file always exists but has conditional content.
   - Use `_exclude` when the WHOLE FILE should be skipped.

4. **Update existing templates** that need to know about the flag:
   - `internal/config/config.go.jinja` — add the new sub-config.
   - `internal/bootstrap/server.go.jinja` — wire it up.
   - `.env.example.jinja` — add env vars.
   - `.mise.toml.jinja` — add tasks.
   - `docs/configuration.md.jinja` — document it.
   - `docs/architecture.md.jinja` — mention it in the layered diagram if relevant.

5. **Render-test** at minimum two profiles (`include_redis=true` and `=false`):
   ```bash
   for flag in true false; do
     dir=/tmp/scaffold-test-redis-$flag
     rm -rf "$dir" && mkdir -p "$dir" && cd "$dir"
     copier copy --defaults --trust \
       --data project_name=test-redis \
       --data include_redis=$flag \
       /Users/felipeascari/personal/profissional/projects/scaffold-templates/go .
     go build ./... && echo "$flag OK"
   done
   ```

6. **Commit + push** with ADR reference.

## Workflow: Adding a New Language

Example: adding `node/` template.

1. **Pick the engine.** For Node, evaluate copier (works for any language) vs degit/hygen (Node-native). Default: copier (consistent with `go/`).
2. **Mirror the structure:** `node/copier.yml` + `node/template/`.
3. **Update top-level README** with the new entry in "Available templates".
4. **Update `skills/scaffolding-project/SKILL.md`** step 3 ("Identify the language template") with the new option.
5. **Add ADR** about language defaults (framework choice, package manager, test runner).
6. **Render-test** and ship.

## Workflow: Porting a Pattern from cashback-platform

When you want to "borrow" something cashback does well:

1. Open the cashback file alongside the template equivalent.
2. **Strip:**
   - Domain-specific names (`cashback`, `mint`, `deposit` → `example`)
   - Project-specific deps (ethereum, NATS unless that's the flag you're adding)
   - Hardcoded ports/URLs → reference Jinja vars
3. **Generalize:**
   - Replace specific structs with `Example` placeholder
   - Use `{{ module_path }}` for imports
4. **Document the port** in the ADR — note what was kept verbatim, what was simplified.

## Files You'll Touch Most Often

- `go/copier.yml` — variables, prompts, exclusions, tasks
- `go/template/internal/bootstrap/*.go.jinja` — wire-up changes
- `go/template/internal/config/config.go.jinja` — new config keys
- `go/template/.mise.toml.jinja` — task additions
- `go/template/docs/*.md.jinja` — documentation
- `go/template/.env.example.jinja` — env var additions
- `go/template/docker-compose.yml.jinja` — infra deps

## Constraints

- **Never break existing renders.** Every change must keep the default profile (single-service-rest, no flags toggled) working — render + `go build ./...`.
- **Never introduce hidden requirements.** If the rendered project needs a new tool (e.g., `protoc`), document it in `docs/development.md.jinja` and `mise.toml` `[tools]`.
- **Keep templates DRY but readable.** A 5-line Jinja `{% if %}` block beats a 50-line abstract macro.
- **Atlas migrations stay declarative.** When adding tables, prefer `db/schema/*.hcl` over hand-written SQL migrations.
- **No project-specific code in `internal/kit/`.** Generic helpers only. Project-specific belongs in `internal/app/<domain>/` of the rendered project.
- **Always `chmod +x`** new scripts via `_tasks` so they work on first render.
- **Update the bundled skill** if the flag changes user-facing behavior (e.g., new prompt, new failure mode).

## Test Profiles to Validate Against

After any non-trivial change, render-test at least:

| Profile | Command (excerpt) |
|---|---|
| Full REST (defaults) | `--data project_type=single-service-rest` |
| REST minimal | `--data include_db=false --data include_otel=false --data include_grpc=false` |
| Library | `--data project_type=library` |
| Study tutorial | `--data project_type=study-tutorial --data unit_names=01-foo,02-bar` |
| Multi-service workspace | `--data project_type=multi-service-workspace --data service_names=api,worker` |

For each: render → `go build ./...` (when applicable) → `go vet ./...`.

## Reference Resources

- Copier docs: https://copier.readthedocs.io/
- Atlas docs: https://atlasgo.io/
- mise docs: https://mise.jdx.dev/
- chi docs: https://go-chi.io/
- viper docs: https://github.com/spf13/viper
- testcontainers-go: https://golang.testcontainers.org/
- cashback-platform reference: `/Users/felipeascari/personal/profissional/projects/cashback-platform/`
