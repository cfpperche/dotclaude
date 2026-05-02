#!/usr/bin/env bash
# install.sh — bootstrap dotclaude on a new machine.
#
# Usage:
#   git clone git@github.com:cfpperche/dotclaude.git ~/dotclaude
#   cd ~/dotclaude
#   ./scripts/install.sh
#
# Note: dotclaude installs at ~/dotclaude/ (not ~/.claude/) since 2026-05-02.
# Opening Claude Code in ~/dotclaude/ activates the assistant; opening it
# anywhere else leaves it dormant. See docs/MIGRATION-2026-05-02.md.

set -euo pipefail

DOTCLAUDE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DOTCLAUDE_DIR"

green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }
dim() { printf "\033[2m%s\033[0m\n" "$*"; }

green "==> dotclaude install"
echo "Repo: $DOTCLAUDE_DIR"
echo

# --- 1. Required dependencies ---
echo "Checking required dependencies..."
MISSING=()
for cmd in git node jq; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		MISSING+=("$cmd")
	fi
done

# claude CLI is required but special — try multiple install paths
if ! command -v claude >/dev/null 2>&1; then
	if [ -x "$HOME/.claude/local/claude" ]; then
		dim "  claude CLI found at ~/.claude/local/claude (add to PATH)"
	else
		MISSING+=("claude")
	fi
fi

if [ ${#MISSING[@]} -gt 0 ]; then
	red "Missing required: ${MISSING[*]}"
	echo "Install via:"
	for m in "${MISSING[@]}"; do
		case "$m" in
			git) echo "  git: https://git-scm.com/" ;;
			node) echo "  node: https://nodejs.org/ or via fnm/nvm" ;;
			jq) echo "  jq: apt install jq | brew install jq" ;;
			claude) echo "  claude: https://docs.claude.com/en/docs/claude-code/setup" ;;
		esac
	done
	exit 1
fi
green "  ✓ git, node, jq, claude available"

# --- 2. Optional but recommended ---
echo
echo "Checking optional dependencies..."
OPTIONAL_MISSING=()
for cmd in gh rg uvx; do
	if ! command -v "$cmd" >/dev/null 2>&1; then
		OPTIONAL_MISSING+=("$cmd")
	fi
done
if [ ${#OPTIONAL_MISSING[@]} -gt 0 ]; then
	yellow "  Missing (recommended): ${OPTIONAL_MISSING[*]}"
	echo "    gh:   GitHub CLI for cross-repo work"
	echo "    rg:   ripgrep, faster than grep"
	echo "    uvx:  uv (Python tool runner) — required for some MCPs"
else
	green "  ✓ gh, rg, uvx available"
fi

# --- 3. settings.local.json ---
echo
if [ ! -f "$DOTCLAUDE_DIR/settings.local.json" ]; then
	echo "Creating settings.local.json from template..."
	cp "$DOTCLAUDE_DIR/settings.local.json.example" "$DOTCLAUDE_DIR/settings.local.json"
	green "  ✓ settings.local.json created — edit with machine-specific overrides"
else
	dim "  settings.local.json already exists"
fi

# --- 4. memory directories ---
echo
mkdir -p "$DOTCLAUDE_DIR/memory/local" "$DOTCLAUDE_DIR/memory/synced"
mkdir -p "$DOTCLAUDE_DIR/handoff/archive"
green "  ✓ memory/, handoff/ subdirs ensured"

# --- 5. cache dir for statusline ---
mkdir -p "$HOME/.cache/dotclaude/statusline/tokens" "$HOME/.cache/dotclaude/statusline/context-markers"
green "  ✓ ~/.cache/dotclaude/ created"

# --- 6. permissions on hooks and scripts ---
echo
find "$DOTCLAUDE_DIR/hooks" -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
find "$DOTCLAUDE_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
chmod +x "$DOTCLAUDE_DIR/statusline.mjs" 2>/dev/null || true
green "  ✓ scripts and hooks executable"

# --- 7. MCP servers (interactive prompt; auto-skip in non-TTY) ---
echo
if [ -t 0 ] && [ "${DOTCLAUDE_NONINTERACTIVE:-0}" != "1" ]; then
	yellow "Optional: install MCP servers?"
	echo "  These extend Claude Code with browser, memory, filesystem, GitHub tools."
	echo "  See mcp/README.md for the full list. Skip with Ctrl+C; rerun later."
	echo
	read -rp "Install playwright + memory + filesystem + github MCPs? [y/N] " REPLY
	echo
	if [[ "$REPLY" =~ ^[Yy]$ ]]; then
		bash "$DOTCLAUDE_DIR/scripts/install-mcps.sh" || yellow "MCP install had errors — check output"
	else
		dim "  Skipped. Run ./scripts/install-mcps.sh anytime."
	fi
else
	dim "  Non-interactive shell — skipping MCP install prompt."
	dim "  Run ./scripts/install-mcps.sh manually when ready."
fi

# --- 8. doctor ---
echo
green "==> Running doctor.sh"
bash "$DOTCLAUDE_DIR/scripts/doctor.sh"

echo
green "==> Install complete"
echo "Next:"
echo "  1. Edit settings.local.json with machine-specific overrides if needed"
echo "  2. Open a new Claude Code session and verify the statusline"
echo "  3. Read CLAUDE.md to understand the agent's behavior"
