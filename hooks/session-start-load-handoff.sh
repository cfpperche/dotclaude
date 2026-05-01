#!/usr/bin/env bash
# session-start-load-handoff.sh — SessionStart hook.
# Reads ~/.claude/handoff/current.md and emits a summary to the session.
# Non-interactive: never prompts. Silent on success when nothing to load.
# Bypass: DOTCLAUDE_HOOK_SESSION_START=0

set -eu

if [ "${DOTCLAUDE_HOOK_SESSION_START:-1}" = "0" ]; then
	exit 0
fi

HANDOFF="$HOME/.claude/handoff/current.md"

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

exit 0
