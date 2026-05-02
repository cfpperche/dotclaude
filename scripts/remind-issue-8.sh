#!/usr/bin/env bash
# remind-issue-8.sh — one-shot local reminder for dotclaude issue #8.
#
# Set 2026-05-01. Fires when both:
#   - today >= TARGET_DATE
#   - GitHub issue #8 in cfpperche/dotclaude is still OPEN
#
# Idempotent: writes a marker file at $REMINDER_FILE; subsequent runs see
# the marker and exit. If the issue is closed, the marker is cleaned up.
# Surfaced to the agent by hooks/session-start-load-handoff.sh.
#
# Schedule: cron line `0 9 15 5 *` (May 15, 09:00). Cron entry can be
# removed by hand once the marker fires or the issue is resolved.

set -eu

TARGET_DATE="2026-05-15"
REPO="cfpperche/dotclaude"
ISSUE=8
REMINDER_DIR="$HOME/.claude/handoff/reminders"
REMINDER_FILE="$REMINDER_DIR/issue-${ISSUE}-multi-machine.md"

TODAY="$(date +%Y-%m-%d)"

# Date guard: only act on or after the target date.
if [ "$TODAY" \< "$TARGET_DATE" ]; then
	exit 0
fi

# Network guard: gh must be installed and authenticated.
if ! command -v gh >/dev/null 2>&1; then
	exit 0
fi

STATE="$(gh issue view "$ISSUE" -R "$REPO" --json state -q .state 2>/dev/null || echo "UNKNOWN")"

case "$STATE" in
	OPEN)
		mkdir -p "$REMINDER_DIR"
		cat > "$REMINDER_FILE" <<EOF
# Reminder — issue #${ISSUE} still open

Set: 2026-05-01
Fired: ${TODAY}
URL: https://github.com/${REPO}/issues/${ISSUE}

The multi-machine validation is still pending. Acceptance:

- clone \`git@github.com:${REPO}.git\` into a second machine's \`~/.claude/\`
- run \`scripts/install.sh\`
- verify \`scripts/doctor.sh\` passes
- sync-test memory: write a file in \`memory/synced/\` on machine A,
  push, pull on machine B, verify it appears

Action: either run the validation, or close the issue if no longer
relevant. Once the issue is closed this reminder will self-clean on
the next cron run.
EOF
		;;
	CLOSED)
		# Issue already done — clean up any stale marker.
		[ -f "$REMINDER_FILE" ] && rm -f "$REMINDER_FILE"
		;;
	*)
		# UNKNOWN (network failure, auth issue, repo gone) — do nothing,
		# don't clobber an existing marker.
		exit 0
		;;
esac

exit 0
