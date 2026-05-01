---
name: handoff
description: Write or read the session handoff. Default action writes a fresh handoff for the current session. Use /handoff read to load the previous handoff. Profession-agnostic.
---

# /handoff

Write or read `~/.claude/handoff/current.md`.

## When to use

- **Write** (default): end of a meaningful session, before `/compact`,
  or when the user explicitly asks to "save where we are"
- **Read**: start of a session, or when the user asks "where did we
  leave off?" / "qual era o contexto da última sessão?"

## Modes

### Default — write handoff

1. Dispatch to `handoff-writer` agent
2. The agent archives the previous handoff to
   `handoff/archive/<YYYY-MM-DD-HHMM>-<slug>.md`
3. The agent writes a fresh `handoff/current.md` with:
   - What was done (concrete, with paths)
   - What's pending (with acceptance)
   - Active context (mental model)
   - Open questions
4. Return path + summary

### `/handoff read` — load prior handoff

1. Dispatch to `handoff-reader` agent
2. Returns: topic, active context, pending items, open questions
3. Does **not** dump full file content — just the forward-looking slice

### `/handoff status` — quick check

Reports whether `handoff/current.md` exists, when it was written, and
whether it's the empty template.

## Conventions

- **Idempotent write.** Calling `/handoff` twice in a row produces the
  same output (or a no-op if nothing material changed).
- **Profession-agnostic.** Handoff content adapts to the work — code
  sessions cite commits/PRs, non-code sessions cite files/decisions.
- **Don't include secrets.** Never copy `.env`, tokens, credentials,
  PII into the handoff body.
- **Brevity.** A handoff is for the next session, not an essay. Aim for
  the minimum content that lets the next session resume without
  re-asking questions.

## Examples

```
/handoff
→ Handoff written: ~/.claude/handoff/current.md
  Topic: Refactor auth middleware
  Pending: 2 items
  Open questions: 1

/handoff read
→ Resuming session.
  Topic: Refactor auth middleware
  Active context: ...
  Pending: ...

/handoff status
→ ~/.claude/handoff/current.md (written 2h ago, status: active)
```
