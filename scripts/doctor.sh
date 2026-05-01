#!/usr/bin/env bash
# doctor.sh — health check for dotclaude installation.
#
# Reports OK/WARN/FAIL for each component. Exit 0 always (advisory).

set -u

DOTCLAUDE_DIR="$(cd "$(dirname "$0")/.." && pwd)"

green() { printf "\033[32m  ✓ %s\033[0m\n" "$*"; }
yellow() { printf "\033[33m  ⚠ %s\033[0m\n" "$*"; }
red() { printf "\033[31m  ✗ %s\033[0m\n" "$*"; }
header() { printf "\n\033[1m%s\033[0m\n" "$*"; }

OK=0
WARN=0
FAIL=0

check_pass() { green "$1"; OK=$((OK+1)); }
check_warn() { yellow "$1"; WARN=$((WARN+1)); }
check_fail() { red "$1"; FAIL=$((FAIL+1)); }

# --- Repo location ---
header "Repository"
if [ "$DOTCLAUDE_DIR" = "$HOME/.claude" ]; then
	check_pass "Installed at \$HOME/.claude (canonical location)"
else
	check_warn "Installed at $DOTCLAUDE_DIR (expected \$HOME/.claude)"
fi

# --- Required commands ---
header "Required commands"
for cmd in git node jq; do
	if command -v "$cmd" >/dev/null 2>&1; then
		check_pass "$cmd: $(command -v "$cmd")"
	else
		check_fail "$cmd: NOT FOUND"
	fi
done
if command -v claude >/dev/null 2>&1; then
	check_pass "claude: $(command -v claude)"
elif [ -x "$HOME/.claude/local/claude" ]; then
	check_warn "claude: $HOME/.claude/local/claude (add to PATH)"
else
	check_fail "claude: NOT FOUND"
fi

# --- Optional commands ---
header "Optional commands"
for cmd in gh rg uvx fzf; do
	if command -v "$cmd" >/dev/null 2>&1; then
		check_pass "$cmd: $(command -v "$cmd")"
	else
		check_warn "$cmd: not installed"
	fi
done

# --- Required files ---
header "Required files"
for f in CLAUDE.md settings.json statusline.mjs README.md; do
	if [ -f "$DOTCLAUDE_DIR/$f" ]; then
		check_pass "$f"
	else
		check_fail "$f: missing"
	fi
done

# --- settings.local.json ---
header "Local config"
if [ -f "$DOTCLAUDE_DIR/settings.local.json" ]; then
	if jq empty "$DOTCLAUDE_DIR/settings.local.json" 2>/dev/null; then
		check_pass "settings.local.json (valid JSON)"
	else
		check_fail "settings.local.json (INVALID JSON)"
	fi
else
	check_warn "settings.local.json: missing (run install.sh or copy from .example)"
fi

# --- settings.json validity ---
if jq empty "$DOTCLAUDE_DIR/settings.json" 2>/dev/null; then
	check_pass "settings.json (valid JSON)"
else
	check_fail "settings.json (INVALID JSON)"
fi

# --- Subdirectories ---
header "Layout"
for d in agents skills hooks commands memory/synced memory/local handoff/archive mcp scripts; do
	if [ -d "$DOTCLAUDE_DIR/$d" ]; then
		# skills convention is skills/<name>/SKILL.md — recurse for skills,
		# flat for everything else
		if [ "$d" = "skills" ]; then
			count=$(find "$DOTCLAUDE_DIR/$d" -mindepth 1 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')
			check_pass "$d ($count skills)"
		else
			count=$(find "$DOTCLAUDE_DIR/$d" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
			check_pass "$d ($count files)"
		fi
	else
		check_warn "$d: missing"
	fi
done

# --- Cache dir ---
header "Cache (~/.cache/dotclaude)"
if [ -d "$HOME/.cache/dotclaude/statusline" ]; then
	check_pass "statusline cache dir present"
else
	check_warn "statusline cache dir missing — will be created on first render"
fi

# --- MCP servers (best-effort detection) ---
header "MCP servers"
if grep -q '"mcpServers":\s*{}' "$DOTCLAUDE_DIR/settings.json" 2>/dev/null; then
	check_warn "no MCP servers registered (run scripts/install-mcps.sh to add)"
else
	mcp_count=$(jq -r '.mcpServers | length' "$DOTCLAUDE_DIR/settings.json" 2>/dev/null || echo "?")
	check_pass "$mcp_count MCP servers registered"
fi

# --- Credentials present (existence only — never read content) ---
header "Credentials"
if [ -f "$HOME/.claude/.credentials.json" ]; then
	check_pass ".credentials.json present (claude auth OK)"
else
	check_warn ".credentials.json missing — run 'claude login'"
fi

# --- Git status of dotclaude itself ---
header "Repo state"
if (cd "$DOTCLAUDE_DIR" && git rev-parse --git-dir >/dev/null 2>&1); then
	branch=$(cd "$DOTCLAUDE_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
	dirty=$(cd "$DOTCLAUDE_DIR" && git status --short 2>/dev/null | wc -l | tr -d ' ')
	if [ "$dirty" = "0" ]; then
		check_pass "git: clean tree on $branch"
	else
		check_warn "git: $dirty modified file(s) on $branch (run 'git status' to inspect)"
	fi
else
	check_warn "not a git repo (cloned correctly?)"
fi

# --- Summary ---
header "Summary"
green "OK:    $OK"
yellow "WARN:  $WARN"
red "FAIL:  $FAIL"
echo
if [ $FAIL -gt 0 ]; then
	red "Doctor reports failures. Address them before using the agent."
	exit 1
fi
exit 0
