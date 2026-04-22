#!/usr/bin/env bash
# Install this plugin's skills into a Unity project as project-scoped symlinks.
# Skills will only appear in Claude Code sessions running inside that project.
#
# Usage:
#   ./install-in-project.sh <path-to-unity-project>
#   ./install-in-project.sh            # defaults to current directory

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$PLUGIN_DIR/skills"
PROJECT_DIR="${1:-$PWD}"

if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: project directory does not exist: $PROJECT_DIR" >&2
  exit 1
fi

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "Error: plugin skills directory not found: $SKILLS_DIR" >&2
  exit 1
fi

TARGET="$PROJECT_DIR/.claude/skills"
mkdir -p "$TARGET"

for skill in unity-dod-architecture unity-development unity-ui-ux-checklist; do
  src="$SKILLS_DIR/$skill"
  dst="$TARGET/$skill"
  if [[ ! -d "$src" ]]; then
    echo "  skip $skill (not found in plugin)"
    continue
  fi
  ln -sfn "$src" "$dst"
  echo "  linked $skill"
done

echo
echo "Installed 3 skills into $TARGET"
echo "Restart Claude Code in $PROJECT_DIR to see them in the skills list."
