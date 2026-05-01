#!/usr/bin/env bash
# install-mcps.sh — register the default MCP server set.
# Idempotent. Reads/writes settings.json.
#
# MCPs split into:
#   Universal (default-on)  : memory, filesystem
#   Dev-leaning (opt-in)    : playwright, github
#
# Skip individually with env vars:
#   SKIP_MEMORY=1 SKIP_FILESYSTEM=1 SKIP_PLAYWRIGHT=1 SKIP_GITHUB=1
#
# Force include dev MCPs without prompt:
#   INSTALL_DEV_MCPS=1
#
# Force skip the prompt and exclude dev MCPs:
#   INSTALL_DEV_MCPS=0

set -euo pipefail

DOTCLAUDE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SETTINGS="$DOTCLAUDE_DIR/settings.json"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }
dim() { printf "\033[2m%s\033[0m\n" "$*"; }

if [ ! -f "$SETTINGS" ]; then
	red "settings.json not found at $SETTINGS"
	exit 1
fi

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
	local TMP
	TMP=$(mktemp)
	jq --arg n "$name" --argjson m "$json" '.mcpServers[$n] = $m' "$SETTINGS" > "$TMP"
	mv "$TMP" "$SETTINGS"
	green "  + $name registered in settings.json"
}

# --- Decide dev MCPs ---
INSTALL_DEV="${INSTALL_DEV_MCPS:-}"
if [ -z "$INSTALL_DEV" ]; then
	if [ -t 0 ] && [ "${DOTCLAUDE_NONINTERACTIVE:-0}" != "1" ]; then
		echo
		yellow "Optional: install dev-focused MCPs?"
		echo "  - playwright: browser automation (~150 MB Chromium download)"
		echo "  - github:     issues/PRs across repos (needs GitHub PAT)"
		echo "  Skip these if you don't write code from this agent."
		read -rp "Install dev MCPs? [y/N] " REPLY
		case "$REPLY" in
			[Yy]*) INSTALL_DEV=1 ;;
			*)     INSTALL_DEV=0 ;;
		esac
	else
		INSTALL_DEV=0
		dim "Non-interactive — defaulting to universal MCPs only."
	fi
fi

echo

# ============================================================
# UNIVERSAL MCPs — useful for any profession
# ============================================================

# --- memory (cross-session knowledge graph) ---
if [ "${SKIP_MEMORY:-0}" != "1" ]; then
	green "Configuring mcp-memory-service (universal)..."
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

# --- filesystem (cross-project read/write within allowed paths) ---
if [ "${SKIP_FILESYSTEM:-0}" != "1" ]; then
	green "Registering filesystem MCP (universal)..."
	# Detect project roots that exist on this machine.
	# Generic conventions only — no user-specific paths shipped.
	PATHS=()
	for d in "$HOME/projects" "$HOME/work" "$HOME/code" "$HOME/dev" "$HOME/Documents"; do
		[ -d "$d" ] && PATHS+=("$d")
	done
	if [ ${#PATHS[@]} -eq 0 ]; then
		yellow "  No standard project dirs detected. Defaulting to ~/projects (will create on first write)."
		PATHS=("$HOME/projects")
	fi
	dim "  Scoped to: ${PATHS[*]}"
	dim "  Edit settings.json to add or remove paths after install."
	ARGS_JSON=$(printf '%s\n' "-y" "@modelcontextprotocol/server-filesystem" "${PATHS[@]}" | jq -R . | jq -s .)
	add_mcp "filesystem" "$(jq -n --argjson a "$ARGS_JSON" '{
		command: "npx",
		args: $a
	}')"
fi

# ============================================================
# DEV-LEANING MCPs — opt-in
# ============================================================

if [ "$INSTALL_DEV" = "1" ]; then
	echo

	# --- playwright (browser) ---
	if [ "${SKIP_PLAYWRIGHT:-0}" != "1" ]; then
		green "Installing Playwright MCP (dev)..."
		if ! npx --yes @playwright/mcp@latest --version >/dev/null 2>&1; then
			yellow "  npx test failed; check Node setup"
		fi
		add_mcp "playwright" '{
			"command": "npx",
			"args": ["-y", "@playwright/mcp@latest"]
		}'
	fi

	# --- github (cross-repo issues, PRs, code search) ---
	if [ "${SKIP_GITHUB:-0}" != "1" ]; then
		green "Registering GitHub MCP (dev) — token via env: GITHUB_TOKEN_DOTCLAUDE..."
		add_mcp "github" '{
			"command": "npx",
			"args": ["-y", "@modelcontextprotocol/server-github"],
			"env": {
				"GITHUB_TOKEN": "${env:GITHUB_TOKEN_DOTCLAUDE}"
			}
		}'
		yellow "  Set GITHUB_TOKEN_DOTCLAUDE in ~/.bashrc / ~/.zshrc with a fine-grained PAT."
		yellow "  Default scope: read-only (issues, PRs, code). See mcp/README.md."
	fi
else
	dim "Skipping dev MCPs (playwright, github)."
	dim "Re-run with INSTALL_DEV_MCPS=1 ./scripts/install-mcps.sh to add them later."
fi

echo
green "==> MCP setup complete. Reload Claude Code to pick up new servers."
green "    Verify with: ./scripts/doctor.sh"
