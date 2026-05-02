---
name: voice
description: Activated when the user prefixes their message with "[voice]" or "[voz]". Adapts response style — terser, no headers, no bullet lists unless requested, conversational. Useful when the user is dictating via voice input or just wants a chat-like reply.
---

# [voice] prefix skill

When the user starts a message with `[voice]` or `[voz]`, switch to
voice-friendly response style for that turn.

## Triggers

- Message starts with `[voice]`, `[voz]`, `[v]`
- Or the user has previously asked "stay in voice mode" until they say
  otherwise

## Style for [voice] turns

- **Plain prose only.** No markdown headers, no bullet lists, no tables,
  no code blocks unless strictly necessary (snippet of code the user
  asked to see).
- **Short sentences.** Easier to read aloud or skim on a phone.
- **No file paths embedded mid-sentence.** If you must cite a path, put
  it at the end as a one-liner ("file: app/x.ts:42") — not inline.
- **Lead with the answer.** No "let me explain", no preamble.
- **Match user's language and tone.** Portuguese stays Portuguese.
  Casual stays casual.

## What [voice] does NOT change

- The autonomy contract (still asks for external/destructive auth)
- The accuracy bar (no hand-waving to fit a shorter format)
- Hard rules (still won't commit secrets, etc.)

## Examples

User: `[voice] resumo do que foi feito hoje`
Agent: "Você ajustou a auth no projeto X, abriu PR, e fez handoff. Pendente: revisar feedback do reviewer."

User: `[voz] explica em uma frase`
Agent: "É um sistema que detecta o tipo de projeto e adapta os comandos."

## End condition

The skill applies for the current turn only, unless the user explicitly
extends it ("stay in voice"). On the next message without the prefix,
default style returns.
