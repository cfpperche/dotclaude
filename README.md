# dotclaude

> Open-source portable Claude Code agent. Stack-aware, domain-agnostic,
> idempotent. Lives at `~/dotclaude/`, scoped to itself — never leaks into
> other projects.

> **Architecture note (2026-05-02):** dotclaude was originally designed as a
> drop-in replacement for `~/.claude/` (loaded globally in every session).
> That model leaked the dotclaude identity, skills, hooks and memory into
> every other project on the machine, conflicting with project-specific
> CLAUDE.md files. The repo now installs at `~/dotclaude/` instead, and is
> only active when the user opens a Claude Code session there
> (`cd ~/dotclaude && claude`). See `docs/MIGRATION-2026-05-02.md` for the
> full rationale and migration steps.

A personal assistant for [Claude Code](https://docs.claude.com/en/docs/claude-code/overview)
that lives in the user's home directory and works the same way across **WSL,
Linux, and macOS**. It's the "dotfiles for your AI agent": shareable,
versioned, portable.

**Profession-agnostic.** dotclaude doesn't assume you're a software
engineer. It works for anyone who has files on a computer:

- **Developers** — cross-repo work, git-aware, stack detection
- **Lawyers** — review contracts, compare drafts, track matters
- **Architects** — survey CAD revisions, draft specs alongside drawings
- **Researchers** — index notes, surface forgotten threads, cite sources
- **Writers** — manage manuscripts across folders, track revisions
- **Economists / analysts** — re-run models, update reports
- **Anyone else** — the agent adapts to what's in the folder

The two universal MCP servers (memory + filesystem) install for
everyone. Dev-leaning MCPs (playwright, github) are opt-in.

## What it gives you

- **Identity that follows you across machines** — global `CLAUDE.md` defines
  agent behavior; same on every machine you clone the repo on.
- **Cross-session memory** — institutional memory in `memory/synced/`
  (versioned) and `memory/local/` (per-machine).
- **Session handoffs** — `handoff/current.md` snapshots state at session
  end so the next session resumes fast.
- **MCP server inventory** — Playwright (browser), memory service,
  filesystem, GitHub, registered with one script.
- **Statusline** — model, project, branch, context bar, rate limits, cost,
  cache hit ratio, all in two compact lines.
- **Hooks** — session start/end automation, secret-scanning before commits.
- **Subagents** — cross-project explorer, handoff writer/reader (planned).
- **Doctor** — health check that catches missing deps, broken JSON, stale
  config.

## Why

Claude Code's `~/.claude/` accumulates state, settings, agents, skills,
hooks, and memory over time. By default this state is **per-machine and
ad-hoc**. dotclaude turns it into a **versioned, portable, reusable** thing
you can install on a fresh machine in 5 minutes.

It's also a starting point: fork it, rip out what you don't need, add what
you do. The agent itself is opinionated about hard rules (no auto-commit,
never touch credentials, never invent facts) but agnostic about your stack
and workflow.

## Install (new machine)

Requirements: `git`, `node`, `jq`, [`claude` CLI](https://docs.claude.com/en/docs/claude-code/setup).
Recommended: `gh`, `rg` (ripgrep), `uv` (`uvx`).

```bash
git clone https://github.com/cfpperche/dotclaude.git ~/.claude
cd ~/.claude
./scripts/install.sh
```

`install.sh` is idempotent — re-running it is safe. It checks dependencies,
creates `settings.local.json` from the template if missing, ensures cache
and memory directories exist, applies executable bits, and **optionally**
prompts to install MCP servers.

## Update

```bash
cd ~/.claude
./scripts/update.sh    # git pull --ff-only + re-apply perms + doctor
```

## Health check

```bash
~/.claude/scripts/doctor.sh
```

Reports OK / WARN / FAIL for: required commands, optional commands,
required files, JSON validity, layout, cache dir, MCP registration,
credentials presence, repo cleanliness.

## What is NOT in this repo

By design, the following are **per-machine** and live outside version control:

- `~/.claude/projects/` — auto-memory per cwd (can hit GBs, contains
  client-sensitive paths)
- `~/.claude/telemetry/`, `file-history/`, `history.jsonl` — session
  state and prompt history
- `~/.claude/plugins/` — plugin binaries
- `~/.claude/.credentials.json` — Claude auth token
- Anything matching `.gitignore`

## Multi-machine usage

| Concern | Strategy |
|---------|----------|
| Source-of-truth files (skills, agents, hooks) | `git pull` |
| Synced personal memory (`memory/synced/*.md`) | git, append-only with timestamped filenames |
| Local memory | not synced — per-machine context |
| Dynamic memory (queries, knowledge graph) | `mcp-memory-service` with SQLite at `~/.claude/memory/db.sqlite` (per-machine) |

For real cross-machine sync of dynamic memory, point the MCP service at a
shared backend (Postgres on a VPS, SQLite on a synced cloud drive, etc.).
The default is local SQLite to stay zero-config.

## Customization

- **Voice and preferences** — edit `CLAUDE.md`. Commit your changes.
- **Per-machine overrides** — copy `settings.local.json.example` to
  `settings.local.json` (gitignored). Override MCP env vars, paths, etc.
- **Add subagents** — drop markdown files in `agents/` with the [Claude
  Code agent frontmatter](https://docs.claude.com/en/docs/claude-code/sub-agents).
- **Add skills** — drop `SKILL.md` in `skills/<skill-name>/` with the
  [Skill spec](https://docs.claude.com/en/docs/claude-code/skills).
- **Add hooks** — drop bash files in `hooks/` and register matchers in
  `settings.json`.

## Layout

```
dotclaude/
├── CLAUDE.md              global agent identity, hard rules, scope
├── settings.json          shared config (theme, statusline, MCPs, hooks)
├── settings.local.json.example  per-machine override template
├── statusline.mjs         status bar renderer (Node)
├── keybindings.json       custom keybindings
├── agents/                subagents (project-scoped delegation)
├── skills/                slash commands available globally
├── hooks/                 PreToolUse / PostToolUse / SessionStart / Stop
├── commands/              legacy CLI utilities (optional)
├── memory/
│   ├── MEMORY.md          index of memories
│   ├── synced/            versioned cross-machine memory
│   └── local/             per-machine memory (gitignored)
├── handoff/
│   ├── current.md         latest session handoff
│   └── archive/           historical handoffs
├── mcp/README.md          MCP server inventory and install notes
├── scripts/
│   ├── install.sh         bootstrap on new machine
│   ├── doctor.sh          health check
│   ├── update.sh          git pull + reload
│   ├── install-mcps.sh    register default MCP set
│   └── memory-prune.sh    cleanup memory > N days
├── .github/
│   ├── workflows/lint.yml validate JSON/YAML/shellcheck/skill-frontmatter
│   └── ISSUE_TEMPLATE/    epic + task templates
└── .gitignore             aggressive — blocks all runtime state
```

## Idempotence

All scripts in `scripts/` are idempotent:

- `install.sh` — safe to re-run. Detects existing `settings.local.json`,
  existing dirs, existing executable bits.
- `install-mcps.sh` — re-registers MCP servers (overwriting entries by
  name) and creates a backup of `settings.json` per run. Old backups
  accumulate; clean periodically.
- `update.sh` — `git pull --ff-only`. Refuses to overwrite local changes.
- `doctor.sh` — read-only.
- `memory-prune.sh` — only deletes files older than `DAYS` env var
  (default 90); supports `DRY_RUN=1`.

## Hard rules the agent enforces

- Never `git add -A` / `.` / `git commit -a`.
- Never push without explicit confirmation.
- Never skip hooks (`--no-verify`).
- Never store credentials in commits or memory.
- Never edit a file without reading it first.
- Never invent APIs, paths, or facts. Says "uncertain" instead.

See `CLAUDE.md` for the full set.

## Context-awareness

The agent detects what kind of project it's in before suggesting commands
or patterns. Stack-awareness (language / package manager / build / test)
is one *case* — for code projects. For non-code projects (writing,
research, design, legal review) it adapts the conventions accordingly.
It won't run `npm` in a Python project, won't suggest `git commit` in a
folder that isn't a repo, won't assume "the test suite" exists. Detection
rules in `CLAUDE.md`.

## Autonomy

The agent acts autonomously by default. It only asks for confirmation
on two kinds of actions:

- **External-world actions** (visible to others): pushing, opening PRs,
  sending messages, deploying, spending money.
- **Authorization-required actions** (irreversible): `rm -rf`, force
  push, hard reset, dropping data, overwriting another machine's state.

For everything else (reading, editing, running tests, exploring,
managing memory, local commits), the agent decides and acts. See
`CLAUDE.md` for the full autonomy contract.

## Contributing

This is one user's personal agent shape, but the structure is reusable.
PRs welcome for:

- Stack detection improvements (more languages, more package managers).
- Cross-platform compatibility fixes (especially macOS / native Linux
  caveats).
- New idempotent scripts.
- New domain-agnostic skills/agents/hooks.

PRs **not welcome** for:

- Domain-specific or vendor-locked logic.
- Personal opinions hardcoded into agent behavior (those go in your fork).

See `CONTRIBUTING.md` for the full guide.

## License

[MIT](LICENSE).

## Acknowledgments

The statusline renderer is adapted from a private SDLC orchestrator's
status hook. The directory layout follows conventions from the broader
Claude Code community ([docs](https://code.claude.com/docs/en/claude-directory)).
MCP server set follows the official Anthropic recommendations as of
April 2026.
