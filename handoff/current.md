---
session_id: 2026-05-01T23:00-03:00
timestamp: 2026-05-01 21:55 -03
status: active
project: dotclaude (~/.claude + github.com/cfpperche/dotclaude)
---

# Handoff — Ship dotclaude scaffold, cutover, and validation

## What was done

- **Issues #1–#7 closed** in `cfpperche/dotclaude` via 8 commits
  (`8ae3308` → `734e942`).
  - #1 CLAUDE.md autonomy principle + profession-agnostic identity (`bdae431`)
  - #2 Three subagents in `agents/` (`8ae3308`)
  - #3+#6 Four skills in `skills/` (`6c11934`)
  - #4 Three hooks + `settings.json` registration (`ffb91b9`)
  - #5 MCP universal/dev split with opt-in prompt (`55eac6f`)
  - #7 Cutover (no commit — local-only)
  - Bonus fixes: doctor.sh skill counting (`602316a`), update.sh
    untracked-tolerance (`0a61aa9` + `8c4027b`), settings.json $schema
    URL (`734e942`).
- **Cutover executed** on 2026-05-01 ~20:37 -03. Backup at
  `~/dotclaude-pre-cutover-20260501-203725/` (2.6 GB, full snapshot).
  Strategy: rsync without `--delete` so runtime state (projects/,
  telemetry/, todos/, history.jsonl, .credentials.json, plugins/) is
  preserved automatically. User customizations from prior settings.json
  migrated to `~/.claude/settings.local.json` (gitignored).
- **Cron armed** for weekly `update.sh`: `0 9 * * 1` local time, log to
  `/tmp/dotclaude-update.log`. Next run: Mon 2026-05-04 09:00 -03.
- **Validation session** at `1af6c1ce-edcb-4e29-80cc-54b6f2162a2c.jsonl`
  (renamed `claude-code-intro-pt`) confirmed: bootstrap clean, 4 skills
  loaded, stop hook runs in 23ms, CLAUDE.md being followed (pt-BR, terse,
  autonomy contract).

## What's pending

- **#8 Multi-machine validation** — manual; requires a second machine
  (other WSL/Linux/macOS box). Acceptance: clone
  `git@github.com:cfpperche/dotclaude.git` into that machine's
  `~/.claude/`, run `scripts/install.sh`, verify doctor passes,
  sync-test memory write A → read B via git pull. Per ADR 0001,
  validation only covers the **markdown layer** (`memory/synced/`),
  not the SQLite working-memory cache.

## Resolved this session (2026-05-01 ~21:50 -03)

- **gitignore**: added `handoff/.*` so `.last-session-end` (and any
  future hook-generated dotfiles in handoff/) stay out of the repo.
  Committed as `be7c1bb`.
- **/tmp/dotclaude-init/ references**: searched repo, shell rc files,
  crontab, systemd user units. **No references** outside of this
  handoff itself. Safe to lose on next reboot.
- **Memory sync backend**: decided **local-only / two-tier** (markdown
  in repo, SQLite per-machine). Documented in
  `docs/decisions/0001-memory-sync-strategy.md`. Decision section
  below preserves the "don't revisit" record.

## Active context

dotclaude is a public OSS portable Claude Code agent at
`github.com/cfpperche/dotclaude` (MIT). It's profession-agnostic, not
just for devs. The agent acts autonomously on local-reversible work and
only asks for confirmation on external (push, send, deploy) or
authorization-required (rm -rf, force push, drop) actions.

Working directories:
- `/home/goat/.claude/` — live install, git clone of cfpperche/dotclaude,
  branch `main`, clean tree.
- `/tmp/dotclaude-init/` — original scaffolding clone, tmpfs. Confirmed
  no external references (cron, shell rc, systemd). Safe to lose on
  next WSL reboot.

Cron is the local-fallback for `update.sh`. /schedule (remote agents) was
considered but doesn't fit because remote agents can't run local scripts
on `~/.claude/`.

## Open questions

(none — all three from prior session resolved; see "Resolved this
session" above.)

## Decisions taken (don't revisit)

- Repo public + MIT license.
- Profession-agnostic shipped identity; no personal voice hardcoded.
- Two-tier MCP set: universal (memory + filesystem) on by default;
  dev-leaning (playwright + github) opt-in.
- Hooks are non-interactive by design (autonomy principle: hooks
  decide, don't prompt).
- Cutover via rsync without `--delete` (preserves runtime state without
  needing an explicit preserve list).
- Cron > /schedule for local update.sh (remote agents can't touch
  local filesystem).
- Settings $schema URL = `https://json.schemastore.org/claude-code-settings.json`
  (the schemastore canonical URL, not the github raw URL).
- Memory backend = **local-only, two-tier**: `memory/synced/*.md` in
  the repo (canonical), `memory/db.sqlite` per-machine cache. No
  shared remote backend. See `docs/decisions/0001-memory-sync-strategy.md`.
