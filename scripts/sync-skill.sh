#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/sync-skill.sh [--provider codex|copilot|all|custom] [--quiet]

Refreshes the local scaffold-templates clone used by globally installed skills.
The skills are expected to be symlinks created by scripts/install.sh.

Environment:
  CODEX_HOME      Codex home directory. Default: $HOME/.codex
  AI_SKILLS_DIR   Target directory when --provider custom is used.
EOF
}

provider="codex"
quiet=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      provider="${2:?missing provider after --provider}"
      shift 2
      ;;
    --quiet)
      quiet=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

log() {
  if [[ "$quiet" -eq 0 ]]; then
    echo "$@" >&2
  fi
}

targets=()
case "$provider" in
  codex)
    targets+=("${CODEX_HOME:-$HOME/.codex}/skills")
    ;;
  copilot)
    targets+=("$HOME/.copilot/skills")
    ;;
  all)
    targets+=("${CODEX_HOME:-$HOME/.codex}/skills")
    targets+=("$HOME/.copilot/skills")
    ;;
  custom)
    targets+=("${AI_SKILLS_DIR:?set AI_SKILLS_DIR when using --provider custom}")
    ;;
  *)
    echo "Unsupported provider: $provider" >&2
    usage >&2
    exit 2
    ;;
esac

repos=()
for target_dir in "${targets[@]}"; do
  for skill_name in scaffolding-project maintaining-scaffold; do
    link_path="$target_dir/$skill_name"
    if [[ ! -L "$link_path" ]]; then
      continue
    fi

    skill_path="$(readlink "$link_path")"
    repo_root="$(cd "$skill_path/../.." 2>/dev/null && pwd -P || true)"
    if [[ -n "$repo_root" && -d "$repo_root/.git" ]]; then
      repos+=("$repo_root")
    fi
  done
done

if [[ "${#repos[@]}" -eq 0 ]]; then
  log "No scaffold-templates skill symlinks found. Run scripts/install.sh first."
  exit 0
fi

mapfile -t unique_repos < <(printf '%s\n' "${repos[@]}" | sort -u)
for repo_root in "${unique_repos[@]}"; do
  log "Updating $repo_root"
  git -C "$repo_root" pull --ff-only
done
