#!/usr/bin/env bash
# Sync the locally-installed scaffolding-project skill with the upstream
# version in github.com/${GITHUB_USER}/scaffold-templates.
#
# Behavior:
#   - If the skill is installed via symlink to a clone of scaffold-templates,
#     git-pull the clone (fast-forward only).
#   - If the skill is installed as a copy (no symlink), fetch the upstream
#     SKILL.md via curl and overwrite the local file when it differs.
#   - If the skill is not installed at all, exit with code 0 and a hint.
#
# Flags:
#   --quiet     suppress informational output (errors still printed)
#
# Usage:
#   GITHUB_USER=<your-github-user> bash <(curl -fsSL https://raw.githubusercontent.com/<your-github-user>/scaffold-templates/main/scripts/sync-skill.sh)
#   bash sync-skill.sh --quiet

set -euo pipefail

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

log() { [ "$QUIET" = "1" ] || echo "$@"; }
warn() { echo "WARN: $*" >&2; }

GITHUB_USER="${GITHUB_USER:?set GITHUB_USER to your GitHub username}"
SKILL_LINK="$HOME/.copilot/skills/scaffolding-project"
UPSTREAM_RAW="https://raw.githubusercontent.com/${GITHUB_USER}/scaffold-templates/main/skills/scaffolding-project/SKILL.md"

if [ ! -e "$SKILL_LINK" ]; then
  log "scaffolding-project skill is not installed at $SKILL_LINK"
  log "run: GITHUB_USER=${GITHUB_USER} bash <(curl -fsSL https://raw.githubusercontent.com/${GITHUB_USER}/scaffold-templates/main/scripts/install.sh)"
  exit 0
fi

if [ -L "$SKILL_LINK" ]; then
  TARGET="$(readlink "$SKILL_LINK")"
  # symlink -> $REPO/skills/scaffolding-project; repo root is two levels up
  REPO_ROOT="$(cd "$(dirname "$TARGET")/.." 2>/dev/null && pwd || true)"
  if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/.git" ]; then
    log "==> syncing skill via git pull in $REPO_ROOT"
    if git -C "$REPO_ROOT" pull --ff-only 2>/dev/null; then
      git -C "$REPO_ROOT" submodule update --init --recursive 2>/dev/null || true
      log "    up to date."
      exit 0
    else
      warn "git pull failed; skill may be stale"
      exit 0
    fi
  fi
fi

log "==> syncing skill via raw fetch"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

if ! curl -fsSL "$UPSTREAM_RAW" -o "$TMP"; then
  warn "could not fetch upstream SKILL.md (offline?); keeping local version"
  exit 0
fi

LOCAL="$SKILL_LINK/SKILL.md"
if [ -f "$LOCAL" ] && cmp -s "$LOCAL" "$TMP"; then
  log "    up to date."
else
  cp "$TMP" "$LOCAL"
  log "    SKILL.md updated."
fi
