#!/usr/bin/env bash
# memory-prune.sh — cleanup memory/local entries older than N days.
# Synced memory (memory/synced/) is NOT pruned automatically; manage in git.
#
# Usage:
#   ./scripts/memory-prune.sh           # default: 90 days
#   DAYS=30 ./scripts/memory-prune.sh   # custom threshold
#   DRY_RUN=1 ./scripts/memory-prune.sh # show what would be deleted

set -u

DOTCLAUDE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DAYS="${DAYS:-90}"
DRY_RUN="${DRY_RUN:-0}"

LOCAL_DIR="$DOTCLAUDE_DIR/memory/local"
ARCHIVE_DIR="$DOTCLAUDE_DIR/handoff/archive"

if [ ! -d "$LOCAL_DIR" ]; then
	echo "memory/local/ not found — nothing to prune"
	exit 0
fi

count_local=0
count_handoff=0

# Prune memory/local older than DAYS
while IFS= read -r f; do
	if [ "$DRY_RUN" = "1" ]; then
		echo "[DRY] would delete: $f"
	else
		rm "$f"
	fi
	count_local=$((count_local+1))
done < <(find "$LOCAL_DIR" -type f -mtime "+$DAYS" 2>/dev/null)

# Prune handoff archive older than DAYS
if [ -d "$ARCHIVE_DIR" ]; then
	while IFS= read -r f; do
		if [ "$DRY_RUN" = "1" ]; then
			echo "[DRY] would delete: $f"
		else
			rm "$f"
		fi
		count_handoff=$((count_handoff+1))
	done < <(find "$ARCHIVE_DIR" -type f -mtime "+$DAYS" 2>/dev/null)
fi

if [ "$DRY_RUN" = "1" ]; then
	echo "Would prune: $count_local memory/local + $count_handoff handoff/archive (>$DAYS days)"
else
	echo "Pruned: $count_local memory/local + $count_handoff handoff/archive (>$DAYS days)"
fi
