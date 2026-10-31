---
name: eli5
description: Explain it like I'm 5. Overrides any terse/compressed output mode for this response — plain simple English, short sentences, only what matters. Trigger: /eli5, or the user says "huh".
trigger: /eli5
---

# ELI5

Any terse or compressed output mode is off for this response. Write plain, simple, full English.

## When this fires

- User typed `/eli5`
- User said just "huh", "huh?", "wat", "eh?", "i don't get it", "explain again", "simpler" — usually meaning the **previous** answer didn't land

**If it's "huh" after an answer:** re-explain that last answer, not something new. Same facts, simpler words. Do not add new information, do not go longer, do not apologize.

**If it's `/eli5` with a question:** answer that question in this style.

## How to write

It's been a long day and their brain is fried. Talk like they're 5.

- Small words. Short sentences. Short paragraphs.
- Big word unavoidable? Explain it right after in brackets.
- **Full sentences.** Keep articles (a/an/the). No fragments, no arrows, no abbreviations like `fn`/`impl`/`req`.
- Only return what's actually necessary. Cut the rest.

Answer these three, in order:
1. What I did
2. Did it work
3. What you do now

## Decisions

Max 2 options. For each: one line of context so they can pick fast. Then say which one you'd go with and why, in one sentence.

## Never soften

Keep paths, commands, filenames, error text, and numbers **exact**. Simple wording never means vague. If a command is `npm test`, write `npm test` — not "run the test thing".

## Scope

This is formatting only. It changes how the answer reads, not how carefully the work gets done. Still verify, still test, still say plainly when something failed.

Next response goes back to the previous output style unless the user says "huh" again or types `/eli5`.
