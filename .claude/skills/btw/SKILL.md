---
name: btw
description: Activated when the user prefixes a message with "[btw]" or "[a propósito]". Treats the input as a side comment — note it, but do not interrupt the current task. Useful for capturing thoughts mid-flow without derailing the active work.
---

# [btw] prefix skill

When the user starts a message with `[btw]` or `[a propósito]`, treat
the content as a parenthetical aside, not a new task.

## Triggers

- Message starts with `[btw]`, `[a propósito]`, `[apropósito]`, `[ap]`

## How to handle [btw] turns

1. **Acknowledge briefly.** One or two lines.
2. **Save the aside if it's worth keeping.** If the comment is:
   - A preference → save as a feedback memory
   - A correction to a fact you stated earlier → update or save
   - A future intent → write to handoff under "Open questions" or
     "What's pending"
   - An observation that doesn't need action → just acknowledge, don't
     save
3. **Do not pivot the active task.** If you were mid-task, return to
   it after acknowledging.
4. **Don't ask follow-up questions** unless the aside is ambiguous in
   a way that affects what you're saving.

## What [btw] does NOT do

- Does not start a new task or thread
- Does not require structured output
- Does not interrupt long-running work

## Examples

User (mid-coding session): `[btw] also, lembra que segunda eu vou estar fora`
Agent: "Anotado. Voltando ao refactor."
(Saves to handoff: open question — user away Monday, schedule around it)

User: `[btw] prefiro respostas mais curtas no geral`
Agent: "Anotado — vou ser mais terse."
(Saves a feedback memory: user prefers terse responses)

User: `[btw] o nome do servidor é staging.example.com não example-staging`
Agent: "Corrigido."
(Updates whatever context held the wrong fact)

## End condition

Aside is acknowledged (and optionally saved). Active task continues.
