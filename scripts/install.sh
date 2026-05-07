#!/usr/bin/env bash
# Install the scaffolding-project skill globally on this machine.
#
# What it does:
#   1. Clones github.com/fascari/scaffold-templates to a chosen path
#      (default: ~/personal/profissional/projects/scaffold-templates).
#   2. Creates a symlink at ~/.copilot/skills/scaffolding-project pointing
#      to the cloned skills/scaffolding-project directory.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/fascari/scaffold-templates/main/scripts/install.sh)
#   INSTALL_PATH=~/code/scaffold-templates bash install.sh

set -euo pipefail

REPO_URL_DEFAULT="git@github.com-personal:fascari/scaffold-templates.git"
REPO_URL_HTTPS="https://github.com/fascari/scaffold-templates.git"
INSTALL_PATH="${INSTALL_PATH:-$HOME/personal/profissional/projects/scaffold-templates}"
SKILL_LINK="$HOME/.copilot/skills/scaffolding-project"

echo "==> scaffold-templates installer"
echo "    target path : $INSTALL_PATH"
echo "    skill link  : $SKILL_LINK"
echo

if [ -d "$INSTALL_PATH/.git" ]; then
  echo "==> Repo already cloned at $INSTALL_PATH — pulling latest"
  git -C "$INSTALL_PATH" pull --ff-only
else
  echo "==> Cloning scaffold-templates"
  mkdir -p "$(dirname "$INSTALL_PATH")"
  if git clone "$REPO_URL_DEFAULT" "$INSTALL_PATH" 2>/dev/null; then
    :
  else
    echo "    SSH clone failed, falling back to HTTPS"
    git clone "$REPO_URL_HTTPS" "$INSTALL_PATH"
  fi
fi

mkdir -p "$(dirname "$SKILL_LINK")"

if [ -L "$SKILL_LINK" ] || [ -e "$SKILL_LINK" ]; then
  echo "==> $SKILL_LINK already exists — replacing"
  rm -rf "$SKILL_LINK"
fi

ln -s "$INSTALL_PATH/skills/scaffolding-project" "$SKILL_LINK"

echo
echo "==> Done."
echo "    Skill linked: $SKILL_LINK -> $INSTALL_PATH/skills/scaffolding-project"
echo
echo "Next steps:"
echo "  - Make sure 'copier' is installed:  uv tool install copier"
echo "  - In a new empty repo dir, ask Copilot: 'scaffold a new go project'"
