# MCP Servers — Inventory and Install Notes

Model Context Protocol (MCP) servers extend Claude Code with specialized
capabilities. This file documents which servers dotclaude registers and why.

Registration lives in `settings.json` `mcpServers`. Install via
`scripts/install-mcps.sh` or by manually adding entries.

## Default set

| Server | Package | Purpose | Required dep |
|--------|---------|---------|--------------|
| `playwright` | `@playwright/mcp` (Microsoft) | Browser automation: read pages, screenshots, form fill | Node + `npx` |
| `memory` | `mcp-memory-service` (doobidoo) | Cross-session knowledge graph; SQLite backend | `uv` (`uvx` runner) |
| `filesystem` | `@modelcontextprotocol/server-filesystem` (official) | Cross-project file access within scoped paths | Node |
| `github` | `@modelcontextprotocol/server-github` (official) | Issues, PRs, code search across repos | Node + GitHub PAT |

## Install

```bash
cd ~/.claude
./scripts/install-mcps.sh
```

Skip individual servers with env vars:

```bash
SKIP_PLAYWRIGHT=1 ./scripts/install-mcps.sh
SKIP_MEMORY=1 ./scripts/install-mcps.sh
SKIP_FILESYSTEM=1 ./scripts/install-mcps.sh
SKIP_GITHUB=1 ./scripts/install-mcps.sh
```

## Per-server notes

### playwright

- Persistent profile at `ms-playwright/mcp-{channel}-profile` (per-machine).
- Login state and cookies preserved between sessions.
- First launch downloads Chromium (~150 MB).

### memory (mcp-memory-service)

- SQLite db at `~/.claude/memory/db.sqlite` (gitignored).
- Has REST API + autonomous consolidation.
- Knowledge graph grows over time; consider `memory/synced/` for hand-curated
  insights and let the MCP handle dynamic queries.

### filesystem

- Default scope: `~/projects`, `~/anthill`, `~/zydrex`, `~/code`, `~/dev`
  (whatever exists on the machine at install time).
- Re-run install-mcps.sh or edit settings.json after creating new project dirs.
- The MCP enforces sandboxing — paths outside the allow-list are rejected.

### github

- Token via env var `GITHUB_TOKEN_DOTCLAUDE`. Set in `~/.bashrc` or `~/.zshrc`:
  ```bash
  export GITHUB_TOKEN_DOTCLAUDE="github_pat_..."
  ```
- Use a **fine-grained PAT** with read-only scope by default (issues, PRs,
  code). Add write only for repos you actively manage from the agent.
- `gh` CLI is the better choice for write actions; this MCP for queries.

## Adding a new server

1. Find the package on https://mcpservers.org or the official MCP catalog.
2. Add the entry to `settings.json` under `mcpServers`:
   ```json
   {
     "mcpServers": {
       "newserver": {
         "command": "npx",
         "args": ["-y", "@scope/package@latest"],
         "env": {}
       }
     }
   }
   ```
3. Reload Claude Code (close and reopen).
4. Run `./scripts/doctor.sh` to confirm.
5. Document in this file.

## Tool Search (Claude Code 2026 feature)

Claude Code's Tool Search lazy-loads MCP server tool schemas, reducing context
usage by ~95%. With it, you can register many MCPs without paying context for
all of them up front. Agents discover tools via `ToolSearch` when they need a
specific capability.

This means: prefer **registering more servers** than gating them, and let the
agent pull what it needs.

## Removing a server

```bash
# Edit settings.json, delete the entry under mcpServers
# Reload Claude Code
./scripts/doctor.sh
```

Or set the entry to `null` in `settings.local.json` to disable per-machine
without removing from the shared config.
