#!/usr/bin/env bash
# session-end-write-handoff.sh — Stop hook.
# Marker only: signals end-of-session for downstream tooling.
# The actual handoff content is written by the handoff-writer agent
# during the session (invoked via /handoff or by the agent's own decision),
# because hooks have no model context to summarize work.
# Non-interactive: never prompts.
# Bypass: DOTCLAUDE_HOOK_SESSION_END=0

set -eu

if [ "${DOTCLAUDE_HOOK_SESSION_END:-1}" = "0" ]; then
	exit 0
fi

# Project-scoped: only write end-of-session marker when inside dotclaude.
# Mirrors the guard in session-start-load-handoff.sh — the marker has no
# business showing up in any other project directory.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
case "$PROJECT_DIR" in
	"$HOME/dotclaude"|"$HOME/dotclaude"/*) ;;
	*) exit 0 ;;
esac

HANDOFF_DIR="$HOME/dotclaude/handoff"
mkdir -p "$HANDOFF_DIR/archive"

# Touch a stamp file the next session can read to know "previous ended at X"
STAMP="$HANDOFF_DIR/.last-session-end"
date -Iseconds > "$STAMP" 2>/dev/null || date > "$STAMP"

exit 0
