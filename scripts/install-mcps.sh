#!/usr/bin/env bash
# install-mcps.sh — install + register the default MCP server set.
# Idempotent. Reads/writes settings.json. Skip individually with env vars.

set -euo pipefail

DOTCLAUDE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$DOTCLAUDE_DIR/settings.json"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }

if [ ! -f "$SETTINGS" ]; then
	red "settings.json not found at $SETTINGS"
	exit 1
fi

# Sanity: settings.json valid?
if ! jq empty "$SETTINGS" 2>/dev/null; then
	red "settings.json has invalid JSON. Aborting."
	exit 1
fi

# Backup
BACKUP="$SETTINGS.bak.$(date +%s)"
cp "$SETTINGS" "$BACKUP"
yellow "Backup at $BACKUP (delete after confirming new settings work)"

# --- Helpers ---
add_mcp() {
	local name="$1" json="$2"
	# shellcheck disable=SC2016
	local TMP
	TMP=$(mktemp)
	jq --arg n "$name" --argjson m "$json" '.mcpServers[$n] = $m' "$SETTINGS" > "$TMP"
	mv "$TMP" "$SETTINGS"
	green "  + $name registered in settings.json"
}

# --- 1. playwright (browser) ---
if [ "${SKIP_PLAYWRIGHT:-0}" != "1" ]; then
	green "Installing Playwright MCP..."
	if ! npx --yes @playwright/mcp@latest --version >/dev/null 2>&1; then
		yellow "  npx failed; check Node setup"
	fi
	add_mcp "playwright" '{
		"command": "npx",
		"args": ["-y", "@playwright/mcp@latest"]
	}'
fi

# --- 2. memory (cross-session knowledge graph) ---
if [ "${SKIP_MEMORY:-0}" != "1" ]; then
	green "Configuring mcp-memory-service..."
	if command -v uvx >/dev/null 2>&1; then
		add_mcp "memory" '{
			"command": "uvx",
			"args": ["mcp-memory-service"],
			"env": {
				"MEMORY_DB": "'"$HOME"'/.claude/memory/db.sqlite"
			}
		}'
	else
		yellow "  uvx not found — install uv first (https://docs.astral.sh/uv/). Skipping memory MCP."
	fi
fi

# --- 3. filesystem (cross-project read/write within allowed paths) ---
if [ "${SKIP_FILESYSTEM:-0}" != "1" ]; then
	green "Registering filesystem MCP (scope: ~/projects, ~/anthill, ~/zydrex if present)..."
	# Only include directories that exist on this machine
	PATHS=()
	for d in "$HOME/projects" "$HOME/anthill" "$HOME/zydrex" "$HOME/code" "$HOME/dev"; do
		[ -d "$d" ] && PATHS+=("$d")
	done
	if [ ${#PATHS[@]} -eq 0 ]; then
		yellow "  No project dirs detected. Edit settings.json to add paths."
		PATHS=("$HOME/projects")
	fi
	# Build args array as JSON
	ARGS_JSON=$(printf '%s\n' "-y" "@modelcontextprotocol/server-filesystem" "${PATHS[@]}" | jq -R . | jq -s .)
	add_mcp "filesystem" "$(jq -n --argjson a "$ARGS_JSON" '{
		command: "npx",
		args: $a
	}')"
fi

# --- 4. github (cross-repo issues, PRs, code search) ---
if [ "${SKIP_GITHUB:-0}" != "1" ]; then
	green "Registering GitHub MCP (token via env: GITHUB_TOKEN_DOTCLAUDE)..."
	add_mcp "github" '{
		"command": "npx",
		"args": ["-y", "@modelcontextprotocol/server-github"],
		"env": {
			"GITHUB_TOKEN": "${env:GITHUB_TOKEN_DOTCLAUDE}"
		}
	}'
	yellow "  Set GITHUB_TOKEN_DOTCLAUDE in ~/.bashrc / ~/.zshrc with a fine-grained PAT"
fi

green "==> MCP setup complete. Reload Claude Code to pick up new servers."
green "    Verify with: ./scripts/doctor.sh"
