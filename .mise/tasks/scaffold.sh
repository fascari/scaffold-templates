#!/usr/bin/env bash
#MISE description="Scaffold a new project from a template (usage: mise run scaffold <name> <language>)"
#USAGE arg "<name>" help="Project name (creates a directory with this name)"
#USAGE arg "<language>" help="Template language: go|node|python"
set -euo pipefail

NAME="${1:?missing project name}"
LANG="${2:?missing language (go|node|python)}"

case "$LANG" in
  go|node|python) ;;
  *) echo "error: unsupported language '$LANG' (expected: go|node|python)" >&2; exit 1 ;;
esac

if ! command -v copier >/dev/null 2>&1; then
  echo "error: copier not installed. Run: uv tool install copier  (or: pipx install copier)" >&2
  exit 1
fi

if [[ -e "$NAME" ]]; then
  echo "error: '$NAME' already exists" >&2
  exit 1
fi

mkdir "$NAME"
cd "$NAME"
GITHUB_USER="${GITHUB_USER:?set GITHUB_USER to your GitHub username}"
copier copy --trust "gh:${GITHUB_USER}/scaffold-templates/${LANG}" .

echo
echo "✓ Scaffold complete in $(pwd)"
