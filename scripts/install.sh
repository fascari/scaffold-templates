#!/usr/bin/env bash
# Install the scaffolding-project skill globally on this machine.
#
# What it does:
#   1. Clones github.com/${GITHUB_USER}/scaffold-templates
#      to a chosen path (default: ~/personal/profissional/projects/scaffold-templates).
#   2. Creates symlinks under ~/.copilot/skills/ pointing to each scaffold skill
#      (scaffolding-project, maintaining-scaffold), making them globally available.
#
# Usage:
#   GITHUB_USER=<your-github-user> bash <(curl -fsSL https://raw.githubusercontent.com/<your-github-user>/scaffold-templates/main/scripts/install.sh)
#   INSTALL_PATH=~/code/scaffold-templates GITHUB_USER=<your-github-user> bash install.sh

set -euo pipefail

GITHUB_USER="${GITHUB_USER:?set GITHUB_USER to your GitHub username (the account that owns the scaffold-templates fork)}"
REPO_URL_DEFAULT="git@github.com-personal:${GITHUB_USER}/scaffold-templates.git"
REPO_URL_HTTPS="https://github.com/${GITHUB_USER}/scaffold-templates.git"
INSTALL_PATH="${INSTALL_PATH:-$HOME/personal/profissional/projects/scaffold-templates}"
SKILLS_DIR="$HOME/.copilot/skills"
SCAFFOLD_SKILLS=(scaffolding-project maintaining-scaffold)

echo "==> scaffold-templates installer"
echo "    target path : $INSTALL_PATH"
echo "    skills dir  : $SKILLS_DIR"
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

mkdir -p "$SKILLS_DIR"

for skill in "${SCAFFOLD_SKILLS[@]}"; do
  link="$SKILLS_DIR/$skill"
  target="$INSTALL_PATH/skills/$skill"
  if [ -L "$link" ] || [ -e "$link" ]; then
    echo "==> $link already exists — replacing"
    rm -rf "$link"
  fi
  ln -s "$target" "$link"
  echo "    linked: $link -> $target"
done

echo
echo "==> Done."
echo
echo "Next steps:"
echo "  - Make sure 'copier' is installed:  uv tool install copier"
echo "  - In a new empty repo dir, ask Copilot: 'scaffold a new go project'"
