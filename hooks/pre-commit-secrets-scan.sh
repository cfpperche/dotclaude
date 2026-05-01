#!/usr/bin/env bash
# pre-commit-secrets-scan.sh — PreToolUse(Bash) hook, filtered to `git commit`.
# Scans staged files for likely secrets. Block (exit 2) on detection.
# Non-interactive: never prompts. The decision is automated.
# Bypass: DOTCLAUDE_HOOK_SECRETS_SCAN=0

set -eu

if [ "${DOTCLAUDE_HOOK_SECRETS_SCAN:-1}" = "0" ]; then
	exit 0
fi

# Read tool input from stdin (Claude Code passes hook input as JSON)
# We only care about Bash tool calls that contain `git commit`
INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null || echo "")

case "$COMMAND" in
	*"git commit"*) ;;
	*) exit 0 ;;
esac

# Are we in a git repo?
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	exit 0
fi

# Get staged content (added lines only)
DIFF=$(git diff --cached --no-color 2>/dev/null || echo "")
if [ -z "$DIFF" ]; then
	exit 0
fi

# Patterns we refuse to commit. Conservative — favor false positives
# over leaking. The user can bypass with DOTCLAUDE_HOOK_SECRETS_SCAN=0.
PATTERNS=(
	'AKIA[0-9A-Z]{16}'                          # AWS access key id
	'aws_secret_access_key[[:space:]]*=[[:space:]]*[A-Za-z0-9/+=]{40}'
	'github_pat_[A-Za-z0-9_]{20,}'              # GitHub fine-grained PAT
	'ghp_[A-Za-z0-9]{30,}'                      # GitHub classic PAT
	'gho_[A-Za-z0-9]{30,}'                      # GitHub OAuth
	'glpat-[A-Za-z0-9_-]{20,}'                  # GitLab PAT
	'sk-[A-Za-z0-9]{32,}'                       # OpenAI / Anthropic-style
	'sk-ant-[A-Za-z0-9_-]{20,}'                 # Anthropic API key
	'-----BEGIN [A-Z ]*PRIVATE KEY-----'         # PEM private key
	'eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.'    # JWT
	'xox[baprs]-[A-Za-z0-9-]{10,}'              # Slack tokens
	'AIza[0-9A-Za-z_-]{35}'                     # Google API key
)

ADDED_LINES=$(printf '%s' "$DIFF" | grep -E '^\+' | grep -vE '^\+\+\+' || echo "")

HITS=()
for pat in "${PATTERNS[@]}"; do
	if printf '%s' "$ADDED_LINES" | grep -qE "$pat"; then
		HITS+=("$pat")
	fi
done

if [ "${#HITS[@]}" -gt 0 ]; then
	{
		echo "[secrets-scan] BLOCKED — staged content matches secret patterns:"
		for p in "${HITS[@]}"; do
			echo "  - $p"
		done
		echo
		echo "Remove the offending lines and re-stage. To bypass once:"
		echo "  DOTCLAUDE_HOOK_SECRETS_SCAN=0 git commit ..."
	} >&2
	exit 2
fi

exit 0
