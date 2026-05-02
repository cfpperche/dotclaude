# ADR 0001 — Memory sync strategy

- **Status:** accepted
- **Date:** 2026-05-01
- **Context scope:** dotclaude, multi-machine

## Decision

Memory in dotclaude is **two-tier**:

- **`memory/synced/*.md`** — durable, human-readable insights. Versioned in
  the repo. Travels across every machine via `git pull`.
- **`memory/db.sqlite`** (mcp-memory-service) — embeddings + semantic
  search index. **Per-machine, local-only.** Gitignored. Not shared
  across machines.

There is no central memory backend. Each machine maintains its own
SQLite working memory; only the markdown layer is canonical.

## Why

The portability promise is *"the agent behaves the same on every machine
the repo is cloned on."* That promise is satisfied as long as the
**source of truth** for durable insights is in the repo. The SQLite db
is a per-machine **cache + index** for semantic search; it can diverge
across machines without breaking continuity, because the underlying
markdown files are the canonical record.

Considered alternatives:

1. **Shared remote backend** (Postgres / Turso) — gives true cross-machine
   continuity for embeddings, but adds hosting, latency, credential
   management, and a single point of failure. Overkill for a personal
   agent.
2. **Sync the SQLite file via cloud storage** (Syncthing, Dropbox,
   iCloud) — race conditions and likely corruption under concurrent
   writes. Rejected.
3. **Periodic git-tracked snapshot of the SQLite db** — lossy, large
   binary churn in repo, complicates `git pull`. Rejected.

## Consequences

**Good:**

- Zero infra, zero latency, zero credential surface.
- `git push` / `git pull` is the only sync mechanism — same model as
  every other dotclaude file.
- Clean failure mode: a corrupted local db doesn't affect other
  machines.

**Trade-offs:**

- Semantic search results may differ across machines until both have
  observed the same content. Acceptable: durable insights are written
  to `memory/synced/*.md` deliberately, not as a side effect of search
  recall.
- A new machine starts with an empty SQLite; it warms up as it's used.

## How to apply

- When the agent saves something durable, write to
  `memory/synced/<topic>.md` (markdown, with frontmatter).
- When the agent caches transient context, the mcp-memory-service db
  is fine — it stays local.
- Multi-machine validation tests the markdown layer (write A → push →
  pull → read B), not SQLite.
