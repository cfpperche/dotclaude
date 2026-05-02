---
title: dotclaude migration — `~/.claude/` → `~/dotclaude/`
date: 2026-05-02
author: cfpperche
---

# Migration: dotclaude moves out of `~/.claude/`

## Problem

dotclaude was originally designed as a "drop-in for `~/.claude/`" — clone
the repo into Claude Code's user-config directory, ship a `CLAUDE.md`,
hooks, skills, agents and memory there, and have them apply to **every**
Claude Code session on the machine.

That model leaked. Concretely:

- The `~/.claude/CLAUDE.md` (10.6 KB, with identity "I am personal
  assistant from home directory") loaded into the system prompt of every
  session, **including** sessions in projects with their own personas
  (e.g., `~/anthill/` declares "you are co-founder, 50/50 partner"). The
  two identities collided.
- The 4 skills (`btw`, `handoff`, `projects-status`, `voice`) and
  3 subagents (`cross-project-explorer`, `handoff-{reader,writer}`)
  appeared in every project's available-skills list — visual pollution
  even when not invoked.
- The 3 hooks (`SessionStart`, `Stop`, `PreToolUse(Bash)`) ran on every
  session in every project. One had a path guard
  (`session-start-load-handoff`), one had no guard at all
  (`session-end-write-handoff` would touch `.last-session-end` in any
  project), and one was identity-free defensive (`pre-commit-secrets-scan`).
- The custom `memory/MEMORY.md` (referenced by the global `CLAUDE.md`)
  loaded dotclaude-specific notes into every unrelated session.

In short: a "personal assistant" that polluted every other agent's
context.

## Decision

Move the dotclaude project out of `~/.claude/` and into its own
project directory at `~/dotclaude/`. Open Claude Code there
(`cd ~/dotclaude && claude`) to activate the assistant. Anywhere else,
dotclaude is invisible.

`~/.claude/` is reduced to:

- `statusline.mjs` location is now `~/dotclaude/statusline.mjs`; the
  global `settings.json` references it via absolute path
- `settings.json` — minimal: `theme`, `statusLine`,
  `permissions.defaultMode`, plus a defensive PreToolUse
  `pre-commit-secrets-scan.sh` that has no identity and is safe to run
  anywhere
- `settings.local.json` — minimal per-machine overrides
- `CLAUDE.md` — minimal, ~30 lines, no identity, just hard safety rules
  and tone (compatible with any project persona)
- runtime dirs (`projects/`, `sessions/`, `tasks/`, `todos/`,
  `telemetry/`, `plugins/`, etc.) — Claude Code-managed, untouched

Everything else lives in `~/dotclaude/` and is only loaded when the
user works inside that directory.

## What was moved

| Old location | New location |
|---|---|
| `~/.claude/CLAUDE.md` | `~/dotclaude/.claude/CLAUDE.md` |
| `~/.claude/skills/{btw,handoff,projects-status,voice}/` | `~/dotclaude/.claude/skills/...` |
| `~/.claude/agents/{cross-project-explorer,handoff-reader,handoff-writer}.md` | `~/dotclaude/.claude/agents/...` |
| `~/.claude/hooks/{session-start-load-handoff,session-end-write-handoff,pre-commit-secrets-scan}.sh` | `~/dotclaude/.claude/hooks/...` |
| `~/.claude/memory/MEMORY.md` + entries | `~/dotclaude/memory/...` |
| `~/.claude/handoff/current.md` + archive | `~/dotclaude/handoff/...` |
| `~/.claude/scripts/`, `docs/`, `mcp/`, `.github/`, `LICENSE`, `README.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.gitignore` | `~/dotclaude/...` |
| `~/.claude/.git/` | `~/dotclaude/.git/` |
| `~/.claude/statusline.mjs` | `~/dotclaude/statusline.mjs` |
| `~/.claude/keybindings.json` | `~/dotclaude/keybindings.json` |
| `~/.claude/settings.json` (original) | `~/dotclaude/.claude/settings.json` (with adapted hook paths) |

## What was adapted

- **Hooks** — `session-start-load-handoff.sh` and
  `session-end-write-handoff.sh` had their guards updated from
  `~/.claude` to `~/dotclaude` and their paths to handoff/reminders
  rewritten accordingly. `pre-commit-secrets-scan.sh` had no path-bound
  state and was unchanged.
- **`session-end-write-handoff.sh`** got the project-scope guard it
  was missing — it now exits silently when the cwd isn't `~/dotclaude/`.
- **`.claude/settings.json`** in dotclaude rewrites hook paths from
  `$HOME/.claude/hooks/...` to `$CLAUDE_PROJECT_DIR/.claude/hooks/...`
  and the statusline command to `node $CLAUDE_PROJECT_DIR/statusline.mjs`,
  so the project is fully relocatable.
- **`CLAUDE.md`** in dotclaude was updated: identity is now scoped
  ("personal assistant scoped to the `~/dotclaude/` project") and the
  framing ("shared across every project") was inverted ("only loaded
  when the working directory is `~/dotclaude/`").
- **`README.md`** got a top-of-file note explaining the new
  architecture and pointing here.
- **`scripts/install.sh`** updated to clone into `~/dotclaude/` instead
  of `~/.claude/`.

## What was preserved in the global `~/.claude/`

After migration, `~/.claude/` holds only what is universally useful:

- `CLAUDE.md` — minimal, ~30 lines, no identity, just hard safety rules
  (no `git add -A`, no `--no-verify`, no committing `.env`) and tone.
  Compatible with any project persona.
- `hooks/pre-commit-secrets-scan.sh` — defensive, identity-free copy of
  the dotclaude version. Blocks staging of obvious secret patterns in
  any project on the machine.
- `settings.json` — wires the secrets-scan hook + statusline; nothing
  else.

## Verifying the migration

From any non-dotclaude directory (e.g., `~/anthill/` or `~/twinr/`),
opening Claude Code should show:

- No `[btw]`, `/handoff`, `/voice`, `/projects-status` skills
- No `cross-project-explorer`, `handoff-reader`, `handoff-writer`
  subagents
- No "I am personal assistant" identity in the system prompt
- The minimal global `CLAUDE.md` (hard rules only) loaded
- The PreToolUse secrets-scan hook still active (defensive)
- Statusline still rendering (points to `~/dotclaude/statusline.mjs`)

From `cd ~/dotclaude && claude`:

- All four dotclaude skills available
- All three subagents available
- The full identity-bearing `CLAUDE.md` loaded
- All three hooks (SessionStart load handoff, Stop write marker,
  PreToolUse secrets-scan) active

## Reversal

The migration is mechanical — to undo:

```bash
# move the project back into ~/.claude/
mv ~/dotclaude/.claude/CLAUDE.md ~/.claude/
mv ~/dotclaude/.claude/skills ~/.claude/
mv ~/dotclaude/.claude/agents ~/.claude/
mv ~/dotclaude/.claude/hooks ~/.claude/
mv ~/dotclaude/memory ~/.claude/
mv ~/dotclaude/handoff ~/.claude/
mv ~/dotclaude/.git ~/.claude/
mv ~/dotclaude/{README,CONTRIBUTING,CODE_OF_CONDUCT}.md ~/.claude/
mv ~/dotclaude/LICENSE ~/.claude/
mv ~/dotclaude/.gitignore ~/.claude/
mv ~/dotclaude/.github ~/.claude/
mv ~/dotclaude/scripts ~/.claude/
mv ~/dotclaude/docs ~/.claude/
mv ~/dotclaude/mcp ~/.claude/
mv ~/dotclaude/statusline.mjs ~/.claude/
mv ~/dotclaude/keybindings.json ~/.claude/
mv ~/dotclaude/.claude/settings.json ~/.claude/settings.json
mv ~/dotclaude/.claude/settings.local.json ~/.claude/settings.local.json
rmdir ~/dotclaude/.claude
rmdir ~/dotclaude

# revert the hook paths and CLAUDE.md edits — see git history for the diff
cd ~/.claude && git diff HEAD~ HEAD
```

The `~/.claude/.git/` history (now at `~/dotclaude/.git/`) preserves
every commit prior to migration, so any rollback target is reachable.

## Lessons / design notes for the next iteration

If a "global personal assistant" is rebuilt later, the cleanest paths
documented at migration time are:

1. **Identity belongs to the project, not the global.** Don't put
   "I am personal assistant" or any persona in `~/.claude/CLAUDE.md`.
   Personas conflict with project CLAUDE.md (anthill = "co-founder",
   others = ?).
2. **Skills/agents that only matter inside dotclaude itself** should
   live in `~/dotclaude/.claude/`, not in `~/.claude/`. Open `claude`
   from `~/dotclaude/` to get them.
3. **Hooks meant only for the dotclaude workspace** must guard on
   `CLAUDE_PROJECT_DIR`. The pattern is documented in
   `.claude/hooks/session-start-load-handoff.sh`.
4. **What truly belongs in global** (`~/.claude/`): hard safety rules
   (no `git add -A`, no `--no-verify`), defensive PreToolUse scans
   (secrets, destructive commands), tone preferences. **Nothing
   identity-bearing, nothing project-specific.**
5. **Plugin mode (alternative)** — for distribution, dotclaude could
   ship as a Claude Code plugin (`.claude-plugin/plugin.json` +
   `marketplace.json`) and be enabled per-project via `enabledPlugins`.
   Keeps the project-scoped behavior of the current architecture while
   adding opt-in activation. Not implemented yet — see the research
   notes in the 2026-05-02 conversation log.
