#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install.sh [--provider codex|copilot|all|custom]

Installs this repository's skills as global symlinks for the selected AI agent
provider. Generated projects do not receive these skills.

Options:
  --provider VALUE   codex, copilot, all, or custom. Default: codex.

Environment:
  CODEX_HOME                  Codex home directory. Default: $HOME/.codex
  AI_SKILLS_DIR               Target directory when --provider custom is used.
  INSTALL_PATH                Clone path used when this script is run remotely.
                              Default: ${XDG_DATA_HOME:-$HOME/.local/share}/scaffold-templates
  SCAFFOLD_TEMPLATES_REPO     GitHub repo in owner/name form, used for remote installs.
  SCAFFOLD_TEMPLATES_URL      Full git URL, used for remote installs.
  GITHUB_USER                 Backward-compatible fallback for SCAFFOLD_TEMPLATES_REPO.
EOF
}

provider="codex"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      provider="${2:?missing provider after --provider}"
      shift 2
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

script_source="${BASH_SOURCE[0]:-$0}"
script_dir="$(cd "$(dirname "$script_source")" 2>/dev/null && pwd -P || true)"
repo_root=""

if [[ -n "$script_dir" && -d "$script_dir/../skills" ]]; then
  repo_root="$(cd "$script_dir/.." && pwd -P)"
else
  install_path="${INSTALL_PATH:-${XDG_DATA_HOME:-$HOME/.local/share}/scaffold-templates}"
  repo_url="${SCAFFOLD_TEMPLATES_URL:-}"

  if [[ -z "$repo_url" ]]; then
    repo="${SCAFFOLD_TEMPLATES_REPO:-}"
    if [[ -z "$repo" && -n "${GITHUB_USER:-}" ]]; then
      repo="${GITHUB_USER}/scaffold-templates"
    fi
    if [[ -z "$repo" ]]; then
      echo "Set SCAFFOLD_TEMPLATES_REPO=owner/scaffold-templates or SCAFFOLD_TEMPLATES_URL for remote installs." >&2
      exit 1
    fi
    repo_url="https://github.com/${repo}.git"
  fi

  if [[ -d "$install_path/.git" ]]; then
    git -C "$install_path" pull --ff-only
  else
    mkdir -p "$(dirname "$install_path")"
    git clone "$repo_url" "$install_path"
  fi
  repo_root="$install_path"
fi

if [[ ! -d "$repo_root/skills" ]]; then
  echo "No skills directory found at $repo_root/skills" >&2
  exit 1
fi

targets=()
case "$provider" in
  codex)
    targets+=("codex:${CODEX_HOME:-$HOME/.codex}/skills")
    ;;
  copilot)
    targets+=("copilot:$HOME/.copilot/skills")
    ;;
  all)
    targets+=("codex:${CODEX_HOME:-$HOME/.codex}/skills")
    targets+=("copilot:$HOME/.copilot/skills")
    ;;
  custom)
    target="${AI_SKILLS_DIR:?set AI_SKILLS_DIR when using --provider custom}"
    targets+=("custom:$target")
    ;;
  *)
    echo "Unsupported provider: $provider" >&2
    usage >&2
    exit 2
    ;;
esac

mapfile -t skill_paths < <(find "$repo_root/skills" -mindepth 1 -maxdepth 1 -type d | sort)
if [[ "${#skill_paths[@]}" -eq 0 ]]; then
  echo "No skills found in $repo_root/skills" >&2
  exit 1
fi

link_count=0
for target_spec in "${targets[@]}"; do
  provider_name="${target_spec%%:*}"
  target_dir="${target_spec#*:}"
  mkdir -p "$target_dir"

  for skill_path in "${skill_paths[@]}"; do
    skill_name="$(basename "$skill_path")"
    link_path="$target_dir/$skill_name"

    if [[ -e "$link_path" && ! -L "$link_path" ]]; then
      echo "Skipping $link_path because it exists and is not a symlink." >&2
      continue
    fi

    ln -sfn "$skill_path" "$link_path"
    echo "linked [$provider_name]: $link_path -> $skill_path"
    ((link_count += 1))
  done
done

echo "Installed $link_count skill link(s) from $repo_root."
