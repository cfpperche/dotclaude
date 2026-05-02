# Contributing

Thanks for the interest. This repo is a portable Claude Code agent that
installs at `~/dotclaude/` and is only active when the user opens Claude
Code in that directory (`cd ~/dotclaude && claude`). Contributions that
**keep it portable and domain-agnostic** are welcome.

> Historical note: dotclaude originally lived at `~/.claude/` (loaded
> globally in every session). It moved to `~/dotclaude/` on 2026-05-02 to
> stop leaking into other projects. See `docs/MIGRATION-2026-05-02.md`.

## What's in scope

- **Stack detection improvements** — more languages, more package
  managers, better heuristics.
- **Cross-platform fixes** — caveats for macOS, native Linux, WSL2.
- **Idempotent scripts** — anything that can run twice without breaking.
- **Domain-agnostic skills, agents, hooks** — reusable across any project
  and any user.
- **Documentation improvements** — install steps that work on a clean
  machine, troubleshooting sections, examples.
- **CI improvements** — better linting, validation, frontmatter checks.

## What's out of scope

- **Personal opinions hardcoded** into the agent's behavior. Voice
  preferences, project-specific rules, vendor lock-in. Fork the repo and
  customize there.
- **Domain-specific tools** for one industry, one stack, one product.
  The repo aims to be a base; domain-specific layers go in your fork.
- **Authentication patterns** that bind the agent to one provider.
- **Anything that requires per-user secrets in the repo.**

## Ground rules

1. **No `.env` content, no tokens, no keys** in commits. CI scans for
   common patterns; if you need a secret in tests, mock it.
2. **No `git add -A` / `git add .`**. Enumerate paths.
3. **Idempotent scripts.** Re-running a script on a configured machine
   must not break that configuration.
4. **JSON / YAML must validate.** Lint runs on every PR.
5. **Shell scripts must pass `shellcheck` at error severity.**
6. **No personality.** Replace "I" / "me" / "my" preferences in shipped
   code with neutral defaults the user customizes via their fork or
   `settings.local.json`.
7. **Don't commit binaries.** Plugin binaries, cache files, lockfile
   artifacts > 1 MB — none.

## Stack-aware additions

When you add code that runs against a user's project (skills, hooks, etc.),
follow the stack-awareness protocol in `CLAUDE.md`:

- Detect language, package manager, build tool, test runner before
  recommending commands.
- Never assume Docker, never assume Node, never assume Python.
- Provide the same capability across at least 2 stacks (e.g., npm + pip)
  before merging. Stack-specific helpers live in your fork.

## Pull request workflow

1. Fork the repo.
2. Create a topic branch: `git checkout -b feat/<short-description>`.
3. Make your changes. Run locally:
   ```bash
   ./scripts/doctor.sh
   ```
4. Commit with the convention: `type(scope): subject` —
   `feat / fix / chore / docs / refactor`.
5. Push to your fork. Open a PR against `main`.
6. CI must pass (`lint.yml`).
7. Address review comments. Maintainers merge once reviewed.

## Issue workflow

- **Epics** — multi-issue bodies of work, marked with `epic` label.
- **Tasks** — single concrete pieces of work, marked with `task` label.
- **Bugs** — use the default GitHub bug label.
- Use the issue templates in `.github/ISSUE_TEMPLATE/`.

## Adding a new MCP server

Update `mcp/README.md` with:

- Server name, package, purpose.
- Required dependencies.
- Default config in `settings.json`.
- Per-machine notes (binary download size, performance caveats, etc.).
- Update `scripts/install-mcps.sh` to register it (idempotent).

## Adding a new skill

Create `.claude/skills/<skill-name>/SKILL.md` with:

- YAML frontmatter (`name`, `description`, `created`, `version`,
  `argument-hint` if applicable).
- Body following the [Skill spec](https://docs.claude.com/en/docs/claude-code/skills).
- Stack-aware detection if the skill operates on user code.
- Examples in body or `references/examples.md`.

## Adding a new subagent

Create `.claude/agents/<agent-name>.md` with:

- YAML frontmatter (`name`, `description`, `tools`, `model`).
- Body explaining when the agent activates and what it produces.
- Tool whitelist scoped to what the agent actually needs.

## Adding a new hook

Add the script to `.claude/hooks/` (POSIX shell, exit 0 / 2 only).

- Hook must support a bypass env var for emergency repair flows
  (e.g., `DOTCLAUDE_HOOK_<NAME>=0`).
- Document the trigger (PreToolUse, PostToolUse, SessionStart, Stop) and
  matcher in `.claude/settings.json`.
- Include a comment block explaining intent + bypass.
- If the hook should only run inside `~/dotclaude/`, add the
  `CLAUDE_PROJECT_DIR` guard pattern from
  `.claude/hooks/session-start-load-handoff.sh`.

## Tests

If your change has observable behavior, add a test or smoke-test that
exercises it. Keep tests stack-neutral or document the assumed stack.

## Reporting bugs

Open an issue with:

- OS + version (WSL2 Ubuntu 24.04, macOS 14, Linux Fedora 41, etc.)
- Claude Code version (`claude --version`)
- Node version (`node --version`)
- Steps to reproduce
- Expected vs actual

## Code of Conduct

By participating, you agree to abide by `CODE_OF_CONDUCT.md`.

## License

MIT. Contributions are licensed under MIT to match the repo.
