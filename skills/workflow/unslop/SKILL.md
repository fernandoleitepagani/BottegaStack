---
name: unslop
description: Cut AI tells from PaganiStack summaries, review copy, and docs. Use before posting a human summary, reviewing UX copy, or writing documentation.
---

# Unslop

Adapted from pstack's `unslop`. Edit text to remove AI patterns. Scan for the
patterns below, then rewrite. Preserve meaning and match the intended tone.

Use this on:
- the run summary or PR body before posting it,
- UX copy in `review-code`,
- `AGENTS.md`, `docs/WORKFLOW.md`, and skill text when you edit them.

## Patterns to detect and fix

### Content

1. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...",
   "showcasing...", "fostering...". Delete or expand with real sources.
2. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some
   critics argue". Name the source or delete.

### Language

3. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering,
   garner, interplay, intricate, landscape (abstract), pivotal, showcase,
   tapestry (abstract), testament, underscore, vibrant. Replace with plain words.
4. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features".
   Say "is" or "has".
5. **"Not just X, but Y."** State the point directly.
6. **Rule of three.** Do not force ideas into groups of three. Use the natural
   number.
7. **Synonym cycling.** Pick one term and repeat it.
8. **False ranges.** "from X to Y" where X and Y are not on a meaningful scale.
   List the topics directly.

### Style

9. **Em dash overuse.** Prefer periods or commas.
10. **Colon overuse.** Colons are fine before a list or example, not as
    mid-sentence connectors.
11. **Boldface overuse.** Do not bold every proper noun or acronym.
12. **Inline-header lists.** Convert a bold label that restates the line into
    prose. A bold lead-in followed by genuinely new detail is fine.
13. **Title case headings.** Use sentence case.
14. **Decorative emojis.** Remove them from headings and bullets.
15. **Curly quotes.** Use straight quotes.

### Communication artifacts

16. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!",
    "Certainly!", "Found the smoking gun!" Remove.
17. **Sycophantic tone.** "Great question! You're absolutely right!" Respond
    directly.

### Filler

18. **Filler phrases.** "In order to" becomes "To". "Due to the fact that"
    becomes "Because". Delete "It is important to note that".
19. **Excessive hedging.** "could potentially possibly be argued that it might"
    becomes "may".
20. **Generic conclusions.** "The future looks bright." State specific plans or
    facts.

### Jargon

21. **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus,
    primitive as a noun, harness as a metaphor, surface as in "API surface",
    bedrock, scaffolding as a metaphor, modality, paradigm, north star, flywheel.
    Pick the concrete word.
22. **Say what it does, not how it feels.** "the database stays close at hand"
    names a feeling. Name the mechanism or a number.
23. **Shorten or split dense sentences.** One idea per sentence.
24. **Active voice.** Prefer it. Name the actor.
25. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or
    the number.
26. **Prefer the plain word.** "utilize" becomes "use", "facilitate" becomes
    "help", "numerous" becomes "many", "in the event that" becomes "if".
27. **Mannered prose.** Metaphor or flourish where a literal phrase exists. Say
    what you mean.
28. **Over-compression.** Write whole sentences with articles and verbs. Spell
    out arrows and abbreviations.

## Check

After rewriting, answer:

- Does every sentence say something concrete about this project?
- Could the sentence appear unchanged in another project's docs? If yes, cut it.
- Is the claim backed by a command, a number, a file, or a screenshot?

If not, fix it or remove it.
