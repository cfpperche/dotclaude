# Memory Index

This file is the index of `memory/synced/` and `memory/local/`. The agent
appends entries chronologically; manual edits should preserve chronological
order.

## Storage rules

- `memory/synced/<topic>.md` — versioned, cross-machine. Goes to git.
- `memory/local/<topic>.md` — per-machine, gitignored. Stays local.

Each memory file has YAML frontmatter:

```yaml
---
name: <short-identifier>
description: <one-line summary>
type: <user | feedback | project | reference>
created: <YYYY-MM-DD>
sync: <true | false>   # only honored in synced/ context
---
```

## Drawers (semantic categories)

- `architecture/` — invariants about how the user's workspace is organized
- `feedback/` — corrections from the user, validated patterns
- `project/` — active state of personal projects (paths, status)
- `reference/` — pointers to external resources (docs, tools, links)
- `user/` — user profile (preferences, voice, working style)

Drawers are conventional, not enforced — create the directory when you have
the first entry.

## When the agent saves

- Durable insight worth recalling later
- User preference validated across multiple sessions
- Cross-project convention
- A fact or decision the user explicitly asked to remember

## When the agent does NOT save

- Ephemeral state (current task, in-progress work)
- Patterns derivable from current files (those go in code, not memory)
- Anything containing credentials, tokens, or sensitive paths

## Index

(empty — will populate as memories accrue)
