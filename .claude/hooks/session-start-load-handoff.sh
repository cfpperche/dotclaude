#!/usr/bin/env bash
# session-start-load-handoff.sh — SessionStart hook.
# Reads ~/dotclaude/handoff/current.md and emits a summary to the session.
# Non-interactive: never prompts. Silent on success when nothing to load.
# Bypass: DOTCLAUDE_HOOK_SESSION_START=0
#
# Project-scoped: only loads handoff when working inside the dotclaude
# project itself. The handoff documents work on dotclaude and has no
# business surfacing in any other project directory.

set -eu

if [ "${DOTCLAUDE_HOOK_SESSION_START:-1}" = "0" ]; then
	exit 0
fi

# Only load handoff when working inside the dotclaude repo itself.
# CLAUDE_PROJECT_DIR is set by Claude Code at session start; falls back to PWD.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
case "$PROJECT_DIR" in
	"$HOME/dotclaude"|"$HOME/dotclaude"/*) ;;
	*) exit 0 ;;
esac

HANDOFF="$HOME/dotclaude/handoff/current.md"

if [ ! -f "$HANDOFF" ]; then
	exit 0
fi

# Detect empty template (status: empty)
if grep -qE '^status:\s*empty' "$HANDOFF" 2>/dev/null; then
	exit 0
fi

# Extract topic and pending — terse summary only
TOPIC=$(grep -m1 '^# Handoff' "$HANDOFF" 2>/dev/null | sed 's/^# Handoff[[:space:]]*[—-]*[[:space:]]*//' || true)
[ -z "$TOPIC" ] && TOPIC="(no topic)"

# Output to stdout — Claude Code surfaces SessionStart hook stdout to the agent
cat <<EOF
[handoff] Resuming previous session.
Topic: $TOPIC
Full handoff: $HANDOFF
EOF

# Surface any past-due local reminders. Markers are written by scripts in
# scripts/remind-*.sh under cron and live in handoff/reminders/.
REMINDERS_DIR="$HOME/dotclaude/handoff/reminders"
if [ -d "$REMINDERS_DIR" ]; then
	# shellcheck disable=SC2012
	REMINDER_FILES=$(ls -1 "$REMINDERS_DIR"/*.md 2>/dev/null || true)
	if [ -n "$REMINDER_FILES" ]; then
		echo ""
		echo "[reminders] $(echo "$REMINDER_FILES" | wc -l | tr -d ' ') pending:"
		for f in $REMINDER_FILES; do
			TITLE=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# *//' || basename "$f" .md)
			echo "  - $TITLE ($f)"
		done
	fi
fi

exit 0
