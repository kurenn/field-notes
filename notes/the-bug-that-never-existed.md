# I almost fixed a bug that never existed.

> A note in our own docs flagged a styling bug that, on paper, made perfect sense. We'd queued the fix. It had never been broken — the reasoning was about the wrong rule.

**Date:** 2026-07-22
**Receipt:** reconstructed — the original is in a private repo

## What happened

We keep a running list of "known issues." One of them said a page's background was quietly broken: a recent build had added a blanket rule painting the whole page white, and it was overriding the warm off-white the design called for, on every screen. It was written down as fact. The fix was queued.

Nobody had looked at the page.

When someone finally did — the actual rendered page, not the stylesheet that describes it — the background was the exact colour it was always meant to be. It had never broken. There was nothing to fix. We deleted the note and the fix.

## Why it happened

The background doesn't come from a rule targeting the page element. It comes from a *class* on that element. And in CSS, a class selector is more specific than a bare element selector — so it wins, regardless of which stylesheet loads last.

Whoever wrote the "known issue" was reasoning about **load order**: the later rule overrides the earlier one. That's true for rules of *equal* specificity. It is not how the cascade resolves a class against an element — there, specificity decides first, and load order never gets a vote.

The reasoning was careful. It was just applying the right rule to the wrong situation. That's the dangerous kind: a plausible bug invented by someone competent, reasoning precisely about the wrong detail. Nobody challenges the confident, technical-sounding explanation — it *sounds* right, and it's wearing the clothes of expertise.

## The smallest thing that shows it

```
/* The design's background comes from a class: */
.page { background: #F4F3F0; }     /* specificity 0-1-0 */

/* A later build adds a blanket element rule: */
body  { background: #FFFFFF; }     /* specificity 0-0-1 — and it loads LATER */
```
```
<body class="page"> ... </body>
```
```
# The theory: "the later body rule wins."            (load order)
# The reality: .page (0-1-0) beats body (0-0-1),      (specificity)
#              no matter the order.
# getComputedStyle(document.body).backgroundColor === "rgb(244, 243, 240)"
# It was never white. There was never a bug.
```

The one-line check that would have ended the whole discussion: read the *computed* style off the live page, not the source rules and a mental model of how they'd combine.

## What I do differently now

Before I fix a bug, I confirm it exists by looking at the thing itself — the rendered output, the computed value, the actual row in the database — not the code that's supposed to produce it. Code tells you what *should* happen. Only the running thing tells you what *does*.

Two rules I keep:

- **A plausible bug is more dangerous than an obvious one,** because it recruits your competence to defend it. The more sophisticated the explanation, the more I want to see it reproduced before I spend a minute fixing it.
- **"Known issues" rot into folklore.** A guess written down in confident language becomes a fact nobody re-checks. Each one is worth the ten seconds it takes to point at reality and ask: is this still — or was it ever — true?
