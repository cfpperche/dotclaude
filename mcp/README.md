# MCP Servers — Inventory and Install Notes

Model Context Protocol (MCP) servers extend Claude Code with specialized
capabilities. This file documents which servers dotclaude registers and why.

Registration lives in `settings.json` under `mcpServers`. Install via
`scripts/install-mcps.sh` or by manually adding entries.

## Two tiers

dotclaude splits its default MCP set into:

- **Universal** — useful for any profession, default-on.
- **Dev-leaning** — opt-in during install (`INSTALL_DEV_MCPS=1` or
  answer `y` at the prompt). If you don't write code from this agent,
  you can skip these.

## Default set

| Server | Tier | Package | Purpose | Required dep |
|--------|------|---------|---------|--------------|
| `memory` | universal | `mcp-memory-service` (doobidoo) | Cross-session knowledge graph; SQLite backend | `uv` (`uvx` runner) |
| `filesystem` | universal | `@modelcontextprotocol/server-filesystem` (official) | Cross-project file access within scoped paths | Node |
| `playwright` | dev-leaning | `@playwright/mcp` (Microsoft) | Browser automation: read pages, screenshots, form fill | Node + `npx` |
| `github` | dev-leaning | `@modelcontextprotocol/server-github` (official) | Issues, PRs, code search across repos | Node + GitHub PAT |

> If you are not a developer, you only need **memory + filesystem**.
> The agent works fine without `playwright` and `github`.

## Install

```bash
cd ~/.claude
./scripts/install-mcps.sh
```

The script will prompt once whether to include dev MCPs. To skip the
prompt:

```bash
INSTALL_DEV_MCPS=0 ./scripts/install-mcps.sh    # universal only
INSTALL_DEV_MCPS=1 ./scripts/install-mcps.sh    # universal + dev
```

Skip individual servers entirely:

```bash
SKIP_MEMORY=1 ./scripts/install-mcps.sh
SKIP_FILESYSTEM=1 ./scripts/install-mcps.sh
SKIP_PLAYWRIGHT=1 ./scripts/install-mcps.sh
SKIP_GITHUB=1 ./scripts/install-mcps.sh
```

## Per-server notes

### memory (mcp-memory-service)

- SQLite db at `~/.claude/memory/db.sqlite` (gitignored).
- Has REST API + autonomous consolidation.
- Knowledge graph grows over time; consider `memory/synced/` for
  hand-curated insights and let the MCP handle dynamic queries.
- Universal — useful for any user (writer building a research index,
  lawyer tracking case context, dev tracking decisions across sessions).

### filesystem

- Default scope (only directories that exist at install time):
  `~/projects`, `~/work`, `~/code`, `~/dev`, `~/Documents`.
- Re-run `install-mcps.sh` or edit `settings.json` after creating new
  project dirs.
- The MCP enforces sandboxing — paths outside the allow-list are
  rejected.
- Universal — useful for any kind of project folder.

### playwright

- Persistent profile at `ms-playwright/mcp-{channel}-profile`
  (per-machine).
- Login state and cookies preserved between sessions.
- First launch downloads Chromium (~150 MB).
- Dev-leaning, but also useful for non-devs (research, web archiving,
  scraping public data).

### github

- Token via env var `GITHUB_TOKEN_DOTCLAUDE`. Set in `~/.bashrc` or
  `~/.zshrc`:
  ```bash
  export GITHUB_TOKEN_DOTCLAUDE="github_pat_..."
  ```
- Use a **fine-grained PAT** with read-only scope by default (issues,
  PRs, code). Add write only for repos you actively manage from the
  agent.
- `gh` CLI is the better choice for write actions; this MCP is for
  queries.
- Dev-leaning — for users who work across GitHub repos.

## Adding a new server

1. Find the package on https://mcpservers.org or the official MCP
   catalog.
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

## Tool Search (Claude Code 2026)

Claude Code's Tool Search lazy-loads MCP server tool schemas, reducing
context usage. With it, you can register many MCPs without paying
context for all of them up front. Agents discover tools via
`ToolSearch` when they need a specific capability.

This means: prefer **registering more servers** than gating them, and
let the agent pull what it needs.

## Removing a server

Edit `settings.json`, delete the entry under `mcpServers`, reload
Claude Code.

```bash
./scripts/doctor.sh
```

Or set the entry to `null` in `settings.local.json` to disable
per-machine without removing from the shared config.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `memory` doesn't load | `uvx` not on PATH | Install `uv` (https://docs.astral.sh/uv/) |
| `filesystem` rejects paths | Path outside allow-list | Edit `settings.json` `mcpServers.filesystem.args` to include the path |
| `playwright` first call hangs | Chromium download in progress | Wait — ~150 MB on first launch |
| `github` 401 / 403 | Missing or expired PAT | Re-export `GITHUB_TOKEN_DOTCLAUDE` and reload Claude Code |
| Server registered but tools missing | Claude Code session needs reload | Close and reopen the session |
