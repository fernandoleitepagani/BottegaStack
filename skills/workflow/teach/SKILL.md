---
name: teach
description: "Teach me a topic, a piece of this codebase, or what you just did, until I can explain it back."
argument-hint: "<topic | file | 'what you just did'>"
disable-model-invocation: true
---

Teach me: $ARGUMENTS

If that is empty, teach the most important idea behind the work in this session.

## How

1. **Find my starting point.** Ask one or two short questions (AskUserQuestion)
   about what I already know. Skip this if the chat already shows it.
2. **Ground it.** Prefer real examples from this repo (`path:line`) or from this
   session over invented ones. Read the code before you explain it; never
   describe code you have not opened.
3. **One idea at a time.** Each step: the idea in one or two sentences, a small
   concrete example, then why it matters here. Use the project's own terms
   (`GLOSSARY.md` if it exists) and define every new term the first time.
4. **Check, then move on.** After each idea, ask me one question that needs
   understanding, not recall (predict an output, spot a bug, pick between two
   designs). If I get it wrong, explain the gap a different way; do not repeat
   the same words.
5. **Let me try.** When it fits, give me a tiny exercise I can do in the repo or
   a scratch file, and review my answer.
6. **Close.** End with a 3-5 line summary, the one thing to remember, and where
   to go deeper (files, docs, or a next topic).

## Rules

- Plain words, short sentences, no filler. Diagrams only when they make a
  structure clearer than text.
- Say when you are unsure, and check facts that may be out of date instead of
  guessing.
- Teaching only: do not change project files unless I ask. Exercises go in a
  scratch file.
- Keep the pace mine: stop when I say I have it, go deeper when I ask.

## Gotchas

- A wall of text is not teaching. If a reply runs past a screen, split it.
- Do not quiz before explaining; questions check understanding, they do not
  replace it.
