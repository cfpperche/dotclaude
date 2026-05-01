#!/usr/bin/env bash
# update.sh — pull latest dotclaude, rerun doctor.

set -euo pipefail

DOTCLAUDE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DOTCLAUDE_DIR"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }

green "==> dotclaude update"

# Refuse to overwrite tracked-file changes (modified, staged, deleted, etc).
# Untracked files (?? prefix) are tolerated — they don't conflict with
# git pull --ff-only and are common after a fresh cutover.
# Note: pipe to awk instead of grep to avoid exit 1 on zero matches under
# pipefail.
DIRTY=$(git status --short | awk '!/^\?\?/' | wc -l | tr -d ' ')
if [ "$DIRTY" -gt 0 ]; then
	yellow "Local changes to tracked files:"
	git status --short | awk '!/^\?\?/'
	echo
	yellow "Stash or commit before update. Aborting."
	exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
	yellow "Not on main (current: $CURRENT_BRANCH). Skipping pull."
else
	git pull --ff-only origin main
fi

# Re-apply executable bits (in case of fresh clone or filesystem quirks)
find "$DOTCLAUDE_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
find "$DOTCLAUDE_DIR/hooks" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
chmod +x "$DOTCLAUDE_DIR/statusline.mjs" 2>/dev/null || true

green "==> Running doctor"
bash "$DOTCLAUDE_DIR/scripts/doctor.sh"

green "==> Update complete"
